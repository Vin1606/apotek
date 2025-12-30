import 'package:flutter/material.dart';
import 'package:apotek/model/obat.dart';
import 'package:apotek/service/api_service.dart';
import 'package:apotek/pages/obat/create_obat.dart';
import 'package:apotek/pages/obat/edit_page.dart';

class ObatPage extends StatefulWidget {
  const ObatPage({super.key});

  @override
  State<ObatPage> createState() => _ObatPageState();
}

class _ObatPageState extends State<ObatPage>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late Future<List<Obat>> _obatList;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  late AnimationController _animationController;

  // Palet Warna Modern
  static const Color primaryColor = Color(0xFF1E88E5);
  static const Color secondaryColor = Color(0xFF26A69A);
  static const Color accentColor = Color(0xFF7E57C2);
  static const Color backgroundColor = Color(0xFFF7F9FC); // Lebih cerah dikit
  static const Color textDark = Color(0xFF2D3142);
  static const Color textGrey = Color(0xFF909399);

  @override
  void initState() {
    super.initState();
    _obatList = _fetchObat();
    _searchController.addListener(() {
      setState(() {});
    });
    // Controller untuk animasi list item
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Obat>> _fetchObat() async {
    try {
      final List<Obat> response = await _apiService.fetchData();
      return response;
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> _confirmDelete(int id, String name) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Hapus Obat?'),
            content: Text(
              'Anda yakin ingin menghapus "$name"? Data yang dihapus tidak bisa dikembalikan.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final success = await _apiService.deleteObat(id);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil menghapus $name'),
              backgroundColor: secondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Refresh list
          setState(() {
            _obatList = _fetchObat();
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus obat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

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
      body: CustomScrollView(
        physics:
            const BouncingScrollPhysics(), // Efek membal saat scroll mentok
        slivers: [
          // --- HEADER & SEARCH ---
          SliverAppBar(
            expandedHeight: 160, // Sedikit dipendekkan agar proporsional
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: primaryColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: EdgeInsets.zero, // Custom positioning
              title:
                  _isSearching
                      ? Container(
                        height: 45,
                        margin: const EdgeInsets.fromLTRB(50, 0, 50, 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          cursorColor: Colors.white,
                          decoration: InputDecoration(
                            hintText: 'Cari nama obat...',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(
                                        Icons.clear,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed:
                                          () => _searchController.clear(),
                                    )
                                    : null,
                          ),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_pharmacy_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Apotek Digital',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                letterSpacing: 0.5,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1976D2), Color(0xFF26A69A)],
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Dekorasi Background Abstrak
                    Positioned(
                      right: -40,
                      top: -40,
                      child: _bgCircle(200, opacity: 0.1),
                    ),
                    Positioned(
                      left: -30,
                      bottom: -30,
                      child: _bgCircle(140, opacity: 0.1),
                    ),
                    Positioned(
                      left: 40,
                      top: 40,
                      child: _bgCircle(80, opacity: 0.05),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) _searchController.clear();
                    });
                  },
                ),
              ),
            ],
          ),

          // --- STATISTIK ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
              child: FutureBuilder<List<Obat>>(
                future: _obatList,
                builder: (context, snapshot) {
                  final totalObat = snapshot.data?.length ?? 0;
                  final totalStok =
                      snapshot.data?.fold<int>(
                        0,
                        (sum, obat) => sum + obat.stock,
                      ) ??
                      0;
                  final habisStok =
                      snapshot.data?.where((o) => o.stock == 0).length ?? 0;

                  return Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.medication_rounded,
                        label: 'Total Jenis',
                        value: totalObat.toString(),
                        color: primaryColor,
                        delay: 0,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.inventory_2_rounded,
                        label: 'Total Stok',
                        value: totalStok.toString(),
                        color: secondaryColor,
                        delay: 100,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.warning_rounded,
                        label: 'Stok Habis',
                        value: habisStok.toString(),
                        color: Colors.orange,
                        delay: 200,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // --- SECTION TITLE & REFRESH ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Obat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textDark,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _obatList = _fetchObat();
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 16,
                            color: primaryColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- LIST DATA ---
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: FutureBuilder<List<Obat>>(
              future: _obatList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Gagal Memuat',
                      subtitle:
                          'Periksa koneksi internet Anda\n${snapshot.error}',
                      color: Colors.red,
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Belum Ada Obat',
                      subtitle: 'Tekan tombol + untuk menambah data',
                      color: Colors.grey,
                    ),
                  );
                }

                final obats = snapshot.data!;
                final filteredObats =
                    obats.where((obat) {
                      final query = _searchController.text.toLowerCase();
                      return obat.name.toLowerCase().contains(query);
                    }).toList();

                if (filteredObats.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Tidak Ditemukan',
                      subtitle: 'Coba kata kunci pencarian lain',
                      color: Colors.grey,
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final obat = filteredObats[index];
                    // Menambahkan animasi fade in slide up
                    return _buildAnimatedItem(
                      index: index,
                      child: _buildObatCard(obat, index),
                    );
                  }, childCount: filteredObats.length),
                );
              },
            ),
          ),

          // Padding bawah agar item terakhir tidak tertutup FAB
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateObatPage()));
          if (result == true) {
            setState(() {
              _obatList = _fetchObat();
            });
          }
        },
        backgroundColor: primaryColor,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _bgCircle(double size, {double opacity = 0.1}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }

  // Widget Animasi Masuk
  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 100)), // Staggered
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)), // Slide Up
          child: Opacity(opacity: value, child: child),
        );
      },
      child: child,
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required int delay,
  }) {
    // Animasi stat card juga
    return Expanded(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 600 + delay),
        curve: Curves.easeOutBack,
        builder: (context, val, _) {
          return Transform.scale(
            scale: val,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 50, color: color),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: textGrey, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildObatCard(Obat obat, int index) {
    final isLowStock = obat.stock > 0 && obat.stock <= 10;
    final isOutOfStock = obat.stock == 0;

    // Default Icon / Fallback
    Widget defaultIcon = Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: _getColorForIndex(index).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Icon(
          Icons.medication_rounded,
          color: _getColorForIndex(index),
          size: 32,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to detail
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GAMBAR
                Hero(
                  tag: 'obat_${obat.id}', // Efek animasi jika pindah halaman
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child:
                        (obat.image != null && obat.image!.isNotEmpty)
                            ? Image.network(
                              obat.image!,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => defaultIcon,
                              loadingBuilder: (ctx, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[100],
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                            )
                            : defaultIcon,
                  ),
                ),
                const SizedBox(width: 16),

                // KONTEN TEKS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Stok di Atas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStockBadge(
                            obat.stock,
                            isLowStock,
                            isOutOfStock,
                          ),
                          if (isOutOfStock)
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 16,
                              color: Colors.red,
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Nama Obat
                      Text(
                        obat.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textDark,
                        ),
                      ),

                      // Deskripsi Singkat
                      const SizedBox(height: 4),
                      Text(
                        obat.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textGrey,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Harga
                      Text(
                        'Rp ${_formatCurrency(obat.price)}',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                // Tombol Edit
                IconButton(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditObatPage(obat: obat),
                      ),
                    );
                    if (result == true) {
                      setState(() {
                        _obatList = _fetchObat();
                      });
                    }
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    color: Colors.blue.withOpacity(0.6),
                  ),
                  tooltip: 'Edit',
                ),

                // Tombol Hapus
                IconButton(
                  onPressed: () => _confirmDelete(obat.id, obat.name),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.withOpacity(0.6),
                  ),
                  tooltip: 'Hapus',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStockBadge(int stock, bool isLowStock, bool isOutOfStock) {
    Color color;
    String text;

    if (isOutOfStock) {
      color = Colors.red;
      text = 'Habis';
    } else if (isLowStock) {
      color = Colors.orange;
      text = 'Sisa $stock';
    } else {
      color = Colors.green;
      text = '$stock Unit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      primaryColor,
      secondaryColor,
      accentColor,
      const Color(0xFFFF7043),
      const Color(0xFF42A5F5),
      const Color(0xFFAB47BC),
    ];
    return colors[index % colors.length];
  }
}
