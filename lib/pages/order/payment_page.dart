import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:apotek/model/obat.dart';
import 'package:apotek/service/api_service.dart';
import 'package:apotek/nav/main_nav.dart';

class PaymentPage extends StatefulWidget {
  final List<Obat> items;
  const PaymentPage({super.key, required this.items});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedPaymentMethod = 'bank_transfer';
  bool _isLoading = false;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _picker = ImagePicker();

  late Map<Obat, int> _groupedItems;

  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _processItems();
    _loadUserAddress();
  }

  void _processItems() {
    _groupedItems = {};
    for (var item in widget.items) {
      Obat? existingKey;
      for (var key in _groupedItems.keys) {
        if (key.obatsId == item.obatsId) {
          existingKey = key;
          break;
        }
      }

      if (existingKey != null) {
        _groupedItems[existingKey] = _groupedItems[existingKey]! + 1;
      } else {
        _groupedItems[item] = 1;
      }
    }
  }

  Future<void> _loadUserAddress() async {
    final profile = await _apiService.getUserProfile();
    if (profile != null && mounted) {
      setState(() {
        _addressController.text = profile.address;
      });
    }
  }

  int get _totalPrice => widget.items.fold(0, (sum, item) => sum + item.price);

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _pickImage() async {
    final XFile? returnedImage = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (returnedImage != null) {
      final bytes = await returnedImage.readAsBytes();
      setState(() {
        _selectedImage = returnedImage;
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _submitOrder() async {
    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon isi alamat pengiriman')),
      );
      return;
    }

    // Validasi gambar jika transfer bank
    if (_selectedPaymentMethod == 'bank_transfer' &&
        _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon upload bukti pembayaran')),
      );
      return;
    }

    setState(() => _isLoading = true);

    List<Map<String, dynamic>> itemsPayload = [];
    _groupedItems.forEach((obat, qty) {
      itemsPayload.add({'obats_id': obat.obatsId, 'quantity': qty});
    });

    final orderData = {
      'items': itemsPayload,
      'payment_method': _selectedPaymentMethod,
      'shipping_address': _addressController.text,
      'notes': _notesController.text,
    };

    final success = await _apiService.createOrder(
      orderData,
      // Hanya kirim gambar jika metode pembayaran adalah transfer bank
      image: _selectedPaymentMethod == 'bank_transfer' ? _selectedImage : null,
      imageBytes:
          _selectedPaymentMethod == 'bank_transfer'
              ? _selectedImageBytes
              : null,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      _showSuccessDialog();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat pesanan. Silakan coba lagi.'),
        ),
      );
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Column(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 12),
                Text('Pesanan Berhasil!'),
              ],
            ),
            content: const Text(
              'Pesanan Anda telah dibuat. Silakan lakukan pembayaran sesuai metode yang dipilih.',
              textAlign: TextAlign.center,
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  onPressed: () {
                    // Kembali ke Dashboard dan hapus semua history route
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const MainNavPage()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'OK, Kembali ke Menu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildPaymentOption(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPaymentMethod = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryColor : Colors.black87,
              ),
            ),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          image:
              _selectedImageBytes != null
                  ? DecorationImage(
                    image: MemoryImage(_selectedImageBytes!),
                    fit: BoxFit.cover,
                  )
                  : null,
        ),
        child:
            _selectedImageBytes == null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, color: Colors.grey[400], size: 40),
                    const SizedBox(height: 8),
                    Text(
                      'Tap untuk upload bukti transfer',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                )
                : Stack(
                  children: [
                    Positioned(
                      right: 8,
                      top: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _selectedImageBytes = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                        'Bayar Sekarang',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ALAMAT ---
            const Text(
              'Alamat Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Masukkan alamat lengkap penerima...',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- METODE PEMBAYARAN ---
            const Text(
              'Metode Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              'bank_transfer',
              'Transfer Bank',
              Icons.account_balance,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              'e_wallet',
              'E-Wallet (OVO/GoPay)',
              Icons.account_balance_wallet,
            ),
            const SizedBox(height: 8),
            _buildPaymentOption(
              'cod',
              'Bayar di Tempat (COD)',
              Icons.local_shipping,
            ),

            // Tampilkan upload gambar jika Transfer Bank dipilih
            if (_selectedPaymentMethod == 'bank_transfer') ...[
              const SizedBox(height: 16),
              const Text(
                'Bukti Pembayaran',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildImagePicker(),
            ],

            const SizedBox(height: 24),

            // --- RINGKASAN PESANAN ---
            const Text(
              'Ringkasan Pesanan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ..._groupedItems.entries.map((entry) {
                    final obat = entry.key;
                    final qty = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${obat.name} x $qty',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Text(
                            'Rp ${_formatCurrency(obat.price * qty)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Rp ${_formatCurrency(_totalPrice)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- CATATAN ---
            const Text(
              'Catatan (Opsional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Optional: Masukkan catatan untuk pesanan...',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
