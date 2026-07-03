import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

class OrderForm extends StatefulWidget {
  final Map<String, dynamic> product;
  const OrderForm({super.key, required this.product});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final String orderId =
        "MZ-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}";

    try {
      // 1. Save to Supabase
      await Supabase.instance.client.from('orders').insert({
        'order_id': orderId,
        'product_name': widget.product['name_en'],
        'customer_name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'status': 'pending',
      });

      // 2. Send Telegram Notification
      final telegramMessage = """
🚀 *New Order Received!*
------------------------
*Order ID:* $orderId
*Product:* ${widget.product['name_en']}
*Customer:* ${_nameController.text}
*Phone:* ${_phoneController.text}
*Address:* ${_addressController.text}
------------------------
📞 Call customer now to provide bank details!
""";

      // Use your actual Bot Token and Chat ID here
      await http.post(
        Uri.parse('https://api.telegram.org/botYOUR_BOT_TOKEN/sendMessage'),
        body: {
          'chat_id': 'YOUR_CHAT_ID',
          'text': telegramMessage,
          'parse_mode': 'Markdown'
        },
      );

      _showSuccessDialog(orderId);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: Text(
          "Order $id Placed!\n\nOur team will call you at ${_phoneController.text} shortly to provide bank details and confirm delivery.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ordering: ${widget.product['name_en']}")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text("Product: ${widget.product['name_en']}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text("Price: ${widget.product['price']} ETB",
                  style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: "Full Name", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: "Phone Number", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: "Delivery Address (City/Area)",
                    border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Order Now",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
