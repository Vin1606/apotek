import 'package:flutter/material.dart';
import 'package:apotek/model/obat.dart';
import 'package:apotek/model/user.dart';
import 'package:apotek/service/api_service.dart';
import 'package:apotek/pages/auth/login.dart';
import 'package:apotek/pages/profile/profile.dart';
import 'package:apotek/pages/order/order_page.dart';

class UserDashboardPage extends StatefulWidget {
  const UserDashboardPage({super.key});

  @override
  State<UserDashboardPage> createState() => _UserDashboardPageState();
}

class _UserDashboardPageState extends State<UserDashboardPage> {
  final ApiService _apiService = ApiService();
  late Future<List<Obat>> _obatList;
  late Future<UserProfile?> _userProfile;
  final TextEditingController _searchController = TextEditingController();

  final List<Obat> _cartItems = [];

  // Colors
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFF7E57C2);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _obatList = _apiService.fetchData();
    _userProfile = _apiService.getUserProfile();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _obatList = _apiService.fetchData();
      _userProfile = _apiService.getUserProfile();
    });
  }

  void _onPesanObat(Obat obat) {
    setState(() {
      _cartItems.add(obat);
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${obat.name} ditambahkan ke keranjang'),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      ),
    );
  }

  Future<void> _navigateToCart() async {
    final updatedCart = await Navigator.push<List<Obat>>(
      context,
      MaterialPageRoute(
        builder: (context) => OrderPage(initialItems: _cartItems),
      ),
    );

    if (updatedCart != null) {
      setState(() {
        _cartItems.clear();
        _cartItems.addAll(updatedCart);
      });
    }
  }

  int get _totalPrice => _cartItems.fold(0, (sum, item) => sum + item.price);

  String _formatCurrency(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      floatingActionButton:
          _cartItems.isNotEmpty
              ? FloatingActionButton.extended(
                onPressed: _navigateToCart,
                backgroundColor: accentColor,
                icon: Badge(
                  label: Text('${_cartItems.length}'),
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  child: const Icon(
                    Icons.shopping_cart_rounded,
                    color: Colors.white,
                  ),
                ),
                label: Text(
                  'Rp ${_formatCurrency(_totalPrice)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
              : null,

      body: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          slivers: [
            // AppBar with Greeting
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onPressed: () => _showSettings(context),
                ),
              ],
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
                        left: 20,
                        bottom: 60,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_pharmacy_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Apotek Digital',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Selamat Datang,',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            FutureBuilder<UserProfile?>(
                              future: _userProfile,
                              builder: (context, snapshot) {
                                final name = snapshot.data?.name ?? 'Pasien';
                                return Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
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
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari obat yang Anda butuhkan...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: primaryColor),
                      suffixIcon:
                          _searchController.text.isNotEmpty
                              ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                              : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Quick Info Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.medication_rounded,
                        title: 'Obat Tersedia',
                        color: secondaryColor,
                        futureData: _obatList,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionCard(
                        icon: Icons.chat,
                        title: 'Chat Bot',
                        color: accentColor,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Fitur pesanan segera hadir'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Delivery Info Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        secondaryColor.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Layanan Antar Obat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pesan obat dan kami antar ke rumah Anda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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

            // Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Katalog Obat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Medicine List
            FutureBuilder<List<Obat>>(
              future: _obatList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text('Gagal memuat data: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final allObat = snapshot.data ?? [];
                final searchQuery = _searchController.text.toLowerCase();
                final filteredObat =
                    allObat.where((obat) {
                      return obat.name.toLowerCase().contains(searchQuery) ||
                          obat.description.toLowerCase().contains(searchQuery);
                    }).toList();

                if (filteredObat.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 64,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isEmpty
                                  ? 'Belum ada obat tersedia'
                                  : 'Tidak ditemukan obat "$searchQuery"',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final obat = filteredObat[index];
                      return _buildObatCard(obat);
                    }, childCount: filteredObat.length),
                  ),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required Color color,
    required Future<List<Obat>> futureData,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Obat>>(
            future: futureData,
            builder: (context, snapshot) {
              final count = snapshot.data?.length ?? 0;
              return Text(
                '$count',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Icon(Icons.arrow_forward_rounded, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObatCard(Obat obat) {
    final bool isAvailable = obat.stock > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () => _showObatDetail(obat),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[100],
                  child:
                      obat.image != null && obat.image!.isNotEmpty
                          ? Image.network(
                            obat.image!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => const Icon(
                                  Icons.medication_rounded,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                          )
                          : const Icon(
                            Icons.medication_rounded,
                            size: 40,
                            color: Colors.grey,
                          ),
                ),
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            obat.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3142),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isAvailable
                                    ? secondaryColor.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isAvailable ? 'Tersedia' : 'Habis',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isAvailable ? secondaryColor : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      obat.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rp ${_formatCurrency(obat.price)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            if (isAvailable)
                              Text(
                                'Stok: ${obat.stock}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                        // Tombol Pesan
                        SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed:
                                isAvailable ? () => _onPesanObat(obat) : null,
                            // icon: const Icon(Icons.add_shopping_cart, size: 16),
                            label: const Text('+ Pesan'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
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
        ),
      ),
    );
  }

  void _showObatDetail(Obat obat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[100],
                              child:
                                  obat.image != null && obat.image!.isNotEmpty
                                      ? Image.network(
                                        obat.image!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                              Icons.medication_rounded,
                                              size: 80,
                                              color: Colors.grey,
                                            ),
                                      )
                                      : const Icon(
                                        Icons.medication_rounded,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Name
                        Text(
                          obat.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Price
                        Text(
                          'Rp ${_formatCurrency(obat.price)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stock
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                obat.stock > 0
                                    ? secondaryColor.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            obat.stock > 0
                                ? 'Stok tersedia: ${obat.stock} unit'
                                : 'Stok habis',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color:
                                  obat.stock > 0 ? secondaryColor : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Description
                        const Text(
                          'Deskripsi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          obat.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Delivery info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.local_shipping_rounded,
                                color: secondaryColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pengiriman Tersedia',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Obat dapat dikirim ke alamat Anda',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Order Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed:
                                obat.stock > 0
                                    ? () {
                                      Navigator.pop(context);
                                      _onPesanObat(obat);
                                    }
                                    : null,
                            icon: const Icon(Icons.shopping_bag_rounded),
                            label: Text(
                              obat.stock > 0 ? 'Pesan Sekarang' : 'Stok Habis',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[500],
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showSettings(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder:
          (bottomSheetContext) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: primaryColor,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: const Text('Profil Saya'),
                  subtitle: const Text('Lihat dan edit profil'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    Navigator.push(
                      parentContext,
                      MaterialPageRoute(builder: (_) => const ProfilePage()),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    child: const Icon(Icons.logout, color: Colors.red),
                  ),
                  title: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red),
                  ),
                  subtitle: const Text('Logout dari akun'),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final confirm = await showDialog<bool>(
                      context: parentContext,
                      builder:
                          (dialogContext) => AlertDialog(
                            title: const Text('Konfirmasi Logout'),
                            content: const Text(
                              'Apakah Anda yakin ingin keluar?',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            actions: [
                              TextButton(
                                onPressed:
                                    () => Navigator.pop(dialogContext, false),
                                child: const Text('Batal'),
                              ),
                              ElevatedButton(
                                onPressed:
                                    () => Navigator.pop(dialogContext, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Keluar'),
                              ),
                            ],
                          ),
                    );

                    if (confirm == true) {
                      await _apiService.logoutUser();
                      if (mounted) {
                        Navigator.of(parentContext).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
