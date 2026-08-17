import 'package:flutter_test/flutter_test.dart';

import 'package:doc_scanner/app/constants/app_constants.dart';

void main() {
  test('app constants are configured', () {
    expect(AppConstants.appName, 'Doc Scanner');
    expect(AppConstants.appVersion, isNotEmpty);
  });
}
