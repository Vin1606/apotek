import 'package:flutter/material.dart';
import 'package:apotek/service/api_service.dart';
// orders list accessed via named route
import 'package:apotek/pages/order/payment_page.dart';
import 'package:apotek/model/obat.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  final ApiService _api = ApiService();
  List<Obat> _all = [];
  List<Obat> _filtered = [];
  Map<int, int> _cart = {}; // obatId -> qty
  bool _loading = true;
  bool _isCheckingOut = false;
  int _ordersCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  _loadOrdersCount();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.fetchData();
      setState(() {
        _all = data;
        _filtered = data;
      });
    } catch (e) {
      // ignore
    }
    setState(() => _loading = false);
  }

  Future<void> _loadOrdersCount() async {
    try {
      final orders = await _api.getOrders();
  setState(() => _ordersCount = orders.length);
    } catch (_) {}
  }

  void _search(String q) {
    setState(() {
      if (q.isEmpty) _filtered = _all;
      else {
        _filtered = _all.where((o) => o.name.toLowerCase().contains(q.toLowerCase())).toList();
      }
    });
  }

  void _addToCart(int id) {
    setState(() {
      _cart[id] = (_cart[id] ?? 0) + 1;
    });
  }

  void _removeFromCart(int id) {
    if (!_cart.containsKey(id)) return;
    setState(() {
      final q = (_cart[id] ?? 0) - 1;
      if (q <= 0) _cart.remove(id);
      else _cart[id] = q;
    });
  }

  int _cartCount() => _cart.values.fold(0, (a, b) => a + b);

  int _cartTotal() {
    var total = 0;
    _cart.forEach((id, qty) {
      final obat = _all.firstWhere((o) => o.id == id, orElse: () => Obat(id: id, name: 'Unknown', description: '', price: 0, stock: 0));
      total += (obat.price * qty);
    });
    return total;
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;

    setState(() => _isCheckingOut = true);

    final items = _cart.entries.map((e) => {"obat_id": e.key, "quantity": e.value}).toList();
    final result = await _api.createOrder(items: items);
    if (!mounted) return;

    setState(() => _isCheckingOut = false);

    final success = result['success'] == true;
    final message = result['message'] ?? (result['body'] != null ? result['body'].toString() : null);

    if (success) {
      setState(() {
        _cart.clear();
      });

      // Try to get created order id from response
      final body = result['body'];
      int? orderId;
      try {
        if (body is Map && body['data'] != null) {
          final d = body['data'];
          if (d is Map && d['id'] != null) orderId = d['id'];
        }
      } catch (_) {}

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order berhasil dibuat')),
      );

      if (orderId != null) {
        // navigate to payment page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PaymentPage(orderId: orderId!)),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat order${message != null ? ': $message' : ''}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1E88E5);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order'),
        centerTitle: true,
        backgroundColor: primaryColor,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                tooltip: 'My Orders',
                icon: const Icon(Icons.list_alt),
                onPressed: () {
                  Navigator.pushNamed(context, '/orders').then((_) => _loadOrdersCount());
                },
              ),
              if (_ordersCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                    child: Text('$_ordersCount', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text('Keranjang: ${_cartCount()}')),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari obat...'),
                    onChanged: _search,
                  ),
                ),
                Expanded(
                  child: _filtered.isEmpty
                      ? const Center(child: Text('Tidak ada obat'))
                      : ListView.builder(
                          itemCount: _filtered.length,
                          itemBuilder: (context, idx) {
                            final o = _filtered[idx];
                            final qty = _cart[o.id] ?? 0;
                            return ListTile(
                              leading: o.image != null && o.image!.isNotEmpty
                                  ? Image.network(o.image!, width: 56, height: 56, fit: BoxFit.cover)
                                  : const Icon(Icons.medication, size: 40),
                              title: Text(o.name),
                              subtitle: Text('Rp ${o.price} • Stok: ${o.stock}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: qty > 0 ? () => _removeFromCart(o.id) : null,
                                  ),
                                  Text(qty.toString()),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: o.stock > (qty) ? () => _addToCart(o.id) : null,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
                  child: Row(
                    children: [
                      Expanded(child: Text('Total: Rp ${_cartTotal()}')),
                      ElevatedButton(
                        onPressed: (_cart.isEmpty || _isCheckingOut) ? null : _checkout,
                        child: _isCheckingOut
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
