import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sleep_talk_recorder/utils/app_theme.dart';

void main() {
  test('AppTheme is configured correctly', () {
    final theme = AppTheme.darkTheme;
    expect(theme.brightness, Brightness.dark);
    expect(theme.primaryColor, AppTheme.accentBlue);
    expect(theme.scaffoldBackgroundColor, AppTheme.primaryDark);
  });
}