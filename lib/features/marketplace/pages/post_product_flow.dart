// filepath: lib/features/agents/pages/agent_post_flow.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class PostProductFlow extends StatefulWidget {
  final Map<String, dynamic>? editItem;

  const PostProductFlow({super.key, this.editItem});

  @override
  State<PostProductFlow> createState() => _PostProductFlowState();
}

class _PostProductFlowState extends State<PostProductFlow> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  final _supabase = Supabase.instance.client;

  static const int _maxImages = 4;

  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _selectedCategory;
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isMizanProduct = false;

  late TextEditingController _titleController;
  late TextEditingController _qtyController;
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final item = widget.editItem;
    _titleController = TextEditingController(text: item?['title'] ?? '');
    _qtyController =
        TextEditingController(text: item?['quantity']?.toString() ?? '');
    _priceController =
        TextEditingController(text: item?['unit_price']?.toString() ?? '');
    _locationController = TextEditingController(text: item?['location'] ?? '');
    _descController = TextEditingController(text: item?['description'] ?? '');
    _isMizanProduct = item?['is_mizan_product'] ?? false;
    _existingImageUrls = List<String>.from(item?['image_urls'] ?? []);
    _fetchCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final data =
          await _supabase.from('market_categories').select().order('name');
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data);
          if (widget.editItem != null) {
            try {
              _selectedCategory = _categories.firstWhere(
                (cat) => cat['id'] == widget.editItem!['category_id'],
              );
            } catch (_) {}
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImages() async {
    final int currentTotal = _selectedImages.length + _existingImageUrls.length;
    if (currentTotal >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Maximum of 4 images allowed")));
      return;
    }
    final List<XFile> pickedFiles =
        await _picker.pickMultiImage(imageQuality: 50, maxWidth: 1080);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = _maxImages - currentTotal;
        _selectedImages.addAll(
            pickedFiles.take(remainingSlots).map((file) => File(file.path)));
      });
    }
  }

  Future<List<String>> _uploadImages(String listingId) async {
    List<String> urls = [..._existingImageUrls];
    for (var i = 0; i < _selectedImages.length; i++) {
      final file = _selectedImages[i];
      final extension = p.extension(file.path);
      final fileName =
          '$listingId/img_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
      try {
        await _supabase.storage.from('listings').upload(fileName, file);
        urls.add(_supabase.storage.from('listings').getPublicUrl(fileName));
      } catch (e) {
        debugPrint("Upload error: $e");
      }
    }
    return urls;
  }

  Future<void> _submitListing() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;
    if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please add at least one photo")));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final user = _supabase.auth.currentUser;
      final bool isEdit = widget.editItem != null;
      final data = {
        'agent_id': user?.id,
        'category_id': _selectedCategory!['id'],
        'title': _titleController.text.trim(),
        'quantity': double.tryParse(_qtyController.text) ?? 0.0,
        'unit_price': double.tryParse(_priceController.text) ?? 0.0,
        'location': _locationController.text.trim(),
        'description': _descController.text.trim(),
        'is_mizan_product': _isMizanProduct,
        'status': 'pending',
        'updated_at': DateTime.now().toIso8601String(),
      };

      String listingId = isEdit ? widget.editItem!['id'].toString() : '';
      if (isEdit) {
        await _supabase
            .from('market_listings')
            .update(data)
            .eq('id', listingId);
      } else {
        final res = await _supabase
            .from('market_listings')
            .insert(data)
            .select()
            .single();
        listingId = res['id'].toString();
      }

      final allUrls = await _uploadImages(listingId);
      await _supabase
          .from('market_listings')
          .update({'image_urls': allUrls}).eq('id', listingId);

      if (mounted) {
        if (isEdit) {
          Navigator.pop(context);
        } else {
          _showPaymentDialog();
        }
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Listing Created"),
        content: const Text("A fee of 500 ETB is required for activation."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final int currentTotal = _selectedImages.length + _existingImageUrls.length;

    return Scaffold(
      appBar: AppBar(
          title:
              Text(widget.editItem != null ? "Edit Listing" : "New Listing")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildImageHeader(currentTotal),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImageUrls
                        .map((url) => _buildThumbnail(url, isUrl: true)),
                    ..._selectedImages
                        .map((file) => _buildThumbnail(file, isUrl: false)),
                    if (currentTotal < _maxImages)
                      GestureDetector(
                        onTap: _pickImages,
                        child: _buildAddButton(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildTextField(_titleController, "Title"),
              _buildCategoryDropdown(),
              _buildTextField(_qtyController, "Quantity", isNum: true),
              _buildTextField(_priceController, "Price", isNum: true),
              _buildTextField(_locationController, "Location"),
              _buildTextField(_descController, "Description", maxLines: 3),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitListing,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text("SUBMIT"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
    );
  }

  Widget _buildImageHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("Photos", style: TextStyle(fontWeight: FontWeight.bold)),
        Text("$count / $_maxImages"),
      ],
    );
  }

  Widget _buildThumbnail(dynamic src, {required bool isUrl}) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
            image: isUrl ? NetworkImage(src) : FileImage(src) as ImageProvider,
            fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String lbl,
      {bool isNum = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: lbl),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedCategory,
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c['name'])))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v),
      validator: (v) => v == null ? "Required" : null,
    );
  }
}
