import 'package:flutter/material.dart';

class DynamicUnitForm extends StatelessWidget {
  final String category; // e.g., 'Eggs', 'Cattle', 'Milk'
  final TextEditingController quantityController;
  final TextEditingController priceController;

  const DynamicUnitForm({
    super.key,
    required this.category,
    required this.quantityController,
    required this.priceController,
  });

  @override
  Widget build(BuildContext context) {
    String unitLabel;
    String helperText;

    // Logic to determine units based on category
    switch (category.toLowerCase()) {
      case 'eggs':
        unitLabel = "Number of Crates";
        helperText = "Standard crate = 30 eggs";
        break;
      case 'cattle':
      case 'sheep':
        unitLabel = "Number of Head";
        helperText = "Total animals in this batch";
        break;
      case 'milk':
        unitLabel = "Liters";
        helperText = "Volume available per day/batch";
        break;
      default:
        unitLabel = "Quantity";
        helperText = "Units available";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Listing Details",
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E20)),
        ),
        const SizedBox(height: 15),

        // Quantity Input
        TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: unitLabel,
            hintText: "e.g. 50",
            helperText: helperText,
            prefixIcon: const Icon(Icons.inventory_2_outlined),
          ),
        ),

        const SizedBox(height: 20),

        // Price Input
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Unit Price (ETB)",
            hintText: "e.g. 15.50",
            helperText: "Price per single $unitLabel",
            prefixIcon: const Icon(Icons.payments_outlined),
          ),
        ),
      ],
    );
  }
}
