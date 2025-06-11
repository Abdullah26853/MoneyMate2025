import 'package:flutter/material.dart';

class CategoryScore {
  final IconData icon;
  final String name;
  final int percent;
  final String maxPercent;
  final int points;
  final int maxPoints;
  final Color color;

  const CategoryScore({
    required this.icon,
    required this.name,
    required this.percent,
    required this.maxPercent,
    required this.points,
    required this.maxPoints,
    required this.color,
  });

  int get maxPercentInt {
    // Try to parse the upper bound from maxPercent (e.g., '10–15%' or '<7%')
    if (maxPercent.startsWith('<')) {
      final val = int.tryParse(maxPercent.replaceAll(RegExp(r'[^0-9]'), ''));
      return val ?? 100;
    } else if (maxPercent.contains('–')) {
      final parts = maxPercent.split('–');
      if (parts.length == 2) {
        final upper = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
        return upper ?? 100;
      }
    }
    return 100;
  }
}
