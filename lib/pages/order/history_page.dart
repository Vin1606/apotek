import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _ordersFuture;

  // Colors - Konsisten dengan halaman lain
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFF7E57C2);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color textDark = Color(0xFF2D3142);
  static const Color textGrey = Color(0xFF909399);

  @override
  void initState() {
    super.initState();
    _ordersFuture = _apiService.getOrders();
  }

  Future<void> _refresh() async {
    setState(() {
      _ordersFuture = _apiService.getOrders();
    });
  }

  String _formatCurrency(dynamic value) {
    int price = 0;
    if (value is int) {
      price = value;
    } else if (value is String) {
      price = int.tryParse(value) ?? 0;
    } else if (value is double) {
      price = value.toInt();
    }

    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString).toLocal();
      // Format sederhana: DD/MM/YYYY HH:mm
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
      case 'lunas':
        return Colors.green;
      case 'pending':
      case 'menunggu':
        return Colors.orange;
      case 'cancelled':
      case 'failed':
      case 'batal':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _translateStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'success':
      case 'completed':
        return 'Selesai';
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'cancelled':
        return 'Dibatalkan';
      case 'failed':
        return 'Gagal';
      default:
        return status ?? '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            // Gradient AppBar - Konsisten dengan halaman lain
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryColor, accentColor],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative circles
                      Positioned(
                        right: -30,
                        top: -30,
                        child: CircleAvatar(
                          radius: 80,
                          backgroundColor: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      Positioned(
                        left: -50,
                        bottom: -20,
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white.withOpacity(0.05),
                        ),
                      ),
                      // Title content
                      Positioned(
                        left: 20,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.receipt_long_rounded,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'TRANSAKSI',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Riwayat Pesanan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Lihat semua transaksi Anda',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Content
            FutureBuilder<List<dynamic>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Gagal Memuat Riwayat',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: textGrey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _refresh,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              size: 64,
                              color: accentColor.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Belum Ada Riwayat',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Riwayat pesanan Anda akan\nmuncul di sini',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final orders = snapshot.data!;

                return SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildOrderCard(order, index),
                      );
                    }, childCount: orders.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(dynamic order, int index) {
    final status = order['payment_status']?.toString() ?? 'Unknown';
    final total = order['total_price'] ?? 0;
    final date = order['created_at']?.toString();
    final orderId = order['orders_id']?.toString() ?? '-';

    // Handle items jika API menyediakannya (misal nested object)
    final items = (order['items'] is List) ? order['items'] as List : [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header dengan gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primaryColor.withOpacity(0.05),
                  accentColor.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, accentColor],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #$orderId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: textGrey.withOpacity(0.8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(date),
                              style: TextStyle(
                                color: textGrey.withOpacity(0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 14,
                        color: _getStatusColor(status),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _translateStatus(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Items List (Preview)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (items.isNotEmpty) ...[
                  ...items.take(3).map<Widget>((item) {
                    // Sesuaikan key dengan response API Anda
                    final obat = item['obat'] ?? {};
                    final name = obat['name'] ?? item['name'] ?? 'Obat';
                    final image = obat['image'];
                    final qty = item['quantity'] ?? 1;
                    final price = item['unit_price'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          // Thumbnail Image dengan gradient border
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withOpacity(0.3),
                                  accentColor.withOpacity(0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                width: 50,
                                height: 50,
                                color: Colors.grey[50],
                                child:
                                    image != null
                                        ? Image.network(
                                          image,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Icon(
                                                Icons.medication_rounded,
                                                color: primaryColor.withOpacity(
                                                  0.5,
                                                ),
                                              ),
                                        )
                                        : Icon(
                                          Icons.medication_rounded,
                                          color: primaryColor.withOpacity(0.5),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: textDark,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: secondaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$qty x Rp ${_formatCurrency(price)}',
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(price * qty)}',
                            style: const TextStyle(
                              color: textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (items.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        '+${items.length - 3} item lainnya',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ] else ...[
                  // Jika tidak ada detail item
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.inventory_2_rounded,
                          color: textGrey.withOpacity(0.5),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Detail item tidak tersedia',
                          style: TextStyle(
                            color: textGrey.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Divider dengan gradient
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        primaryColor.withOpacity(0.2),
                        accentColor.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),

                // Total Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.payments_rounded,
                            color: accentColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: textGrey,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, accentColor],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Rp ${_formatCurrency(total)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
      case 'success':
      case 'completed':
      case 'lunas':
        return Icons.check_circle_rounded;
      case 'pending':
      case 'menunggu':
        return Icons.schedule_rounded;
      case 'cancelled':
      case 'failed':
      case 'batal':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }
}
