import 'package:flutter/material.dart';
import 'package:apotek/model/obat.dart';
import 'package:apotek/pages/order/payment_page.dart';

// Class bantuan untuk menyimpan Obat + Jumlah
class _CartItem {
  final Obat obat;
  int quantity;

  _CartItem({required this.obat, required this.quantity});
}

class OrderPage extends StatefulWidget {
  // Data mentah dari dashboard (List obat yang mungkin duplikat)
  final List<Obat> initialItems;

  const OrderPage({super.key, required this.initialItems});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  // Colors - Konsisten dengan halaman lain
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFF7E57C2);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  // Kita gunakan List _CartItem agar bisa simpan quantity
  final List<_CartItem> _groupedItems = [];

  @override
  void initState() {
    super.initState();
    _groupItems();
  }

  // Logika Mengelompokkan Item (Grouping)
  void _groupItems() {
    for (var obat in widget.initialItems) {
      // Cek apakah obat sudah ada di list _groupedItems
      // Kita cek berdasarkan nama
      final index = _groupedItems.indexWhere(
        (item) => item.obat.name == obat.name,
      );

      if (index != -1) {
        // Jika sudah ada, tambah quantity-nya
        _groupedItems[index].quantity++;
      } else {
        // Jika belum ada, buat baru dengan quantity 1
        _groupedItems.add(_CartItem(obat: obat, quantity: 1));
      }
    }
  }

  // Mengubah kembali data Grouped menjadi List<Obat> biasa untuk dikirim ke Dashboard
  List<Obat> _flattenItems() {
    List<Obat> flatList = [];
    for (var item in _groupedItems) {
      for (int i = 0; i < item.quantity; i++) {
        flatList.add(item.obat);
      }
    }
    return flatList;
  }

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Hitung total harga (Harga x Quantity)
  int get _totalPrice => _groupedItems.fold(
    0,
    (sum, item) => sum + (item.obat.price * item.quantity),
  );

  void _onBack() {
    // Kirim balik data yang sudah di-flatten (bentuk List<Obat>)
    Navigator.pop(context, _flattenItems());
  }

  void _incrementQuantity(int index) {
    setState(() {
      // Cek stok sebelum nambah (Opsional, jika di model Obat ada variable stock)
      if (_groupedItems[index].quantity < _groupedItems[index].obat.stock) {
        _groupedItems[index].quantity++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stok maksimal tercapai'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _decrementQuantity(int index) {
    setState(() {
      if (_groupedItems[index].quantity > 1) {
        _groupedItems[index].quantity--;
      } else {
        // Jika sisa 1 dan dikurang, tanya mau hapus atau tidak
        _showDeleteConfirmDialog(index);
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _groupedItems.removeAt(index);
    });
  }

  Future<void> _showDeleteConfirmDialog(int index) async {
    final bool? confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Item?'),
            content: Text(
              'Hapus ${_groupedItems[index].obat.name} dari keranjang?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Hapus', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm == true) {
      _removeItem(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: CustomScrollView(
          slivers: [
            // Gradient AppBar
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: _onBack,
              ),
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
                      Positioned(
                        left: 60,
                        bottom: 30,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Keranjang Belanja',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_groupedItems.length} jenis obat',
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
            _groupedItems.isEmpty
                ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Keranjang Kosong',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tambahkan obat dari katalog',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _groupedItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCartItemCard(item, index),
                      );
                    }, childCount: _groupedItems.length),
                  ),
                ),
          ],
        ),
        bottomNavigationBar: _buildCheckoutFooter(),
      ),
    );
  }

  Widget _buildCartItemCard(_CartItem item, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Gambar Obat dengan gradient border
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    accentColor.withOpacity(0.1),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[50],
                  child:
                      item.obat.image != null
                          ? Image.network(
                            item.obat.image!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Icon(
                                  Icons.medication_rounded,
                                  color: primaryColor.withOpacity(0.5),
                                  size: 36,
                                ),
                          )
                          : Icon(
                            Icons.medication_rounded,
                            color: primaryColor.withOpacity(0.5),
                            size: 36,
                          ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info Obat & Quantity Control
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.obat.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Tombol Hapus dengan animasi
                      Material(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => _showDeleteConfirmDialog(index),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Stok tersedia
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Stok: ${item.obat.stock}',
                      style: TextStyle(
                        color: secondaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Harga
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rp ${_formatCurrency(item.obat.price)}',
                            style: const TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          if (item.quantity > 1)
                            Text(
                              'Total: Rp ${_formatCurrency(item.obat.price * item.quantity)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),

                      // --- QUANTITY CONTROLLER ---
                      Container(
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Tombol Minus
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                onTap: () => _decrementQuantity(index),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.remove_rounded,
                                    size: 18,
                                    color:
                                        item.quantity > 1
                                            ? primaryColor
                                            : Colors.grey,
                                  ),
                                ),
                              ),
                            ),

                            // Angka Quantity
                            Container(
                              constraints: const BoxConstraints(minWidth: 40),
                              alignment: Alignment.center,
                              child: Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),

                            // Tombol Plus
                            Material(
                              color: primaryColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                              child: InkWell(
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(10),
                                  bottomRight: Radius.circular(10),
                                ),
                                onTap: () => _incrementQuantity(index),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.add_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ringkasan harga
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal (${_groupedItems.fold(0, (sum, item) => sum + item.quantity)} item)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_totalPrice)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Pembayaran',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_totalPrice)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tombol Checkout dengan gradient
            SizedBox(
              width: double.infinity,
              height: 54,
              child: Container(
                decoration: BoxDecoration(
                  gradient:
                      _groupedItems.isNotEmpty
                          ? const LinearGradient(
                            colors: [primaryColor, accentColor],
                          )
                          : null,
                  color: _groupedItems.isEmpty ? Colors.grey[300] : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow:
                      _groupedItems.isNotEmpty
                          ? [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: ElevatedButton(
                  onPressed:
                      _groupedItems.isNotEmpty
                          ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text('Melanjutkan ke pembayaran...'),
                                  ],
                                ),
                                backgroundColor: secondaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );

                            List<Obat> itemsToPay = _flattenItems();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => PaymentPage(items: itemsToPay),
                              ),
                            );
                          }
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      const Text(
                        'Checkout Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
