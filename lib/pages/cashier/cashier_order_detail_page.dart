import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';

class CashierOrderDetailPage extends StatefulWidget {
  final int orderId;
  const CashierOrderDetailPage({super.key, required this.orderId});

  @override
  State<CashierOrderDetailPage> createState() => _CashierOrderDetailPageState();
}

class _CashierOrderDetailPageState extends State<CashierOrderDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getCashierOrderById(widget.orderId);
    setState(() {
      _order = res?['data'];
      _loading = false;
    });
  }

  Future<void> _confirmPayment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: const Text('Apakah Anda yakin ingin mengkonfirmasi pembayaran order ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Konfirmasi')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _confirming = true);
    final res = await _api.confirmPaymentCashier(widget.orderId);
    setState(() => _confirming = false);

    final success = res['success'] == true;
    final message = res['message'] ?? (res['body'] != null ? res['body'].toString() : 'Unknown error');

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran dikonfirmasi!'), backgroundColor: Colors.green),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengkonfirmasi pembayaran: $message'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Order'), backgroundColor: primaryColor),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Order'), backgroundColor: primaryColor),
        body: const Center(child: Text('Order tidak ditemukan')),
      );
    }

    final user = _order!['user'];
    final items = _order!['items'] as List? ?? [];
    final paymentStatus = _order!['payment_status'] ?? '';
    final paymentMethod = _order!['payment_method'] ?? '-';
    final paymentDetails = _order!['payment_details'] as Map<String, dynamic>? ?? {};
    final proofUrl = paymentDetails['proof_url'] as String?;
    final paidAt = _order!['paid_at'];
    final paidBy = _order!['paidBy'];
    final isPending = paymentStatus == 'pending';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: primaryColor,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Informasi Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      _infoRow('Nama', user?['name'] ?? '-'),
                      _infoRow('Email', user?['email'] ?? '-'),
                      _infoRow('Alamat', user?['address'] ?? _order!['shipping_address'] ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Order Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detail Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      _infoRow('Order ID', '#${_order!['id']}'),
                      _infoRow('Status', _order!['status'] ?? '-'),
                      _infoRow('Total', 'Rp ${_order!['total_price']}'),
                      _infoRow('Metode Bayar', paymentMethod),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status Pembayaran'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: paymentStatus == 'paid' ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              paymentStatus.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (paidAt != null) _infoRow('Dibayar pada', paidAt.toString()),
                      if (paidBy != null) _infoRow('Dikonfirmasi oleh', paidBy['name'] ?? 'Cashier #${paidBy['id']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Payment Proof Card
              if (proofUrl != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.receipt_long, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        if (paymentDetails['bank'] != null)
                          _infoRow('Bank', paymentDetails['bank']),
                        if (paymentDetails['account_name'] != null)
                          _infoRow('Nama Rekening', paymentDetails['account_name']),
                        if (paymentDetails['amount'] != null)
                          _infoRow('Jumlah', 'Rp ${paymentDetails['amount']}'),
                        const SizedBox(height: 12),
                        const Text('Foto Bukti:', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () => _showFullImage(proofUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              proofUrl,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 200,
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stack) => Container(
                                height: 200,
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.broken_image, size: 48)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Ketuk gambar untuk memperbesar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Items Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Item Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      ...items.map((item) {
                        final obat = item['obat'] ?? {};
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(obat['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w500)),
                                    Text('${item['quantity']}x @ Rp ${item['unit_price']}', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                              ),
                              Text('Rp ${item['subtotal']}', style: const TextStyle(fontWeight: FontWeight.w500)),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm Button
              if (isPending)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _confirming ? null : _confirmPayment,
                    icon: _confirming 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.check_circle),
                    label: Text(_confirming ? 'Memproses...' : 'Konfirmasi Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              
              if (!isPending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Pembayaran sudah dikonfirmasi', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  void _showFullImage(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Bukti Pembayaran'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
