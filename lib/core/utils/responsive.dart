import 'package:flutter/material.dart';

abstract class Responsive {
  /// Columns for poster grids on tablets vs phones.
  static int posterGridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 900) return 5;
    if (w >= 600) return 4;
    return 3;
  }
}
