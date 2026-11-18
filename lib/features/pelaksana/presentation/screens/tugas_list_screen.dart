import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/pelaksana/data/tugas_service.dart';
import 'package:infrast/features/pelaksana/presentation/screens/tugas_detail_screen.dart';

class TugasListScreen extends StatefulWidget {
  const TugasListScreen({super.key});

  @override
  State<TugasListScreen> createState() => _TugasListScreenState();
}

class _TugasListScreenState extends State<TugasListScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allTugas     = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _loading = true;
  String? _error;
  late TabController _tabCtrl;

  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _tabs = [
    ('semua',      'Semua'),
    ('ditugaskan', 'Baru'),
    ('dikerjakan', 'Dikerjakan'),
    ('selesai',    'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _applyFilter(_tabs[_tabCtrl.index].$1);
      }
    });
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.toLowerCase();
        _applyFilter(_tabs[_tabCtrl.index].$1);
      });
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      return (double.tryParse(val) ?? int.tryParse(val) ?? fallback).toInt();
    }
    return fallback;
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await TugasService.fetchTugas();
    if (!mounted) return;
    if (res['success'] == true) {
      final data = List<Map<String, dynamic>>.from(
          res['data']?['data'] ?? res['data'] ?? []);
      setState(() {
        _allTugas = data;
        _applyFilter(_tabs[_tabCtrl.index].$1);
        _loading = false;
      });
    } else {
      setState(() { _error = res['message']; _loading = false; });
    }
  }

  void _applyFilter(String status) {
    setState(() {
      List<Map<String, dynamic>> tempList;

      if (status == 'semua') {
        tempList = List.from(_allTugas);
      } else if (status == 'selesai') {
        tempList = _allTugas
            .where((t) => ['selesai', 'dikonfirmasi',
                'menunggu_konfirmasi_admin', 'menunggu_konfirmasi_masyarakat']
                .contains(t['laporan']?['status']))
            .toList();
      } else {
        tempList = _allTugas
            .where((t) => t['laporan']?['status'] == status)
            .toList();
      }

      if (_searchQuery.isNotEmpty) {
        tempList = tempList.where((t) {
          final laporan = t['laporan'] as Map? ?? {};
          final judul = (laporan['judul'] ?? '').toString().toLowerCase();
          final nomor = (laporan['nomor'] ?? '').toString().toLowerCase();
          return judul.contains(_searchQuery) || nomor.contains(_searchQuery);
        }).toList();
      }

      _filteredList = tempList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false, 
        toolbarHeight: 70, // Menyesuaikan tinggi sedikit
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Daftar Tugas',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            _buildConnectionStatus(), 
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), // Space untuk Search Bar + TabBar
          child: Column(
            children: [
              // ── SEARCH BAR DI HEADER (Di atas TabBar) ────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari judul atau nomor laporan...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 20),
                            onPressed: () {
                              _searchCtrl.clear();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              
              // ── TAB BAR (Filter) ─────────────────────────────────────
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
              ),
            ],
          ),
        ),
      ),
      
      // ── BODY HANYA UNTUK LIST ──────────────────────────────────────
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _filteredList.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildCard(_filteredList[i]),
                        ),
                ),
    );
  }

  Widget _buildConnectionStatus() {
    const isConnected = true; 
    final color = isConnected ? AppColors.success : AppColors.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            isConnected ? 'Terhubung' : 'Tidak terhubung',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> t) {
    final laporan     = t['laporan'] as Map? ?? {};
    final status      = laporan['status'] as String? ?? 'ditugaskan';
    final (color, bg) = _statusStyle(status);
    final persentase  = _parseInt(laporan['persentase']);

    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(
              builder: (_) => TugasDetailScreen(tugasId: t['id'] as int)))
          .then((_) => _load()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPink,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(laporan['nomor'] ?? '#',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary)),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration:
                      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
                  child: Text(laporan['status_label'] ?? status,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(laporan['judul'] ?? '',
                style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            if (t['catatan'] != null && (t['catatan'] as String).isNotEmpty)
              Text('Catatan: ${t['catatan']}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${laporan['kecamatan'] ?? '-'}'
                    '${laporan['lokasi'] != null ? ' · ${laporan['lokasi']}' : ''}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.category_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(laporan['kategori'] ?? '-',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            if (status == 'dikerjakan') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: persentase / 100.0,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$persentase%',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            ],
            if (status == 'ditugaskan') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) =>
                              TugasDetailScreen(tugasId: t['id'] as int)))
                      .then((_) => _load()),
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Lihat & Mulai Tugas',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(children: [
      SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined,
                    color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Tidak Ada Tugas',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty 
                  ? 'Pencarian "$_searchQuery" tidak ditemukan.' 
                  : 'Belum ada tugas yang ditugaskan\npada filter ini.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _statusStyle(String status) {
    return switch (status) {
      'ditugaskan'   => (AppColors.statusPending, AppColors.statusPendingBg),
      'dikerjakan'   => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'selesai'      => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi' => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      _              => (AppColors.textMuted, AppColors.background),
    };
  }
}