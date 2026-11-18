import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/masyarakat/data/laporan_service.dart';
import 'package:infrast/features/masyarakat/presentation/pages/laporan/create/create_laporan_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/laporan/detail/laporan_detail_page.dart';
import 'package:infrast/features/masyarakat/presentation/widgets/shimmer_widgets.dart';

class MyLaporanPage extends StatefulWidget {
  final String? initialStatus;
  const MyLaporanPage({super.key, this.initialStatus});

  @override
  State<MyLaporanPage> createState() => _MyLaporanPageState();
}

class _MyLaporanPageState extends State<MyLaporanPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allLaporan = [];
  List<Map<String, dynamic>> _filteredList = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'semua';
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int? _currentUserId;
  late TabController _tabCtrl;

  static const _tabs = [
    ('semua', 'Semua'),
    ('baru', 'Baru'),
    ('ditinjau', 'Ditinjau'),
    ('ditugaskan', 'Ditugaskan'),
    ('dikerjakan', 'Dikerjakan'),
    ('selesai', 'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    _filterStatus = widget.initialStatus ?? 'semua';

    // Cari index tab yang sesuai dengan status awal
    int initialIndex = _tabs.indexWhere((t) => t.$1 == _filterStatus).clamp(0, _tabs.length - 1);
    _tabCtrl = TabController(length: _tabs.length, vsync: this, initialIndex: initialIndex);
    _tabCtrl.addListener(_onTabChanged);
    _loadCurrentUserId();
    _loadLaporan();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUserId() async {
    final user = await StorageService.getUser();
    if (!mounted) return;
    setState(() {
      _currentUserId = _parseInt(user?['id']);
    });
  }

  void _onTabChanged() {
    if (_tabCtrl.indexIsChanging) return;
    setState(() {
      _filterStatus = _tabs[_tabCtrl.index].$1;
      _applyFilter();
    });
  }

  /// Sinkronisasi data riwayat laporan langsung dari database backend Laravel.
  Future<void> _loadLaporan() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await LaporanService.fetchMyLaporan();
      if (!mounted) return;

      if (result['success'] == true) {
        // Ekstraksi data fleksibel (mendukung payload langsung maupun bersarang data: [...])
        final raw =
            result['data'] is Map && (result['data'] as Map).containsKey('data')
            ? result['data']['data']
            : result['data'];

        // Di Flutter Web, JSON item mungkin bertipe Map<dynamic,dynamic>
        // sehingga perlu konversi eksplisit per-item agar tidak crash.
        final data = (raw is List)
            ? raw
                  .whereType<Map>()
                  .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
                  .toList()
            : <Map<String, dynamic>>[];

        final scopedData = data
            .where((item) => _belongsToCurrentUser(item))
            .toList();

        setState(() {
          _allLaporan = scopedData;
          _applyFilter();
          _loading = false;
        });
      } else {
        setState(() {
          _error =
              result['message'] ?? 'Gagal memuat riwayat laporan dari server.';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Koneksi database bermasalah: ${e.toString()}';
        _loading = false;
      });
    }
  }

  void _applyFilter() {
    List<Map<String, dynamic>> list = List.from(_allLaporan);

    // 1. Filter status
    if (_filterStatus != 'semua') {
      list = list.where((l) {
        final s = _safeStr(l['status']).toLowerCase();
        if (_filterStatus == 'selesai') {
          return s == 'selesai' || s == 'dikonfirmasi';
        }
        if (_filterStatus == 'diproses') {
          return ['ditinjau', 'ditugaskan', 'dikerjakan'].contains(s);
        }
        return s == _filterStatus;
      }).toList();
    }

    // 2. Filter kata kunci pencarian
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((l) {
        final nomor = _safeStr(l['nomor']).toLowerCase();
        final judul = _safeStr(l['judul']).toLowerCase();
        final lokasi = _safeStr(l['lokasi']).toLowerCase();
        final kec =
            (l['kecamatan'] is Map
                    ? _safeStr((l['kecamatan'] as Map)['nama'])
                    : '')
                .toLowerCase();
        final kat =
            (l['kategori'] is Map
                    ? _safeStr((l['kategori'] as Map)['nama'])
                    : '')
                .toLowerCase();
        return nomor.contains(q) ||
            judul.contains(q) ||
            lokasi.contains(q) ||
            kec.contains(q) ||
            kat.contains(q);
      }).toList();
    }

    _filteredList = list;
  }

  int _countForStatus(String status) {
    if (status == 'semua') return _allLaporan.length;
    return _allLaporan.where((l) {
      final s = _safeStr(l['status']).toLowerCase();
      if (status == 'selesai') return s == 'selesai' || s == 'dikonfirmasi';
      if (status == 'diproses') return ['ditinjau', 'ditugaskan', 'dikerjakan'].contains(s);
      return s == status;
    }).length;
  }

  String _formatWibDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '-';
    try {
      final dt = DateTime.parse(isoString)
          .toUtc()
          .add(const Duration(hours: 7));
      const months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '${dt.day} ${months[dt.month]} ${dt.year} • $hour:$min WIB';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: canPop
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        // Judul selalu menempel rapi di sisi kiri, baik saat halaman dibuka
        // sebagai tab (tanpa tombol back) maupun lewat navigasi push (dengan
        // tombol back). Tanpa `titleSpacing: 0`, AppBar menambahkan jarak
        // default 16px yang membuat judul terlihat menjorok saat `leading`
        // bernilai null.
        titleSpacing: 4,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Laporan Saya',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Pelacakan status penanganan infrastruktur',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.normal,
                height: 1.25,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            tooltip: 'Sinkronkan Database',
            onPressed: _loadLaporan,
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(108),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                        _applyFilter();
                      });
                    },
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nomor laporan, judul, atau jalan...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _applyFilter();
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),

              // Status Filter Tabs
              TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                dividerColor: const Color(0xFFF1F5F9),
                tabs: _tabs.map((t) {
                  final count = _countForStatus(t.$1);
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t.$2),
                        if (!_loading && count > 0) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: _filterStatus == t.$1
                                  ? AppColors.primary.withValues(alpha: 0.12)
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: _filterStatus == t.$1
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: 6,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (_, index) => Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerWidget(width: 100, height: 20),
                        ShimmerWidget(width: 80, height: 20),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ShimmerWidget(width: 78, height: 78, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ShimmerWidget(height: 16),
                              const SizedBox(height: 6),
                              ShimmerWidget(height: 12),
                              const SizedBox(height: 6),
                              ShimmerWidget(height: 12),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ShimmerWidget(height: 12),
                  ],
                ),
              ),
            )
          : _error != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadLaporan,
              color: AppColors.primary,
              child: _filteredList.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      itemCount: _filteredList.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (_, i) => _buildCard(_filteredList[i]),
                    ),
            ),
    );
  }

  Widget _buildCard(Map<String, dynamic> l) {
    final status = _safeStr(l['status'], 'baru').toLowerCase();
    final (statusColor, statusBg, statusIcon) = _statusInfo(status);
    final String? fotoUrl = _getPhotoUrl(l['foto']);
    final nomor = _safeStr(l['nomor'], 'LAP-UNKNOWN');
    final kategoriMap = l['kategori'];
    final kecamatanMap = l['kecamatan'];
    final kategori = kategoriMap is Map
        ? _safeStr(kategoriMap['nama'], 'Infrastruktur')
        : 'Infrastruktur';
    final kecamatan = kecamatanMap is Map ? _safeStr(kecamatanMap['nama']) : '';
    final lokasi = _safeStr(l['lokasi']);
    final tanggal = _formatWibDate(_safeStr(l['created_at']));
    final statusLabel = _safeStr(l['status_label']);
    final bool isNeedKonfirmasi = status == 'selesai';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isNeedKonfirmasi
              ? const Color(0xFF86EFAC)
              : const Color(0xFFE2E8F0),
          width: isNeedKonfirmasi ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final laporanId = l['id'] as int?;
            if (laporanId != null) {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LaporanDetailPage(laporanId: laporanId),
                ),
              );
              // Otomatis sinkronkan kembali dari database saat user kembali dari halaman detail
              _loadLaporan();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Nomor Laporan & Status Badge
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.tag_rounded,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                nomor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                statusLabel.isNotEmpty
                                    ? statusLabel
                                    : _capitalizeFirst(status),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Middle: Thumbnail Foto + Info Laporan
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Foto Bukti
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 78,
                        height: 78,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: fotoUrl != null
                            ? Image.network(
                                fotoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => _placeholderThumb(),
                              )
                            : _placeholderThumb(),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Detail Konten
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul Laporan
                          Text(
                            _safeStr(l['judul'], 'Laporan Infrastruktur'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                              height: 1.25,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_safeStr(l['deskripsi']).isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              _shorten(_safeStr(l['deskripsi']), 110),
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                                height: 1.35,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),

                          // Kategori
                          Row(
                            children: [
                              Text(
                                _getKategoriEmoji(kategori),
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  kategori,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Lokasi Jalan / Wilayah
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 1.5),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
                                  color: Color(0xFFE91E63),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  lokasi.isNotEmpty
                                      ? (kecamatan.isNotEmpty
                                            ? '$lokasi (Kec. $kecamatan)'
                                            : lokasi)
                                      : (kecamatan.isNotEmpty
                                            ? 'Kec. $kecamatan'
                                            : 'Kabupaten Jember'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // 3. Footer: Tanggal Masuk WIB + Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 12.5,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              tanggal,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Lihat Laporan',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isNeedKonfirmasi
                                ? const Color(0xFF16A34A)
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: isNeedKonfirmasi
                              ? const Color(0xFF16A34A)
                              : AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),

                // 4. Banner Konfirmasi (Jika status selesai dan siap diverifikasi oleh masyarakat)
                if (isNeedKonfirmasi) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 15,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Pekerjaan selesai! Ketuk untuk konfirmasi kepuasan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: const Color(0xFFFCE4EC),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFFE91E63), size: 28),
      ),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.60,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Tidak Ditemukan'
                        : _filterStatus == 'semua'
                        ? 'Belum Ada Riwayat Laporan'
                        : 'Tidak Ada Laporan ${_capitalizeFirst(_filterStatus)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'Tidak ada laporan yang cocok dengan kata kunci "$_searchQuery".'
                        : 'Laporan kerusakan jalan atau jembatan yang Anda kirim akan tercatat di sini dan tersinkronisasi otomatis.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context)
                          .push(
                            MaterialPageRoute(
                              builder: (_) => const CreateLaporanScreen(),
                            ),
                          )
                          .then((_) => _loadLaporan());
                    },
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('Buat Laporan Sekarang'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: Color(0xFFDC2626),
                size: 42,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal Sinkronisasi Database',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadLaporan,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Sinkronkan Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  (Color, Color, IconData) _statusInfo(String status) {
    return switch (status) {
      'baru' => (
        const Color(0xFFE11D48),
        const Color(0xFFFFF1F2),
        Icons.fiber_new_rounded,
      ),
      'ditinjau' => (
        const Color(0xFF7C3AED),
        const Color(0xFFF5F3FF),
        Icons.manage_search_rounded,
      ),
      'ditugaskan' => (
        const Color(0xFF2563EB),
        const Color(0xFFEFF6FF),
        Icons.assignment_ind_rounded,
      ),
      'dikerjakan' => (
        const Color(0xFFD97706),
        const Color(0xFFFFFBEB),
        Icons.construction_rounded,
      ),
      'selesai' => (
        const Color(0xFF16A34A),
        const Color(0xFFF0FDF4),
        Icons.check_circle_rounded,
      ),
      'dikonfirmasi' => (
        const Color(0xFF0D9488),
        const Color(0xFFF0FDFA),
        Icons.verified_rounded,
      ),
      _ => (
        const Color(0xFF64748B),
        const Color(0xFFF1F5F9),
        Icons.help_outline_rounded,
      ),
    };
  }

  String _getKategoriEmoji(String kategori) {
    final lower = kategori.toLowerCase();
    if (lower.contains('jalan')) return '🛣️';
    if (lower.contains('jembatan')) return '🌉';
    return '📋';
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  int? _extractOwnerId(Map<String, dynamic> laporan) {
    final directKeys = [
      laporan['user_id'],
      laporan['pelapor_id'],
      laporan['masyarakat_id'],
      laporan['created_by'],
    ];

    for (final keyValue in directKeys) {
      final parsed = _parseInt(keyValue);
      if (parsed != null) return parsed;
    }

    final userMap = laporan['user'];
    if (userMap is Map) {
      final parsed = _parseInt(userMap['id']);
      if (parsed != null) return parsed;
    }

    final masyarakatMap = laporan['masyarakat'];
    if (masyarakatMap is Map) {
      final parsedUserId = _parseInt(masyarakatMap['user_id']);
      if (parsedUserId != null) return parsedUserId;
      final parsedId = _parseInt(masyarakatMap['id']);
      if (parsedId != null) return parsedId;
    }

    return null;
  }

  bool _belongsToCurrentUser(Map<String, dynamic> laporan) {
    if (_currentUserId == null) return true;
    final ownerId = _extractOwnerId(laporan);
    if (ownerId == null) return true;
    return ownerId == _currentUserId;
  }

  String _shorten(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars).trimRight()}...';
  }

  /// Konversi nilai dynamic apapun (null, int, bool, dll) menjadi String aman.
  /// Di Flutter Web, cast dynamic bisa melempar TypeError jika nilai di JS adalah undefined.
  String _safeStr(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    final s = v.toString().trim();
    if (s.isEmpty || s == 'null' || s == 'undefined') return fallback;
    return s;
  }

  /// Ekstraksi URL foto pertama secara aman untuk Web, Android, iOS, & Desktop.
  String? _getPhotoUrl(dynamic fotoData) {
    if (fotoData == null) return null;
    if (fotoData is List && fotoData.isNotEmpty) {
      final first = fotoData.first;
      if (first is Map) {
        final u = _safeStr(first['url']);
        return u.isNotEmpty ? u : null;
      }
      if (first is String) {
        final u = first.trim();
        return u.isNotEmpty ? u : null;
      }
    } else if (fotoData is String) {
      final u = fotoData.trim();
      return u.isNotEmpty ? u : null;
    }
    return null;
  }
}
