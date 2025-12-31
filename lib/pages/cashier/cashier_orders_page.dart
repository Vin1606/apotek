import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';
import 'cashier_order_detail_page.dart';

class CashierOrdersPage extends StatefulWidget {
  const CashierOrdersPage({super.key});

  @override
  State<CashierOrdersPage> createState() => _CashierOrdersPageState();
}

class _CashierOrdersPageState extends State<CashierOrdersPage> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  late TabController _tabController;

  // Filters
  String? _statusFilter;
  String? _paymentStatusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged(int index) {
    switch (index) {
      case 0: // All
        _statusFilter = null;
        _paymentStatusFilter = null;
        break;
      case 1: // Pending Payments
        _statusFilter = null;
        _paymentStatusFilter = 'pending';
        break;
      case 2: // Paid
        _statusFilter = null;
        _paymentStatusFilter = 'paid';
        break;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    final result = await _api.getCashierOrders(
      status: _statusFilter,
      paymentStatus: _paymentStatusFilter,
    );
    
    setState(() {
      _orders = result['data'] ?? [];
      _loading = false;
    });
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

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Order (Kasir)'),
        backgroundColor: primaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Semua'),
            Tab(text: 'Pending'),
            Tab(text: 'Paid'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('Tidak ada order'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (context, idx) {
                      final o = _orders[idx];
                      final user = o['user'];
                      final paymentStatus = o['payment_status'] ?? '';
                      final hasProof = o['payment_details'] != null && 
                                       o['payment_details']['proof_url'] != null;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(paymentStatus),
                            child: Text(
                              '${o['id']}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                          title: Text('Order #${o['id']} - ${user?['name'] ?? 'Unknown'}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Total: Rp ${o['total_price']}'),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(paymentStatus).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      paymentStatus.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _getStatusColor(paymentStatus),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (hasProof) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.receipt_long, size: 16, color: Colors.blue),
                                    const Text(' Bukti', style: TextStyle(fontSize: 11)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CashierOrderDetailPage(orderId: o['id']),
                              ),
                            );
                            _load(); // Refresh after returning
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
