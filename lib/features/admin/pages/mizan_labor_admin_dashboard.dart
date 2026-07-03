// filepath: lib/features/admin/pages/mizan_labor_admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MizanLaborAdminDashboard extends StatefulWidget {
  const MizanLaborAdminDashboard({super.key});

  @override
  State<MizanLaborAdminDashboard> createState() =>
      _MizanLaborAdminDashboardState();
}

class _MizanLaborAdminDashboardState extends State<MizanLaborAdminDashboard> {
  bool _isLoading = true;
  List<dynamic> _summaryData = [];
  List<dynamic> _allPostings = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final summary = await Supabase.instance.client.rpc(
        'get_mizan_labor_summary',
      );
      final postings = await Supabase.instance.client
          .from('labor_postings')
          .select('*, agents(name)');

      setState(() {
        _summaryData = summary;
        _allPostings = postings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text(
          "MIZAN LABOR MANAGEMENT",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatCards(isDesktop),
                  const SizedBox(height: 24),
                  const Text(
                    "Detailed Labor Registry",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildLaborTable(isDesktop),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCards(bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _summaryData.length,
      itemBuilder: (context, index) {
        final item = _summaryData[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item['skill_category'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  "${item['total_workers']}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B5E20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLaborTable(bool isDesktop) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DataTable(
        columnSpacing: isDesktop ? 40 : 10,
        columns: const [
          DataColumn(label: Text("Worker")),
          DataColumn(label: Text("Skill")),
          if (true)
            DataColumn(
              label: Text("Agent (Verifier)"),
            ), // Logic to hide on very small screens if needed
          DataColumn(label: Text("Status")),
        ],
        rows: _allPostings
            .map(
              (p) => DataRow(
                cells: [
                  DataCell(Text(p['worker_name'])),
                  DataCell(Text(p['skill_category'])),
                  DataCell(Text(p['agents']['name'])),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: p['is_available']
                            ? Colors.green[50]
                            : Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p['is_available'] ? "Available" : "Busy",
                        style: TextStyle(
                          color: p['is_available']
                              ? Colors.green[800]
                              : Colors.red[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}
