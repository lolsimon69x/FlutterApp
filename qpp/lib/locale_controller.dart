import 'package:flutter/material.dart';

// Global ValueNotifier to hold the active language locale
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('en'));