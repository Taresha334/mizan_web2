import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:mizan_web/core/utils/pricing_logic.dart';
import 'package:mizan_web/widgets/category_selector.dart';

class NonPartnerPostForm extends StatefulWidget {
  const NonPartnerPostForm({Key? key}) : super(key: key);

  @override
  State<NonPartnerPostForm> createState() => _NonPartnerPostFormState();
}

class _NonPartnerPostFormState extends State<NonPartnerPostForm> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _txIdCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();

  String? _selectedCategoryName;
  String? _selectedCategoryId;
  String? _selectedUnit = 'kg';
  int _selectedWeeks = 1;
  bool _isLoading = false;

  final List<Uint8List?> _imageBytesList = List.filled(4, null);

  final Color mizanGreen = const Color(0xFF1B5E20);
  final Color mizanGold = const Color(0xFFC6A664);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _txIdCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  double _calculatePublicFee() => MizanPricing.getVisibilityFee(
    role: 'non-partner',
    weeks: _selectedWeeks,
    isRegisteredPartner: false,
  );

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) {
      if (_selectedCategoryId == null)
        _showSnackBar("Please select a category", Colors.red);
      return;
    }
    setState(() => _isLoading = true);

    try {
      List<String> uploadedUrls = [];
      for (int i = 0; i < 4; i++) {
        if (_imageBytesList[i] != null) {
          final path =
              'public_posts/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await _supabase.storage
              .from('market-images')
              .uploadBinary(path, _imageBytesList[i]!);
          uploadedUrls.add(
            _supabase.storage.from('market-images').getPublicUrl(path),
          );
        }
      }

      final response = await _supabase.functions.invoke(
        'verify-guest-post',
        body: {
          'tx_id': _txIdCtrl.text.trim().toUpperCase(),
          'requested_weeks': _selectedWeeks,
          'listing_payload': {
            'category_id': _selectedCategoryId,
            'category_name': _selectedCategoryName,
            'title': _titleCtrl.text.trim(),
            'unit_price': double.tryParse(_priceCtrl.text) ?? 0.0,
            'quantity': double.tryParse(_qtyCtrl.text) ?? 1.0,
            'unit': _selectedUnit == 'Others'
                ? _customUnitCtrl.text.trim()
                : _selectedUnit,
            'location': _locCtrl.text.trim(),
            'contact_phone': _phoneCtrl.text.trim(),
            'transaction_ref': _txIdCtrl.text.trim().toUpperCase(),
            'description': _descCtrl.text.trim(),
            'image_urls': uploadedUrls,
          },
        },
      );

      if (response.data['success'] == true) {
        _showSnackBar("Post Live!", Colors.green);
        context.go('/');
      } else {
        throw Exception(response.data['error'] ?? "Submission failed");
      }
    } catch (e) {
      _showSnackBar("Error: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String m, Color c) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: c));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text("PUBLIC MARKETPLACE"),
        backgroundColor: mizanGreen,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mizanGreen))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildImageGrid(),
                    const SizedBox(height: 20),
                    _buildPaymentNoticeBox(),
                    _buildInstructionBox(),
                    _buildInput(_txIdCtrl, "TELEBIRR TRANSACTION ID"),
                    _buildInput(_titleCtrl, "Product Title"),
                    CategorySelector(
                      selectedCategoryName: _selectedCategoryName,
                      onCategorySelected: (id, name) {
                        setState(() {
                          _selectedCategoryId = id;
                          _selectedCategoryName = name;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInput(
                            _priceCtrl,
                            "Price (ETB)",
                            isDecimal: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInput(
                            _qtyCtrl,
                            "Quantity",
                            isDecimal: true,
                          ),
                        ),
                      ],
                    ),
                    _buildUnitSection(),
                    _buildInput(_phoneCtrl, "Contact Phone"),
                    _buildInput(_locCtrl, "Location"),
                    _buildInput(_descCtrl, "Description", isMultiline: true),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mizanGreen,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        "SUBMIT",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPaymentNoticeBox() => Container(
    padding: const EdgeInsets.all(10),
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      border: Border.all(color: mizanGold),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Text(
          "Required: ${_calculatePublicFee().toStringAsFixed(0)} ETB",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        DropdownButton<int>(
          value: _selectedWeeks,
          items: [1, 2, 4]
              .map(
                (w) => DropdownMenuItem(
                  value: w,
                  child: Text("$w Week(s) Visibility"),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => _selectedWeeks = v!),
        ),
      ],
    ),
  );

  Widget _buildInstructionBox() => Container(
    padding: const EdgeInsets.all(12),
    margin: const EdgeInsets.only(bottom: 15),
    decoration: BoxDecoration(
      color: Colors.blue.shade50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Text(
      "INSTRUCTION: Send the required ETB to Tariku Gebretsadik (0962274450) via Telebirr. Copy the transaction_id from the incoming SMS from 127 and paste it above.",
      style: TextStyle(fontSize: 12),
    ),
  );

  Widget _buildImageGrid() => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: List.generate(
      4,
      (i) => GestureDetector(
        onTap: () async {
          final img = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 40,
          );
          if (img != null) {
            final b = await img.readAsBytes();
            setState(() => _imageBytesList[i] = b);
          }
        },
        child: Container(
          height: 75,
          width: 75,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _imageBytesList[i] != null ? mizanGreen : Colors.grey,
            ),
          ),
          child: _imageBytesList[i] != null
              ? Image.memory(_imageBytesList[i]!, fit: BoxFit.cover)
              : const Icon(Icons.add_a_photo),
        ),
      ),
    ),
  );

  Widget _buildUnitSection() => Column(
    children: [
      DropdownButtonFormField<String>(
        value: _selectedUnit,
        items: [
          'kg',
          'Quintal',
          'Ton',
          'Head',
          'Pcs',
          'Bale',
          'Others',
        ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
        onChanged: (v) => setState(() => _selectedUnit = v),
        decoration: const InputDecoration(
          labelText: "Unit",
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
      ),
      if (_selectedUnit == 'Others')
        _buildInput(_customUnitCtrl, "Custom Unit Name"),
    ],
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
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
    ),
  );
}
