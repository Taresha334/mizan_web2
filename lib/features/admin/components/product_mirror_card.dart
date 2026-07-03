import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mizan_web/core/utils/pricing_logic.dart';

class ProductMirrorCard extends StatefulWidget {
  final Map<String, dynamic> task;
  final Function(
    String,
    String,
    Map<String, dynamic>,
    String,
    Map<String, dynamic>,
  )
  onUpdate;
  final Function(String, String) onPurge;
  final Function(String) onArchive;

  const ProductMirrorCard({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onPurge,
    required this.onArchive,
  });

  @override
  State<ProductMirrorCard> createState() => _ProductMirrorCardState();
}

class _ProductMirrorCardState extends State<ProductMirrorCard> {
  final _supabase = Supabase.instance.client;

  late TextEditingController _title,
      _price,
      _qty,
      _loc,
      _phone,
      _desc,
      _payRef,
      _adminNote,
      _unit,
      _category,
      _weeks;

  bool _initialized = false, _isSaving = false, _isManualEditing = false;
  bool _showReceipt = false;

  final Color mizanGreen = const Color(0xFF1B5E20);
  final Color mizanGold = const Color(0xFFC6A664);

  @override
  void initState() {
    super.initState();
    _title = TextEditingController();
    _price = TextEditingController();
    _qty = TextEditingController();
    _loc = TextEditingController();
    _phone = TextEditingController();
    _desc = TextEditingController();
    _payRef = TextEditingController();
    _adminNote = TextEditingController();
    _unit = TextEditingController();
    _category = TextEditingController();
    _weeks = TextEditingController();
  }

