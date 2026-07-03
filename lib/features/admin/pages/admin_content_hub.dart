import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminContentHub extends StatefulWidget {
  const AdminContentHub({super.key});

  @override
  State<AdminContentHub> createState() => _AdminContentHubState();
}

class _AdminContentHubState extends State<AdminContentHub> {
  final _supabase = Supabase.instance.client;

  // Article Controllers
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'General';

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Removed Scaffold & AppBar to integrate into AdminDashboard
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildHeaderTabs(),
          Expanded(
            child: TabBarView(
              children: [
                _buildArticlesTab(),
                _buildInquiriesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderTabs() {
    return Container(
      color: Colors.white,
      child: const TabBar(
        labelColor: Color(0xFF1B5E20),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(0xFF1B5E20),
        indicatorWeight: 3,
        tabs: [
          Tab(icon: Icon(Icons.article_outlined), text: "Knowledge Base"),
          Tab(icon: Icon(Icons.forum_outlined), text: "Farmer Inquiries"),
        ],
      ),
    );
  }

  // --- ARTICLES TAB ---
  Widget _buildArticlesTab() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateArticleSheet,
        backgroundColor: const Color(0xFF1B5E20),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase
            .from('articles')
            .stream(primaryKey: ['id']).order('created_at'),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  title: Text(doc['title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${doc['category']} • By ${doc['author']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined,
                        color: Colors.redAccent),
                    onPressed: () => _deleteArticle(doc['id']),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- FARMER Q&A TAB ---
  Widget _buildInquiriesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _supabase
          .from('expert_inquiries')
          .stream(primaryKey: ['id']).order('created_at'),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final items = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final bool isAnswered = item['status'] == 'answered';

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color: isAnswered
                        ? Colors.grey.shade200
                        : const Color(0xFF1B5E20).withOpacity(0.3)),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isAnswered
                      ? Colors.grey[100]
                      : const Color(0xFF1B5E20).withOpacity(0.1),
                  child: Icon(
                    isAnswered ? Icons.check : Icons.question_mark,
                    color: isAnswered ? Colors.grey : const Color(0xFF1B5E20),
                    size: 20,
                  ),
                ),
                title: Text(item['question'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text("From: ${item['customer_name'] ?? 'Farmer'}"),
                trailing: ElevatedButton(
                  onPressed: () => _showReplyDialog(item),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isAnswered ? Colors.grey[200] : const Color(0xFF1B5E20),
                    foregroundColor: isAnswered ? Colors.black87 : Colors.white,
                    elevation: 0,
                  ),
                  child: Text(isAnswered ? "View" : "Reply"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- LOGIC ---
  void _showCreateArticleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Publish Expert Content",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: "Article Title", border: OutlineInputBorder())),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: ['Poultry', 'Dairy', 'General']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => _selectedCategory = v!,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(), labelText: "Specialty"),
            ),
            const SizedBox(height: 15),
            TextField(
                controller: _contentController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: "Write content here...",
                    border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publishArticle,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  minimumSize: const Size(double.infinity, 50)),
              child: const Text("Post to Farmer Feed",
                  style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _publishArticle() async {
    if (_titleController.text.isEmpty) return;
    await _supabase.from('articles').insert({
      'title': _titleController.text,
      'content': _contentController.text,
      'category': _selectedCategory,
      'author': 'Mizan Expert',
    });
    _titleController.clear();
    _contentController.clear();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteArticle(String id) async {
    await _supabase.from('articles').delete().eq('id', id);
  }

  void _showReplyDialog(Map<String, dynamic> item) {
    final replyController =
        TextEditingController(text: item['admin_reply'] ?? "");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Farmer Inquiry"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8)),
                child: Text("Farmer asks: ${item['question']}",
                    style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
              const SizedBox(height: 20),
              TextField(
                  controller: replyController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                      hintText: "Your expert advice...",
                      border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _supabase.from('expert_inquiries').update({
                'admin_reply': replyController.text,
                'status': 'answered'
              }).eq('id', item['id']);
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Send Expert Reply"),
          ),
        ],
      ),
    );
  }
}
