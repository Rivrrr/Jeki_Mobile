import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/home/data/laporan_service.dart';
import 'package:infrast/presentation/pages/laporan/detail/laporan_detail_page.dart';

class MyLaporanPage extends StatefulWidget {
  const MyLaporanPage({super.key});

  @override
  State<MyLaporanPage> createState() => _MyLaporanPageState();
}

class _MyLaporanPageState extends State<MyLaporanPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allLaporan    = [];
  List<Map<String, dynamic>> _filteredList  = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'semua';
  late TabController _tabCtrl;

  static const _tabs = [
    ('semua',     'Semua'),
    ('baru',      'Baru'),
    ('ditinjau',  'Ditinjau'),
    ('ditugaskan','Ditugaskan'),
    ('dikerjakan','Dikerjakan'),
    ('selesai',   'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(_onTabChanged);
    _loadLaporan();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    setState(() {
      _filterStatus = _tabs[_tabCtrl.index].$1;
      _applyFilter();
    });
  }

  Future<void> _loadLaporan() async {
    setState(() { _loading = true; _error = null; });
    final result = await LaporanService.fetchMyLaporan();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = List<Map<String, dynamic>>.from(result['data'] ?? []);
      setState(() {
        _allLaporan = data;
        _applyFilter();
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Gagal memuat laporan.';
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    if (_filterStatus == 'semua') {
      _filteredList = List.from(_allLaporan);
    } else {
      _filteredList = _allLaporan
          .where((l) => l['status'] == _filterStatus)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Laporan Saya',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _loadLaporan,
                  color: AppColors.primary,
                  child: _filteredList.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildCard(_filteredList[i]),
                        ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> l) {
    final status = l['status'] as String? ?? 'baru';
    final (statusColor, statusBg) = _statusColors(status);
    final foto = l['foto'] as List?;
    final fotoUrl = (foto != null && foto.isNotEmpty) ? foto.first['url'] as String? : null;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanDetailPage(laporanId: l['id'])),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: fotoUrl != null
                    ? Image.network(fotoUrl, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholderThumb())
                    : _placeholderThumb(),
              ),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l['nomor'] ?? '',
                            style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l['status_label'] ?? _capitalizeFirst(status),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l['judul'] ?? '',
                      style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            l['kecamatan']?['nama'] ?? l['lokasi'] ?? '-',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.category_outlined, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          l['kategori']?['nama'] ?? '-',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: AppColors.accentPink,
      child: const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 28),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.55,
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
                  child: const Icon(Icons.folder_open_outlined, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  _filterStatus == 'semua'
                      ? 'Belum Ada Laporan'
                      : 'Tidak Ada Laporan ${_tabs[_tabCtrl.index].$2}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tekan tombol kamera di beranda\nuntuk membuat laporan baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadLaporan,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    return switch (status) {
      'baru'        => (AppColors.statusPending, AppColors.statusPendingBg),
      'ditinjau'    => (AppColors.statusVerification, AppColors.statusVerificationBg),
      'ditugaskan'  => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'dikerjakan'  => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'selesai'     => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi'=> (AppColors.statusCompleted, AppColors.statusCompletedBg),
      _             => (AppColors.textSecondary, AppColors.border),
    };
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