  @override
  void dispose() {
    for (var c in [
      _title,
      _price,
      _qty,
      _loc,
      _phone,
      _desc,
      _payRef,
      _adminNote,
      _unit,
      _category,
      _weeks,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String _getRoleFromTask() {
    final role = widget.task['role']?.toString().toUpperCase() ?? 'NON-PARTNER';
    return role;
  }

  /// Logic: Checks if the user has an active partner subscription.
  bool _checkIsRegisteredPartner() {
    // If metadata explicitly says they are a partner, use the discount.
    // In Mizan, 'NON-PARTNER' status always pays the premium.
    final bool isPartner = widget.task['is_partner_account'] ?? false;
    final String role = _getRoleFromTask();
    return isPartner && role != 'NON-PARTNER';
  }

  Future<void> _handleManualApproval(
    String productId,
    String taskId,
    int weeks,
    String ref,
  ) async {
    if (ref.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mizan Admin: Reference required for manual override."),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final double serviceFee = MizanPricing.getVisibilityFee(
        weeks: weeks,
        role: _getRoleFromTask(),
        isRegisteredPartner: _checkIsRegisteredPartner(),
      );

      await _supabase.rpc(
        'approve_market_listing_manual',
        params: {
          'p_listing_id': productId,
          'p_admin_id': user.id,
          'p_amount': serviceFee,
          'p_ref': ref,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Mizan PLC: $serviceFee ETB Verified & Approved."),
            backgroundColor: mizanGreen,
          ),
        );
      }
    } catch (e) {
      debugPrint("RPC Approval Error: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _reopenTask(String taskId, String productId) async {
    setState(() => _isSaving = true);
    try {
      await _supabase
          .from('admin_todo_list')
          .update({'status': 'pending'})
          .eq('id', taskId);
      await _supabase
          .from('market_listings')
          .update({'status': 'pending'})
          .eq('id', productId);
      if (mounted) setState(() => _isManualEditing = true);
    } catch (e) {
      debugPrint("Reopen failed: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String productId = widget.task['product_id']?.toString() ?? '';
    final String taskId = widget.task['id']?.toString() ?? '';
    final metadata = widget.task['metadata'] ?? <String, dynamic>{};
    final bool isTaskProcessed = widget.task['status'] == 'processed';
    final createdAt =
        DateTime.tryParse(widget.task['created_at'] ?? "") ?? DateTime.now();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('market_listings')
          .stream(primaryKey: ['id'])
          .eq('id', productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();

        final product = snapshot.data!.first;
        final String? receiptUrl =
            product['receipt_image_url'] ?? product['payment_screenshot_url'];
        final String currentStatus = product['status'] ?? 'pending';
        final String payStatus = product['payment_status'] ?? 'pending';
        final bool isAutoVerified =
            payStatus == 'auto_verified' || payStatus == 'verified';
        final bool isApproved = currentStatus == 'approved';
        final bool isSold = currentStatus == 'sold';

        if (!_initialized) {
          final dataSource = metadata['proposed_data'] ?? product;
          _title.text = dataSource['title'] ?? '';
          _price.text = (dataSource['unit_price'] ?? 0).toString();
          _qty.text = (dataSource['quantity'] ?? 0).toString();
          _loc.text = dataSource['location'] ?? '';
          _phone.text = dataSource['contact_phone'] ?? '';
          _desc.text = dataSource['description'] ?? '';
          _payRef.text =
              dataSource['transaction_ref'] ?? dataSource['payment_ref'] ?? '';
          _adminNote.text = product['admin_note'] ?? '';
          _unit.text = dataSource['unit'] ?? '';
          _category.text = dataSource['category_name'] ?? '';
          _weeks.text = (dataSource['visibility_duration_weeks'] ?? 1)
              .toString();
          _initialized = true;
        }

        final bool isRegistered = _checkIsRegisteredPartner();
        final double requiredServiceFee = MizanPricing.getVisibilityFee(
          weeks: int.tryParse(_weeks.text) ?? 1,
          role: _getRoleFromTask(),
          isRegisteredPartner: isRegistered,
        );

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          elevation: (isApproved || isSold) ? 2 : 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isAutoVerified
                  ? Colors.green
                  : (isTaskProcessed
                        ? Colors.black12
                        : mizanGreen.withOpacity(0.1)),
              width: 2,
            ),
          ),
          child: Opacity(
            opacity: isTaskProcessed ? 0.8 : 1.0,
            child: Column(
              children: [
                _buildHeader(isTaskProcessed, isAutoVerified, currentStatus),
                if (_showReceipt && receiptUrl != null)
                  _buildReceiptPreview(receiptUrl)
                else if (product['image_urls'] != null)
                  _buildImagePreview(List<String>.from(product['image_urls'])),
                _buildServiceFeeBanner(requiredServiceFee, isRegistered),
                _buildPaymentBar(
                  product['payment_method'] ?? 'TELEBIRR',
                  _payRef.text,
                  receiptUrl,
                  isAutoVerified,
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildField(
                        _title,
                        "Product Title",
                        isApproved || isSold,
                      ),
                      _buildField(
                        _desc,
                        "Full Description",
                        isApproved || isSold,
                        isNote: true,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              _category,
                              "Category",
                              isApproved || isSold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              _unit,
                              "Unit Type",
                              isApproved || isSold,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              _price,
                              "Farmer Price (ETB)",
                              isApproved || isSold,
                              isNum: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              _qty,
                              "Qty",
                              isApproved || isSold,
                              isNum: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildField(
                              _weeks,
                              "Weeks",
                              isApproved || isSold,
                              isNum: true,
                            ),
                          ),
                        ],
                      ),
                      _buildField(_loc, "Location", isApproved || isSold),
                      _buildField(
                        _phone,
                        "Contact Phone",
                        isApproved || isSold,
                      ),
                      _buildField(
                        _adminNote,
                        "Admin Feedback (Internal Note)",
                        isApproved || isSold,
                        isNote: true,
                      ),
                      const SizedBox(height: 12),
                      _buildPersistentActionGrid(
                        productId,
                        taskId,
                        metadata,
                        isTaskProcessed,
                        currentStatus,
                        isAutoVerified,
                        int.tryParse(_weeks.text) ?? 1,
                      ),
                      const Divider(height: 32),
                      _buildFooter(
                        createdAt,
                        isTaskProcessed,
                        taskId,
                        productId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isProc, bool auto, String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isProc
            ? Colors.grey[800]
            : (auto ? const Color(0xFF2E7D32) : mizanGreen),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isProc
                ? "RECORD PROCESSED"
                : (auto
                      ? "✓ AUTO-VERIFIED"
                      : "STATUS: ${status.toUpperCase()}"),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          if (!isProc)
            GestureDetector(
              onTap: () => setState(() => _isManualEditing = !_isManualEditing),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isManualEditing ? Icons.lock_open : Icons.edit_note,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceFeeBanner(double fee, bool isReg) => Container(
    width: double.infinity,
    color: mizanGold.withOpacity(0.1),
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "EXPECTED SERVICE FEE:",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: mizanGreen,
              ),
            ),
            Text(
              isReg ? "Partner Discount Applied" : "Non-Partner Premium Rate",
              style: TextStyle(
                fontSize: 8,
                color: mizanGold,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        Text(
          "$fee ETB",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
        ),
      ],
    ),
  );

  Widget _buildField(
    TextEditingController c,
    String l,
    bool locked, {
    bool isNum = false,
    bool isNote = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      enabled: !locked && _isManualEditing,
      maxLines: isNote ? null : 1,
      minLines: isNote ? 2 : 1,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: l,
        isDense: true,
        filled: true,
        fillColor: (locked || !_isManualEditing)
            ? const Color(0xFFF0F0F0)
            : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mizanGreen.withOpacity(0.3)),
        ),
      ),
    ),
  );

  Widget _buildPersistentActionGrid(
    String pId,
    String tId,
    Map<String, dynamic> meta,
    bool isProc,
    String status,
    bool auto,
    int weeks,
  ) {
    final bool isApproved = status == 'approved';
    final bool isSold = status == 'sold';
    final bool isRejected = status == 'rejected';

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: (isProc || isApproved)
                  ? Colors.grey
                  : (auto ? Colors.green[700] : mizanGold),
              foregroundColor: Colors.white,
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: (isProc || isApproved || _isSaving)
                ? null
                : () {
                    if (auto) {
                      _execute(pId, tId, meta, 'approved');
                    } else {
                      _handleManualApproval(pId, tId, weeks, _payRef.text);
                    }
                  },
            icon: Icon(
              auto ? Icons.verified : Icons.payments_outlined,
              size: 18,
            ),
            label: Text(
              isApproved
                  ? "LIVE ON MARKET"
                  : (auto ? "APPROVE SERVICE" : "MANUAL VERIFY & APPROVE"),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildCircleAction(
          onPressed: (isProc || isRejected)
              ? null
              : () => _execute(pId, tId, meta, 'rejected'),
          icon: Icons.cancel_outlined,
          color: (isProc || isRejected) ? Colors.grey : Colors.red,
        ),
        const SizedBox(width: 8),
        _buildCircleAction(
          onPressed: (isProc || isSold)
              ? null
              : () => widget.onUpdate(pId, 'sold', {}, tId, meta),
          icon: Icons.sell_outlined,
          color: (isProc || isSold) ? Colors.grey : Colors.orange[800]!,
        ),
      ],
    );
  }

  Widget _buildCircleAction({
    VoidCallback? onPressed,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Future<void> _execute(
    String pId,
    String tId,
    Map<String, dynamic> meta,
    String status,
  ) async {
    setState(() => _isSaving = true);
    final data = {
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
      'unit_price': double.tryParse(_price.text.replaceAll(',', '')) ?? 0.0,
      'quantity': double.tryParse(_qty.text) ?? 1.0,
      'unit': _unit.text.trim(),
      'location': _loc.text.trim(),
      'contact_phone': _phone.text.trim(),
      'category_name': _category.text.trim(),
      'visibility_duration_weeks': int.tryParse(_weeks.text) ?? 1,
      'admin_note': _adminNote.text.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      if (status == 'approved') 'payment_status': 'verified',
    };
    await widget.onUpdate(pId, status, data, tId, meta);
    if (mounted) setState(() => _isSaving = _isManualEditing = false);
  }

  Widget _buildPaymentBar(String m, String r, String? u, bool a) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: a ? Colors.green.shade50 : mizanGold.withOpacity(0.05),
      border: Border(bottom: BorderSide(color: mizanGold.withOpacity(0.1))),
    ),
    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    child: Row(
      children: [
        Icon(Icons.payment_rounded, size: 14, color: mizanGold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "REF: ${r.isEmpty ? 'PENDING' : r}",
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
        ),
        if (u != null)
          TextButton.icon(
            onPressed: () => setState(() => _showReceipt = !_showReceipt),
            icon: Icon(
              _showReceipt ? Icons.visibility_off : Icons.receipt_long,
              size: 14,
            ),
            label: Text(
              _showReceipt ? "CLOSE" : "VIEW RECEIPT",
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    ),
  );

  Widget _buildImagePreview(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.black12,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(urls[i], fit: BoxFit.cover, width: 140),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptPreview(String url) => Container(
    height: 300,
    width: double.infinity,
    margin: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: mizanGold, width: 2),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Image.network(url, fit: BoxFit.contain),
    ),
  );

  Widget _buildFooter(DateTime date, bool isProc, String tId, String pId) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('MMM dd, yyyy • hh:mm a').format(date),
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          Row(
            children: [
              if (isProc)
                IconButton(
                  onPressed: () => _reopenTask(tId, pId),
                  icon: Icon(Icons.history_rounded, color: mizanGold, size: 22),
                ),
              IconButton(
                onPressed: () => widget.onPurge(pId, tId),
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      );
}
