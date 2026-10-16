import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../../app/constants/app_constants.dart';
import '../providers/settings_provider.dart';
import 'ad_service.dart';
import 'app_open_ad_service.dart';

/// Play Billing for Weekly, Monthly, and Yearly Pro.
/// Pro is granted only after the store reports an active purchase.
class ProPurchaseService extends ChangeNotifier with WidgetsBindingObserver {
  ProPurchaseService(this._settings);

  static const Map<String, String> productIds = {
    'weekly': AppConstants.weeklyProductId,
    'monthly': AppConstants.monthlyProductId,
    'yearly': AppConstants.yearlyProductId,
  };

  final SettingsProvider _settings;
  final InAppPurchase _iap = InAppPurchase.instance;

  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  Completer<void>? _restoreCompleter;
  bool _syncInProgress = false;
  bool _restoreFoundActive = false;
  bool _started = false;

  List<ProductDetails> products = [];
  String? lastMessage;

  static const String missingPrice = '__';

  ProductDetails? productFor(String planId) {
    final id = productIds[planId];
    if (id == null) return null;
    final matches = [
      for (final product in products)
        if (product.id == id) product,
    ];
    if (matches.isEmpty) return null;

    for (final product in matches) {
      if (product is! GooglePlayProductDetails) continue;
      final phase = _recurringPhase(product);
      if (phase != null &&
          phase.recurrenceMode == RecurrenceMode.infiniteRecurring &&
          phase.priceAmountMicros > 0) {
        return product;
      }
    }
    return matches.first;
  }

  /// Play's formatted price. Missing products stay as [missingPrice].
  String priceLabel(String planId) {
    final product = productFor(planId);
    if (product == null) return missingPrice;
    final phase = product is GooglePlayProductDetails
        ? _recurringPhase(product)
        : null;
    final label = (phase?.formattedPrice ?? product.price).trim();
    if (label.isEmpty) return missingPrice;
    return label;
  }

  double? rawPrice(String planId) {
    final product = productFor(planId);
    if (product == null) return null;
    if (product is GooglePlayProductDetails) {
      final micros = _recurringPhase(product)?.priceAmountMicros;
      if (micros != null && micros > 0) return micros / 1000000.0;
    }
    return product.rawPrice > 0 ? product.rawPrice : null;
  }

  PricingPhaseWrapper? _recurringPhase(GooglePlayProductDetails product) {
    final index = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (index == null || offers == null || index >= offers.length) return null;
    final phases = offers[index].pricingPhases;
    for (final phase in phases.reversed) {
      if (phase.priceAmountMicros > 0 &&
          phase.recurrenceMode == RecurrenceMode.infiniteRecurring) {
        return phase;
      }
    }
    for (final phase in phases.reversed) {
      if (phase.priceAmountMicros > 0) return phase;
    }
    return phases.isEmpty ? null : phases.last;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _purchaseSub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {
        if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
          _restoreCompleter!.complete();
        }
      },
    );
    await loadProducts();
    unawaited(refreshFromStore());
  }

  Future<void> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) {
      lastMessage = 'Play Store billing is not available on this device.';
      notifyListeners();
      return;
    }
    final response = await _iap.queryProductDetails(productIds.values.toSet());
    if (response.error != null && kDebugMode) {
      debugPrint('Pro products error: ${response.error}');
    }
    products = response.productDetails;
    notifyListeners();
  }

  Future<bool> buy(String planId) async {
    lastMessage = null;
    final available = await _iap.isAvailable();
    if (!available) {
      lastMessage = 'Play Store billing is not available on this device.';
      notifyListeners();
      return false;
    }
    if (products.isEmpty) await loadProducts();
    final product = productFor(planId);
    if (product == null) {
      lastMessage =
          'This plan is not available in the Play Store yet. Add ${productIds[planId]} and try again.';
      notifyListeners();
      return false;
    }
    try {
      final started = await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        lastMessage = 'Could not open checkout. Please try again.';
        notifyListeners();
      }
      return started;
    } catch (error) {
      lastMessage = 'Could not open checkout. Please try again.';
      if (kDebugMode) debugPrint('Pro purchase failed: $error');
      notifyListeners();
      return false;
    }
  }

  Future<void> restore() => refreshFromStore();

  Future<void> refreshFromStore() async {
    final available = await _iap.isAvailable();
    if (!available || _syncInProgress) return;
    _syncInProgress = true;
    try {
      final active = await _resolveActivePro();
      await _settings.setPremium(active);
      AdService.instance.syncWithPro(_settings.isPremium);
      if (_settings.isPremium) {
        AppOpenAdManager.instance.discard();
      } else {
        unawaited(AppOpenAdManager.instance.loadAd());
      }
    } finally {
      _syncInProgress = false;
    }
  }

  Future<bool> _resolveActivePro() async {
    if (Platform.isAndroid) return _queryActiveProAndroid();

    _restoreFoundActive = false;
    _restoreCompleter = Completer<void>();
    await _iap.restorePurchases();
    await _restoreCompleter!.future.timeout(
      const Duration(seconds: 6),
      onTimeout: () {},
    );
    return _restoreFoundActive;
  }

  Future<bool> _queryActiveProAndroid() async {
    final addition = _iap
        .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) {
      if (kDebugMode) {
        debugPrint('Pro restore failed — keeping the current Pro state');
      }
      return _settings.isPremium;
    }
    return response.pastPurchases.any(_isActiveProPurchase);
  }

  bool _isActiveProPurchase(PurchaseDetails purchase) {
    if (!productIds.values.contains(purchase.productID)) return false;
    if (purchase.status == PurchaseStatus.pending ||
        purchase.status == PurchaseStatus.error ||
        purchase.status == PurchaseStatus.canceled) {
      return false;
    }
    if (Platform.isAndroid && purchase is GooglePlayPurchaseDetails) {
      return purchase.billingClientPurchase.purchaseState ==
          PurchaseStateWrapper.purchased;
    }
    return purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!productIds.values.contains(purchase.productID)) continue;
      if (_isActiveProPurchase(purchase)) {
        if (_syncInProgress) {
          _restoreFoundActive = true;
        } else {
          await _settings.setPremium(true);
          AdService.instance.syncWithPro(true);
          AppOpenAdManager.instance.discard();
        }
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    if (_restoreCompleter != null && !_restoreCompleter!.isCompleted) {
      _restoreCompleter!.complete();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refreshFromStore());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchaseSub?.cancel();
    super.dispose();
  }
}
