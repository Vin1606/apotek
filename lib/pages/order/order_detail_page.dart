import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';
import 'package:apotek/pages/order/payment_page.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _order;
  bool _loading = true;
  Map<String, dynamic>? _profile;
  bool _acting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getOrderById(widget.orderId);
    final profResp = await _api.getCurrentUser();
    final prof = profResp != null && profResp['data'] != null ? profResp['data'] : null;
    setState(() {
      _order = res?['data'];
      _profile = prof != null ? Map<String, dynamic>.from(prof) : null;
      _loading = false;
    });
  }

  bool get _isOwner {
    try {
      final uid = _order?['user_id'];
      final pid = _profile?['id'];
      return uid != null && pid != null && uid == pid;
    } catch (_) {
      return false;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Order'),
        content: const Text('Apakah Anda yakin ingin membatalkan order ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _acting = true);
    final ok = await _api.cancelOrder(widget.orderId);
    setState(() => _acting = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order dibatalkan'), backgroundColor: Colors.orange),
      );
      await _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membatalkan order'), backgroundColor: Colors.red),
      );
    }
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

    final items = _order!['items'] as List? ?? [];
    final paymentStatus = _order!['payment_status'] ?? '';
    final paymentMethod = _order!['payment_method'] ?? '-';
    final paymentDetails = _order!['payment_details'] as Map<String, dynamic>? ?? {};
    final proofUrl = paymentDetails['proof_url'] as String?;
    final status = _order!['status'] ?? '';
    final isPending = status == 'pending';
    final isPaid = paymentStatus == 'paid';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(paymentStatus),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              paymentStatus.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      _infoRow('Order ID', '#${_order!['id']}'),
                      _infoRow('Status', status),
                      _infoRow('Total', 'Rp ${_order!['total_price']}'),
                      _infoRow('Metode Bayar', paymentMethod),
                      _infoRow('Alamat Pengiriman', _order!['shipping_address'] ?? '-'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Payment Proof Card (if available)
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
                            Text('Bukti Pembayaran Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const Divider(),
                        if (paymentDetails['bank'] != null)
                          _infoRow('Bank', paymentDetails['bank']),
                        if (paymentDetails['account_name'] != null)
                          _infoRow('Nama Rekening', paymentDetails['account_name']),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _showFullImage(proofUrl),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              proofUrl,
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  height: 150,
                                  color: Colors.grey[200],
                                  child: const Center(child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stack) => Container(
                                height: 150,
                                color: Colors.grey[200],
                                child: const Center(child: Icon(Icons.broken_image, size: 48)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('Ketuk untuk memperbesar', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Waiting for confirmation message
              if (!isPaid && proofUrl != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.hourglass_top, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(child: Text('Menunggu konfirmasi dari kasir...', style: TextStyle(color: Colors.orange))),
                    ],
                  ),
                ),

              if (isPaid)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 8),
                      Expanded(child: Text('Pembayaran sudah dikonfirmasi!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

              const SizedBox(height: 12),

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
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Rp ${_order!['total_price']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              if (!isPaid && isPending && proofUrl == null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _acting ? null : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentPage(orderId: widget.orderId)),
                      );
                      _load();
                    },
                    icon: const Icon(Icons.upload),
                    label: const Text('Upload Bukti Pembayaran'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

              if (!isPaid && isPending && proofUrl != null)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _acting ? null : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PaymentPage(orderId: widget.orderId)),
                      );
                      _load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Update Bukti Pembayaran'),
                  ),
                ),

              if (isPending && _isOwner) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _acting ? null : _cancelOrder,
                    icon: _acting 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Batalkan Order', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
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
}
