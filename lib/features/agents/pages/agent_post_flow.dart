import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:mizan_web/widgets/category_selector.dart';

class AgentPostFlow extends StatefulWidget {
  final Map<String, dynamic>? listingData;
  const AgentPostFlow({super.key, this.listingData});

  @override
  State<AgentPostFlow> createState() => _AgentPostFlowState();
}

class _AgentPostFlowState extends State<AgentPostFlow> {
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
  String? _selectedUnit = 'Head';
  Map<String, dynamic>? _selectedTierData;
  bool _isLoading = false;
  List<Map<String, dynamic>> _pricingTiers = [];
  final List<Uint8List?> _imageBytesList = List.filled(4, null);

  final Color mizanGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

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

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadPricingTiers();
    final user = _supabase.auth.currentUser;
    if (user?.phone != null) _phoneCtrl.text = user!.phone!;

    if (widget.listingData != null) {
      _titleCtrl.text = widget.listingData!['title'] ?? '';
      _priceCtrl.text = widget.listingData!['unit_price']?.toString() ?? '';
      _qtyCtrl.text = widget.listingData!['quantity']?.toString() ?? '';
      _locCtrl.text = widget.listingData!['location'] ?? '';
      _phoneCtrl.text = widget.listingData!['contact_phone'] ?? _phoneCtrl.text;
      _descCtrl.text = widget.listingData!['description'] ?? '';
      _selectedCategoryName = widget.listingData!['category_name'];
      _selectedCategoryId = widget.listingData!['category_id'];
      _selectedUnit = widget.listingData!['unit'];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadPricingTiers() async {
    final response = await _supabase
        .from('visibility_pricing')
        .select('*')
        .eq('user_role', 'partner')
        .order('weeks', ascending: true);
    if (mounted) setState(() => _pricingTiers = response);
  }

  Future<void> _handleSubmit() async {
    if (widget.listingData == null &&
        (!_formKey.currentState!.validate() ||
            _selectedTierData == null ||
            _selectedCategoryId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Select tier, category & fill all fields"),
        ),
      );
      return;
    }

    final String agentPhone = _phoneCtrl.text.trim();
    if (agentPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Phone number is required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.listingData != null) {
        await _supabase
            .from('market_listings')
            .update({
              'title': _titleCtrl.text.trim(),
              'unit_price':
                  double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
              'quantity': double.tryParse(_qtyCtrl.text) ?? 1.0,
              'description': _descCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'contact_phone': agentPhone,
            })
            .eq('id', widget.listingData!['id']);
        if (mounted) Navigator.pop(context);
      } else {
        List<String> urls = [];
        for (var img in _imageBytesList) {
          if (img != null) {
            final path =
                'partner_posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
            await _supabase.storage
                .from('market-images')
                .uploadBinary(path, img);
            urls.add(
              _supabase.storage.from('market-images').getPublicUrl(path),
            );
          }
        }

        final response = await _supabase.functions.invoke(
          'verify-partner-post',
          body: {
            'tx_id': _txIdCtrl.text.trim(),
            'requested_weeks': _selectedTierData!['weeks'],
            'amount':
                double.tryParse(_selectedTierData!['price_etb'].toString()) ??
                0.0,
            'agent_id': _supabase.auth.currentUser!.id,
            'agent_phone': agentPhone,
            'listing_payload': {
              'category_id': _selectedCategoryId,
              'category_name': _selectedCategoryName,
              'title': _titleCtrl.text.trim(),
              'description': _descCtrl.text.trim(),
              'unit_price':
                  double.tryParse(_priceCtrl.text.replaceAll(',', '')) ?? 0.0,
              'quantity': double.tryParse(_qtyCtrl.text) ?? 1.0,
              'unit': _selectedUnit == 'Others'
                  ? _customUnitCtrl.text.trim()
                  : _selectedUnit,
              'location': _locCtrl.text.trim(),
              'image_urls': urls,
            },
          },
        );

        if (response.data['success'] == true)
          context.go('/agent-portal');
        else
          throw Exception(response.data['error'] ?? "Posting failed");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: AppBar(
        title: Text(widget.listingData != null ? "EDIT" : "PORTAL"),
        backgroundColor: mizanGreen,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mizanGreen))
          : LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 60 : 20,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (widget.listingData == null) ...[
                        _buildImageGrid(),
                        const SizedBox(height: 20),
                        _buildPaymentNoticeBox(),
                        _buildInput(_txIdCtrl, "TX ID"),
                      ],
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
                              "Price",
                              isDecimal: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInput(
                              _qtyCtrl,
                              "Qty",
                              isDecimal: true,
                            ),
                          ),
                        ],
                      ),
                      _buildUnitSection(),
                      _buildInput(_phoneCtrl, "Phone"),
                      _buildInput(_locCtrl, "Location"),
                      _buildInput(_descCtrl, "Desc", isMultiline: true),
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
            ),
    );
  }

  Widget _buildPaymentNoticeBox() => Column(
    children: _pricingTiers
        .map(
          (tier) => RadioListTile<Map<String, dynamic>>(
            title: Text("${tier['weeks']} Week(s) Visibility"),
            subtitle: Text(
              "${double.tryParse(tier['price_etb'].toString())?.toStringAsFixed(2)} ETB",
            ),
            value: tier,
            groupValue: _selectedTierData,
            onChanged: (v) => setState(() => _selectedTierData = v),
          ),
        )
        .toList(),
  );

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
            setState(() => _imageBytesList[i] = bytes);
          }
        },
        child: Container(
          height: 75,
          width: 75,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: _imageBytesList[i] != null ? mizanGreen : Colors.grey,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _imageBytesList[i] != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(_imageBytesList[i]!, fit: BoxFit.cover),
                )
              : const Icon(Icons.add_a_photo, color: Colors.grey),
        ),
      ),
    ),
  );

  Widget _buildUnitSection() => Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: DropdownButtonFormField<String>(
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
