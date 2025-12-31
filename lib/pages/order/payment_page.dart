import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show File;

class PaymentPage extends StatefulWidget {
  final int orderId;
  const PaymentPage({super.key, required this.orderId});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final ApiService _api = ApiService();
  bool _sending = false;
  final TextEditingController _methodCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();
  XFile? _picked;
  Uint8List? _pickedBytes;

  @override
  void dispose() {
    _methodCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  Future<void> _notify() async {
    setState(() => _sending = true);
    Map<String, dynamic>? details;
    try {
      final txt = _detailsCtrl.text.trim();
      if (txt.isNotEmpty) details = {'note': txt};
    } catch (_) {}

  final method = _methodCtrl.text.trim().isEmpty ? null : _methodCtrl.text.trim();
  final ok = await _api.notifyPayment(widget.orderId, paymentMethod: method, paymentDetails: details, image: _picked, imageBytes: _pickedBytes);
    setState(() => _sending = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informasi pembayaran dikirim')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal mengirim info pembayaran')));
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran'), backgroundColor: primaryColor),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _methodCtrl,
              decoration: const InputDecoration(labelText: 'Metode pembayaran (contoh: bank, cash)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsCtrl,
              decoration: const InputDecoration(labelText: 'Catatan / detail pembayaran (opsional)'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picker = ImagePicker();
                    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
                    if (x == null) return;
                    setState(() => _picked = x);
                    if (kIsWeb) {
                      final bytes = await x.readAsBytes();
                      setState(() => _pickedBytes = bytes);
                    }
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Upload bukti (opsional)'),
                ),
                const SizedBox(width: 12),
                if (_picked != null)
                  Row(
                    children: [
                      // preview thumbnail (if web use bytes, else use path)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                        child: _pickedBytes != null
                            ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
                            : Image.file(
                                File(_picked!.path),
                                fit: BoxFit.cover,
                              ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 140,
                        child: Text(_picked!.name, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _picked = null;
                            _pickedBytes = null;
                          });
                        },
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _sending ? null : _notify,
              child: _sending ? const CircularProgressIndicator(color: Colors.white) : const Text('Kirim Info Pembayaran'),
            ),
          ],
        ),
      ),
    );
  }
}
