// filepath: lib/features/marketplace/widgets/edit_guest_listing_page.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditGuestListingPage extends StatefulWidget {
  final Map<String, dynamic> item;
  final String userPhone;
  const EditGuestListingPage({
    super.key,
    required this.item,
    required this.userPhone,
  });

  @override
  State<EditGuestListingPage> createState() => _EditGuestListingPageState();
}

class _EditGuestListingPageState extends State<EditGuestListingPage> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

  late TextEditingController _titleCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _descCtrl;
  List<dynamic> _imageState = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item['title']);
    _priceCtrl = TextEditingController(
      text: widget.item['unit_price']?.toString(),
    );
    _qtyCtrl = TextEditingController(text: widget.item['quantity']?.toString());
    _descCtrl = TextEditingController(text: widget.item['description']);
    _imageState = List.from(widget.item['image_urls'] ?? []);
    while (_imageState.length < 4) _imageState.add(null);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateListing() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      List<String> finalUrls = [];
      for (var item in _imageState) {
        if (item is String) {
          finalUrls.add(item);
        } else if (item is Uint8List) {
          final path =
              'public_posts/${DateTime.now().millisecondsSinceEpoch}_${finalUrls.length}.jpg';
          await _supabase.storage
              .from('market-images')
              .uploadBinary(path, item);
          finalUrls.add(
            _supabase.storage.from('market-images').getPublicUrl(path),
          );
        }
      }

      final updatedData = {
        'title': _titleCtrl.text.trim(),
        'unit_price':
            double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
        'quantity': double.tryParse(_qtyCtrl.text) ?? 1.0,
        'description': _descCtrl.text.trim(),
        'image_urls': finalUrls,
      };

      await _supabase.rpc(
        'update_non_partner_listing',
        params: {
          'listing_id': widget.item['id'],
          'user_phone': widget.userPhone,
          'new_data': updatedData,
        },
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EDIT LISTING")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildImageGrid(),
                  const SizedBox(height: 20),
                  _buildInput(_titleCtrl, "Title"),
                  _buildInput(_priceCtrl, "Price (ETB)", isDecimal: true),
                  _buildInput(_qtyCtrl, "Quantity", isDecimal: true),
                  _buildInput(_descCtrl, "Description", isMultiline: true),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateListing,
                    child: const Text("SAVE CHANGES"),
                  ),
                ],
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
