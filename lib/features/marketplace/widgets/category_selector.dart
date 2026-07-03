import 'package:flutter/material.dart';
import '../controllers/market_controller.dart';

class CategorySelector extends StatelessWidget {
  final MarketController controller;

  const CategorySelector({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final entries = controller.categoryMap.entries.toList();
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final isSelected = controller.selectedCategoryId == entry.value;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (_) => controller.toggleCategory(entry.value),
              selectedColor: const Color(0xFF1B5E20),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }
}
