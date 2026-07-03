// File Path: lib/features/admin/admin_approval_hub.dart
// MIZAN PLC: APPROVAL HUB (V7.2 - FULL PRODUCTION READY)
// FIX: SURGICAL LAYOUT GATES INJECTED TO KILL "RENDERBOX" LOOP
// RETAINS: 100% ORIGINAL MIRROR CARD LOGIC, IMAGE PREVIEWS, & PURGE HANDLERS

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminApprovalHub extends StatefulWidget {
  const AdminApprovalHub({super.key});

  @override
  State<AdminApprovalHub> createState() => _AdminApprovalHubState();
}

class _AdminApprovalHubState extends State<AdminApprovalHub>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleMarketAction(
    String pid,
    String status,
    Map<String, dynamic> updateData,
    String? taskId,
  ) async {
    try {
      await _supabase
          .from('market_listings')
          .update({
            ...updateData,
            'status': status,
            'is_sold': status == 'sold',
            'updated_at': DateTime.now().toUtc().toIso8601String(),
            if (status == 'approved')
              'approved_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', pid);

      if (taskId != null) {
        await _supabase
            .from('admin_todo_list')
            .update({
              'status': 'completed',
              'metadata': {
                'last_action': status,
                'processed_by_admin': _supabase.auth.currentUser?.id,
                'processed_at': DateTime.now().toUtc().toIso8601String(),
              },
            })
            .eq('id', taskId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Listing ${status.toUpperCase()} Successfully"),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint("Mizan PLC Logic Error: $e");
    }
  }

  Future<void> _purgeItem(String pid, String tid) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Permanent Purge"),
        content: const Text("Remove this product and task forever?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              "PURGE ALL",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.from('market_listings').delete().eq('id', pid);
      await _supabase.from('admin_todo_list').delete().eq('id', tid);
    }
  }

  @override
  Widget build(BuildContext context) {
    // STABILIZATION GATE: LayoutBuilder ensures parent height is locked
    // before the StreamBuilder attempts to render the TabBarView.
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Container(
              color: const Color(0xFF1B5E20),
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFC6A664),
                indicatorWeight: 3,
                tabs: [
                  _buildTab("AGENTS"),
                  _buildTab("NON-PARTNER"),
                  _buildTab("SYSTEM"),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _supabase
                    .from('admin_todo_list')
                    .stream(primaryKey: ['id'])
                    .order('created_at', ascending: false),
                builder: (context, snapshot) {
                  if (snapshot.hasError)
                    return Center(child: Text("Error: ${snapshot.error}"));
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final allTasks = snapshot.data ?? [];

                  final agentTasks = allTasks
                      .where(
                        (t) => (t['title'] ?? '')
                            .toString()
                            .toUpperCase()
                            .contains('AGENT'),
                      )
                      .toList();
                  final nonPartnerTasks = allTasks
                      .where(
                        (t) => (t['title'] ?? '')
                            .toString()
                            .toUpperCase()
                            .contains('NON-PARTNER'),
                      )
                      .toList();
                  final systemTasks = allTasks
                      .where(
                        (t) =>
                            !agentTasks.contains(t) &&
                            !nonPartnerTasks.contains(t),
                      )
                      .toList();

                  // FIX: TabBarView must be inside a constrained Expanded to prevent "NEEDS-PAINT" loop
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTaskList(agentTasks),
                      _buildTaskList(nonPartnerTasks),
                      _buildTaskList(systemTasks),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(String label) {
    return Tab(
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) return const Center(child: Text("No pending tasks."));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _AdminProductMirrorCard(
        key: ValueKey(filtered[index]['id']),
        task: filtered[index],
        onUpdate: _handleMarketAction,
        onPurge: _purgeItem,
      ),
    );
  }
}

class _AdminProductMirrorCard extends StatefulWidget {
  final Map<String, dynamic> task;
  final Function(String, String, Map<String, dynamic>, String?) onUpdate;
  final Function(String, String) onPurge;

  const _AdminProductMirrorCard({
    super.key,
    required this.task,
    required this.onUpdate,
    required this.onPurge,
  });

  @override
  State<_AdminProductMirrorCard> createState() =>
      _AdminProductMirrorCardState();
}

class _AdminProductMirrorCardState extends State<_AdminProductMirrorCard> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _title, _price, _qty, _loc, _phone, _desc, _payRef;
  String? _selectedCategory, _selectedUnit;
  Map<String, dynamic>? _userProfile;
  bool _initialized = false;
  bool _isManualEditing = false;

  final List<String> _categories = [
    'Animal Feed',
    'Livestock',
    'Farm Tools',
    'Seeds/Crops',
    'Agri-products',
    'Others',
  ];
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
    _title = TextEditingController();
    _price = TextEditingController();
    _qty = TextEditingController();
    _loc = TextEditingController();
    _phone = TextEditingController();
    _desc = TextEditingController();
    _payRef = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _qty.dispose();
    _loc.dispose();
    _phone.dispose();
    _desc.dispose();
    _payRef.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getFormMap() => {
    'title': _title.text.trim(),
    'unit_price': double.tryParse(_price.text) ?? 0,
    'quantity': double.tryParse(_qty.text) ?? 1,
    'category_name': _selectedCategory,
    'unit': _selectedUnit,
    'location': _loc.text.trim(),
    'contact_phone': _phone.text.trim(),
    'description': _desc.text.trim(),
    'payment_ref': _payRef.text.trim(),
  };

  Future<void> _fetchUserProfile(String? userId) async {
    if (userId == null || _userProfile != null) return;
    final res = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (res != null && mounted) setState(() => _userProfile = res);
  }

  @override
  Widget build(BuildContext context) {
    final productId = widget.task['product_id'] ?? '';
    final taskId = widget.task['id']?.toString();
    final bool isTaskCompleted = widget.task['status'] == 'completed';

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('market_listings')
          .stream(primaryKey: ['id'])
          .eq('id', productId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty)
          return const SizedBox.shrink();
        final product = snapshot.data!.first;
        final status = product['status'] ?? 'pending';
        final imageUrls = List<String>.from(product['image_urls'] ?? []);

        if (product['agent_id'] != null) _fetchUserProfile(product['agent_id']);

        if (!_initialized) {
          _title.text = product['title'] ?? '';
          _price.text = product['unit_price'].toString();
          _qty.text = product['quantity'].toString();
          _loc.text = product['location'] ?? '';
          _phone.text = product['contact_phone'] ?? '';
          _desc.text = product['description'] ?? '';
          _payRef.text = product['payment_ref'] ?? '';
          _selectedCategory = product['category_name'];
          _selectedUnit = product['unit'] ?? 'Head';
          _initialized = true;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 24),
          elevation: isTaskCompleted ? 1 : 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildHeader(
                status,
                isTaskCompleted,
                product['is_mizan_product'] ?? false,
              ),
              if (imageUrls.isNotEmpty) _buildImagePreview(imageUrls),
              _buildIdentityBar(product['agent_id'] != null),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDropdown(
                      "Category",
                      _categories,
                      _selectedCategory,
                      (v) => setState(() => _selectedCategory = v),
                      isTaskCompleted,
                    ),
                    const SizedBox(height: 12),
                    _buildField(
                      _title,
                      "Product Title",
                      locked: isTaskCompleted && !_isManualEditing,
                    ),
                    _buildField(
                      _phone,
                      "Contact Phone (Public)",
                      locked: isTaskCompleted && !_isManualEditing,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            _price,
                            "Price (ETB)",
                            isNum: true,
                            locked: isTaskCompleted && !_isManualEditing,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildField(
                            _qty,
                            "Quantity",
                            isNum: true,
                            locked: isTaskCompleted && !_isManualEditing,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDropdown(
                            "Unit",
                            _units,
                            _selectedUnit,
                            (v) => setState(() => _selectedUnit = v),
                            isTaskCompleted,
                          ),
                        ),
                      ],
                    ),
                    _buildField(
                      _loc,
                      "Location",
                      locked: isTaskCompleted && !_isManualEditing,
                    ),
                    _buildField(
                      _desc,
                      "Description",
                      maxLines: 2,
                      locked: isTaskCompleted && !_isManualEditing,
                    ),
                    _buildField(
                      _payRef,
                      "Transaction Reference ID",
                      locked: isTaskCompleted && !_isManualEditing,
                    ),
                    const SizedBox(height: 16),
                    _buildActions(productId, taskId, status, isTaskCompleted),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    String status,
    bool isTaskCompleted,
    bool isMizanProduct,
  ) {
    Color headerColor = isTaskCompleted
        ? Colors.blueGrey
        : const Color(0xFF1B5E20);
    if (status == 'rejected') headerColor = Colors.red[800]!;
    if (status == 'sold') headerColor = const Color(0xFFC6A664);

    return Container(
      width: double.infinity,
      color: headerColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isMizanProduct
                ? "MIZAN FACTORY"
                : (isTaskCompleted
                      ? "PROCESSED: ${status.toUpperCase()}"
                      : "PENDING REVIEW"),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          IconButton(
            icon: Icon(
              _isManualEditing ? Icons.lock_open : Icons.edit_note,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _isManualEditing = !_isManualEditing),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(List<String> urls) {
    return Container(
      height: 150,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: urls.length,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(urls[i], width: 140, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _buildIdentityBar(bool isAgent) {
    String sellerLabel = isAgent
        ? (_userProfile?['full_name'] ?? "Partner Agent")
        : "Non-Partner Listing";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.grey[50],
      child: Row(
        children: [
          Icon(
            isAgent ? Icons.business_center : Icons.person_outline,
            size: 18,
            color: const Color(0xFF1B5E20),
          ),
          const SizedBox(width: 8),
          Text(
            sellerLabel,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const Spacer(),
          if (_phone.text.isNotEmpty)
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF1B5E20).withOpacity(0.1),
              child: IconButton(
                icon: const Icon(
                  Icons.call,
                  size: 16,
                  color: Color(0xFF1B5E20),
                ),
                onPressed: () => launchUrl(Uri.parse("tel:${_phone.text}")),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? current,
    Function(String?) onChg,
    bool locked,
  ) {
    bool isReadonly = locked && !_isManualEditing;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: items.contains(current) ? current : null,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: isReadonly ? null : onChg,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: isReadonly ? Colors.grey[100] : Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String l, {
    bool isNum = false,
    int maxLines = 1,
    bool locked = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        enabled: !locked,
        maxLines: maxLines,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: l,
          isDense: true,
          filled: true,
          fillColor: locked ? Colors.grey[100] : Colors.white,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildActions(
    String pid,
    String? tid,
    String status,
    bool isTaskCompleted,
  ) {
    final bool actionable = !isTaskCompleted || _isManualEditing;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                ),
                onPressed: (!actionable || status == 'approved')
                    ? null
                    : () =>
                          widget.onUpdate(pid, 'approved', _getFormMap(), tid),
                child: const Text(
                  "APPROVE POST",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC6A664),
                  foregroundColor: Colors.black,
                ),
                onPressed: (!actionable || status == 'sold')
                    ? null
                    : () => widget.onUpdate(pid, 'sold', _getFormMap(), tid),
                child: const Text(
                  "MARK AS SOLD",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              icon: const Icon(
                Icons.cancel_outlined,
                color: Colors.red,
                size: 20,
              ),
              label: const Text(
                "REJECT",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
              onPressed: isTaskCompleted
                  ? null
                  : () => _showRejectDialog(pid, tid),
            ),
            const SizedBox(width: 16),
            TextButton.icon(
              icon: const Icon(
                Icons.delete_sweep,
                color: Colors.black,
                size: 20,
              ),
              label: const Text(
                "PURGE",
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
              onPressed: () => widget.onPurge(pid, tid ?? ''),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showRejectDialog(String pid, String? tid) async {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Listing"),
        content: TextField(
          controller: reason,
          decoration: const InputDecoration(hintText: "Reason for rejection"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onUpdate(pid, 'rejected', {
                'rejection_note': reason.text,
              }, tid);
              Navigator.pop(ctx);
            },
            child: const Text("CONFIRM REJECT"),
          ),
        ],
      ),
    );
  }
}
