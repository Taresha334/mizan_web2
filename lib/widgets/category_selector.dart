import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategorySelector extends StatelessWidget {
  final Function(String id, String name) onCategorySelected;
  final String? selectedCategoryName;

  const CategorySelector({
    super.key,
    required this.onCategorySelected,
    this.selectedCategoryName,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('market_categories')
          .select('id, name')
          .order('name'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final categories = snapshot.data ?? [];

        return DropdownButtonFormField<String>(
          value: selectedCategoryName,
          hint: const Text("Select Category"),
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: "Category",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(),
          ),
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['name'],
              child: Text(cat['name']),
              onTap: () => onCategorySelected(cat['id'], cat['name']),
            );
          }).toList(),
          onChanged: (value) {},
          validator: (value) => value == null ? "Required" : null,
        );
      },
    );
  }
}
