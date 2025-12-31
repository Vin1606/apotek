import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';
import 'package:apotek/pages/cashier/cashier_orders_page.dart';
import 'package:apotek/pages/order/order_detail_page.dart';

class OrdersListPage extends StatefulWidget {
  const OrdersListPage({super.key});

  @override
  State<OrdersListPage> createState() => _OrdersListPageState();
}

class _OrdersListPageState extends State<OrdersListPage> {
  final ApiService _api = ApiService();
  List<dynamic> _orders = [];
  bool _loading = true;
  String _role = '';
  bool _redirectedToCashier = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    
    // Determine role
    final profResp = await _api.getCurrentUser();
    final prof = profResp != null && profResp['data'] != null ? profResp['data'] : null;
    _role = prof != null ? (prof['role'] ?? '') : '';

    // If cashier, redirect to CashierOrdersPage
    if (_role == 'cashier' && !_redirectedToCashier && mounted) {
      _redirectedToCashier = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const CashierOrdersPage()),
      );
      return;
    }

    // For patients, fetch their orders
    final data = await _api.getOrders();
    setState(() {
      _orders = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: primaryColor),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
      : _orders.isEmpty
              ? const Center(child: Text('Belum ada order'))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, idx) {
                    final o = _orders[idx];
                    return ListTile(
                      title: Text('Order #${o['id']}'),
                      subtitle: Text('Total: Rp ${o['total_price']} • Status: ${o['payment_status'] ?? ''}'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => OrderDetailPage(orderId: o['id'])),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
