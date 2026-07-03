import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mizan_web/widgets/category_selector.dart'; // Ensure this is imported

class AdminDirectPost extends StatefulWidget {
  final String? existingProductId;
  const AdminDirectPost({super.key, this.existingProductId});

  @override
  State<AdminDirectPost> createState() => _AdminDirectPostState();
}

class _AdminDirectPostState extends State<AdminDirectPost> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _payRefCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();

  // State Variables
  String? _selectedCategoryName; // Updated for CategorySelector
  String? _selectedCategoryId; // Updated for CategorySelector
  String? _selectedUnit = 'Head';
  int _selectedWeeks = 1;
  bool _isLoading = false;
  String? _createdId;
  bool _isSold = false;
  bool _isMizanFactoryProduct = true;
  String _userRole = 'admin';

  List<String> _netImages = [];
  final List<Uint8List?> _imageBytesList = List.filled(4, null);

  final Color mizanGreen = const Color(0xFF1B5E20);
  final List<String> _units = [
    'kg',
    'Quintal',
    'Ton',
    'Head',
    'Pcs',
    'Bale',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAdminSession();
    if (widget.existingProductId != null) _load(widget.existingProductId!);
  }

  Future<void> _initializeAdminSession() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();
        if (mounted && profile != null)
          setState(() => _userRole = profile['role'] ?? 'admin');
      } catch (e) {
        debugPrint("Admin Profile Fetch Error: $e");
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    _locCtrl.dispose();
    _phoneCtrl.dispose();
    _descCtrl.dispose();
    _payRefCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String id) async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('market_listings')
          .select()
          .eq('id', id)
          .single();
      setState(() {
        _createdId = id;
        _titleCtrl.text = data['title'] ?? '';
        _priceCtrl.text = data['unit_price']?.toString() ?? '';
        _qtyCtrl.text = data['quantity']?.toString() ?? '';
        _locCtrl.text = data['location'] ?? '';
        _descCtrl.text = data['description'] ?? '';
        _phoneCtrl.text = data['contact_phone'] ?? '';
        _payRefCtrl.text = data['payment_ref'] ?? '';
        _selectedCategoryName = data['category_name'];
        _selectedCategoryId = data['category_id'];
        _selectedUnit = _units.contains(data['unit']) ? data['unit'] : 'Others';
        if (_selectedUnit == 'Others')
          _customUnitCtrl.text = data['unit'] ?? '';
        _netImages = List<String>.from(data['image_urls'] ?? []);
        _isSold = data['is_sold'] ?? false;
        _isMizanFactoryProduct = data['is_mizan_product'] ?? true;
      });
    } catch (e) {
      debugPrint("Mizan Load Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null)
      return;
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      List<String> uploadedUrls = [];
      for (int i = 0; i < 4; i++) {
        if (_imageBytesList[i] != null) {
          final path =
              'mizan_factory/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await _supabase.storage
              .from('market-images')
              .uploadBinary(path, _imageBytesList[i]!);
          uploadedUrls.add(
            _supabase.storage.from('market-images').getPublicUrl(path),
          );
        }
      }

      final payload = {
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'unit_price':
            double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
        'quantity': double.tryParse(_qtyCtrl.text) ?? 1.0,
        'unit': _selectedUnit == 'Others'
            ? _customUnitCtrl.text.trim()
            : _selectedUnit,
        'location': _locCtrl.text.trim(),
        'contact_phone': _phoneCtrl.text.trim(),
        'category_name': _selectedCategoryName,
        'category_id': _selectedCategoryId,
        'image_urls': [..._netImages, ...uploadedUrls],
        'status': _isSold ? 'sold' : 'approved',
        'is_mizan_product': _isMizanFactoryProduct,
        'payment_status': 'verified',
        'visibility_duration_weeks': _selectedWeeks,
        'payment_ref': _payRefCtrl.text.trim().isEmpty
            ? "MIZAN-INTERNAL"
            : _payRefCtrl.text.trim(),
        'is_sold': _isSold,
        'agent_id': user.id,
      };

      String productId = _createdId ?? "";
      if (productId.isEmpty) {
        final res = await _supabase
            .from('market_listings')
            .insert(payload)
            .select()
            .single();
        productId = res['id'].toString();
      } else {
        await _supabase
            .from('market_listings')
            .update(payload)
            .eq('id', productId);
      }

      await _supabase.from('admin_todo_list').upsert({
        'product_id': productId,
        'title': 'FACTORY POST: ${_titleCtrl.text.trim()}',
        'task_type': 'approval',
        'status': _isSold ? 'completed' : 'pending',
        'metadata': {
          'auto_verified': true,
          'is_mizan_factory': _isMizanFactoryProduct,
          'posted_by_role': _userRole,
        },
      }, onConflict: 'product_id');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Published Successfully")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Submission Failed: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: const Text(
          "ADMIN DIRECT POST",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: mizanGreen,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _save,
        backgroundColor: mizanGreen,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.cloud_upload, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mizanGreen))
          : _buildFormContent(),
    );
  }

  Widget _buildFormContent() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Form(
      key: _formKey,
      child: Column(
        children: [
          _buildImageGrid(),
          const SizedBox(height: 20),
          _buildMizanToggle(),
          const SizedBox(height: 20),
          _buildInput(_titleCtrl, "Product Title"),
          // REPLACED: Using the new CategorySelector component
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
                  "Unit Price (ETB)",
                  isDecimal: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInput(_qtyCtrl, "Quantity", isDecimal: true),
              ),
            ],
          ),
          _buildUnitSection(),
          _buildInput(_phoneCtrl, "Contact Phone"),
          _buildInput(_locCtrl, "Location"),
          _buildInput(_descCtrl, "Description", isMultiline: true),
          _buildInput(_payRefCtrl, "Internal Notes", isOptional: true),
        ],
      ),
    ),
  );

  Widget _buildMizanToggle() => SwitchListTile(
    title: const Text("Mizan Factory Product"),
    value: _isMizanFactoryProduct,
    activeColor: mizanGreen,
    onChanged: (v) => setState(() => _isMizanFactoryProduct = v),
  );

  Widget _buildUnitSection() => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          value: _selectedUnit,
          items: _units
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
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
    ),
  );

  Widget _buildInput(
    TextEditingController c,
    String l, {
    bool isDecimal = false,
    bool isMultiline = false,
    bool isOptional = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(
      controller: c,
      maxLines: isMultiline ? null : 1,
      minLines: isMultiline ? 3 : 1,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: l,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
      validator: (v) =>
          (isOptional || (v != null && v.isNotEmpty)) ? null : "Required",
    ),
  );

  Widget _buildImageGrid() => SizedBox(
    height: 80,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) => GestureDetector(
        onTap: () async {
          final img = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 50,
          );
          if (img != null) {
            final bytes = await img.readAsBytes();
            setState(() => _imageBytesList[i] = bytes);
          }
        },
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: mizanGreen),
          ),
          child: _imageBytesList[i] != null
              ? Image.memory(_imageBytesList[i]!, fit: BoxFit.cover)
              : (_netImages.length > i
                    ? Image.network(_netImages[i], fit: BoxFit.cover)
                    : const Icon(Icons.camera_alt)),
        ),
      ),
    ),
  );
}
