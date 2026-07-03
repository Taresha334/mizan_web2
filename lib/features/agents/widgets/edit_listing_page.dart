// filepath: lib/features/agents/widgets/edit_listing_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditListingPage extends StatefulWidget {
  final Map<String, dynamic> listingData;
  const EditListingPage({super.key, required this.listingData});

  @override
  State<EditListingPage> createState() => _EditListingPageState();
}

class _EditListingPageState extends State<EditListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locCtrl;

  // Hybrid list: contains either String (URLs) or Uint8List (New images)
  List<dynamic> _imageState = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.listingData['title']);
    _priceCtrl = TextEditingController(
      text: widget.listingData['unit_price']?.toString(),
    );
    _qtyCtrl = TextEditingController(
      text: widget.listingData['quantity']?.toString(),
    );
    _descCtrl = TextEditingController(text: widget.listingData['description']);
    _locCtrl = TextEditingController(text: widget.listingData['location']);

    // Initialize with existing URLs
    _imageState = List.from(widget.listingData['image_urls'] ?? []);
    // Ensure we have 4 slots
    while (_imageState.length < 4) _imageState.add(null);
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<String> finalUrls = [];
      for (var item in _imageState) {
        if (item is String) {
          finalUrls.add(item); // Keep existing
        } else if (item is Uint8List) {
          // Upload new
          final path =
              'partner_posts/${DateTime.now().millisecondsSinceEpoch}_${finalUrls.length}.jpg';
          await _supabase.storage
              .from('market-images')
              .uploadBinary(path, item);
          finalUrls.add(
            _supabase.storage.from('market-images').getPublicUrl(path),
          );
        }
      }

      await _supabase
          .from('market_listings')
          .update({
            'title': _titleCtrl.text.trim(),
            'unit_price':
                double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
            'quantity': double.tryParse(_qtyCtrl.text) ?? 1.0,
            'description': _descCtrl.text.trim(),
            'location': _locCtrl.text.trim(),
            'image_urls': finalUrls,
          })
          .eq('id', widget.listingData['id']);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Product"),
        backgroundColor: const Color(0xFF1B5E20),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageGrid(),
                    _buildInput(_titleCtrl, "Title"),
                    _buildInput(_priceCtrl, "Price", isDecimal: true),
                    _buildInput(_qtyCtrl, "Quantity", isDecimal: true),
                    _buildInput(_locCtrl, "Location"),
                    _buildInput(_descCtrl, "Description", isMultiline: true),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateListing,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "SAVE CHANGES",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildImageGrid() => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: List.generate(
      4,
      (i) => GestureDetector(
        onTap: () async {
          final XFile? img = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 50,
          );
          if (img != null) {
            final bytes = await img.readAsBytes();
            setState(() => _imageState[i] = bytes);
          }
        },
        child: Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imageState[i] == null
              ? const Icon(Icons.add_a_photo)
              : _imageState[i] is String
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(_imageState[i], fit: BoxFit.cover),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(_imageState[i], fit: BoxFit.cover),
                ),
        ),
      ),
    ),
  );

  Widget _buildInput(
    TextEditingController c,
    String l, {
    bool isDecimal = false,
    bool isMultiline = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(
      controller: c,
      maxLines: isMultiline ? 3 : 1,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: l,
        filled: true,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    ),
  );
}
