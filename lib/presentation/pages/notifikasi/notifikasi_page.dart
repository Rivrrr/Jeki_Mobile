import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/home/data/laporan_service.dart';
import 'package:infrast/presentation/pages/laporan/detail/laporan_detail_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<Map<String, dynamic>> _laporan = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final result = await LaporanService.fetchMyLaporan();
    if (!mounted) return;
    if (result['success'] == true) {
      final data = List<Map<String, dynamic>>.from(result['data'] ?? []);
      setState(() { _laporan = data; _loading = false; });
    } else {
      setState(() { _error = result['message'] ?? 'Gagal memuat.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Riwayat Laporan',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _laporan.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _laporan.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _buildNotifCard(_laporan[i]),
                      ),
                    ),
    );
  }

  Widget _buildNotifCard(Map<String, dynamic> l) {
    final status = l['status'] as String? ?? 'baru';
    final (statusColor, statusBg) = _statusColors(status);
    final foto = l['foto'] as List?;
    final fotoUrl = (foto != null && foto.isNotEmpty) ? foto.first['url'] as String? : null;
    final riwayat = l['riwayat'] as List? ?? [];
    // Apakah ada update baru (status berubah dalam 3 hari terakhir)
    final hasNew = _isRecentUpdate(riwayat);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => LaporanDetailPage(laporanId: l['id'])),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: hasNew
              ? Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Baris utama
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Thumbnail
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 70,
                          height: 70,
                          child: fotoUrl != null
                              ? Image.network(fotoUrl, fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _thumb())
                              : _thumb(),
                        ),
                      ),
                      if (hasNew)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l['nomor'] ?? '',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
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
                                l['status_label'] ?? _capitalize(status),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l['judul'] ?? '-',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                l['kecamatan']?['nama'] ?? l['lokasi'] ?? '-',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),

            // Progress bar jika dikerjakan
            if (status == 'dikerjakan') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ((l['persentase'] as num?)?.toDouble() ?? 0) / 100,
                          backgroundColor: AppColors.statusProcessing.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.statusProcessing),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(l['persentase'] as num?)?.toInt() ?? 0}%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.statusProcessing,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Update terbaru dari riwayat
            if (riwayat.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getLatestUpdate(riwayat),
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  Widget _thumb() {
    return Container(
      color: AppColors.accentPink,
      child: const Icon(Icons.photo_camera_outlined, color: AppColors.primary, size: 24),
    );
  }

  Widget _buildEmpty() {
    return ListView(
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(color: AppColors.accentPink, shape: BoxShape.circle),
                  child: const Icon(Icons.notifications_none_rounded, color: AppColors.primary, size: 40),
                ),
                const SizedBox(height: 20),
                const Text('Belum Ada Laporan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'Riwayat laporan Anda akan\nmuncul di sini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
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
            onPressed: _load,
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

  bool _isRecentUpdate(List riwayat) {
    if (riwayat.isEmpty) return false;
    try {
      final last = riwayat.last as Map;
      final tanggal = last['tanggal'] ?? last['created_at'];
      if (tanggal == null) return false;
      final dt = DateTime.parse(tanggal.toString());
      return DateTime.now().difference(dt).inDays <= 3;
    } catch (_) {
      return false;
    }
  }

  String _getLatestUpdate(List riwayat) {
    try {
      final last = riwayat.last as Map;
      final status = last['status_sesudah'] as String? ?? '';
      final catatan = last['catatan'] as String? ?? '';
      if (catatan.isNotEmpty) return 'Update: $catatan';
      return 'Status diperbarui: ${_capitalize(status)}';
    } catch (_) {
      return 'Ada pembaruan status';
    }
  }

  (Color, Color) _statusColors(String status) {
    return switch (status) {
      'baru'         => (AppColors.statusPending, AppColors.statusPendingBg),
      'ditinjau'     => (AppColors.statusVerification, AppColors.statusVerificationBg),
      'ditugaskan'   => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'dikerjakan'   => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'selesai'      => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi' => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      _              => (AppColors.textSecondary, AppColors.border),
    };
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

