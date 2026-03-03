// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habesha_dates/core/theme/app_theme.dart';

void main() {
  test('App theme uses dark mode and brand colors', () {
    expect(appTheme.brightness, Brightness.dark);
    expect(appTheme.primaryColor, AppColors.gold);
    expect(appTheme.scaffoldBackgroundColor, AppColors.darkBg);
  });
}
