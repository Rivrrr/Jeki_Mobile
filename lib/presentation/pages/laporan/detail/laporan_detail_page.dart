import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/home/data/laporan_service.dart';

class LaporanDetailPage extends StatefulWidget {
  final int laporanId;

  const LaporanDetailPage({super.key, required this.laporanId});

  @override
  State<LaporanDetailPage> createState() => _LaporanDetailPageState();
}

class _LaporanDetailPageState extends State<LaporanDetailPage> {
  Map<String, dynamic>? _laporan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() { _loading = true; _error = null; });
    final result = await LaporanService.fetchLaporanDetail(widget.laporanId);
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _laporan = Map<String, dynamic>.from(result['data'] ?? {});
        _loading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Gagal memuat detail laporan.';
        _loading = false;
      });
    }
  }

  bool _isSubmittingKonfirmasi = false;

  Future<void> _showKonfirmasiDialog() async {
    final catatanCtrl = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_outlined, color: Colors.green),
            SizedBox(width: 8),
            Text('Konfirmasi Selesai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Petugas lapangan telah menyelesaikan perbaikan pada laporan Anda. Mohon konfirmasi apakah pekerjaan telah sesuai harapan.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFD97706), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Penting: Jika Anda tidak melakukan konfirmasi dalam 7 hari, sistem akan secara otomatis menandai laporan ini tuntas dan selesai.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Catatan Tambahan (Opsional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 6),
              TextField(
                controller: catatanCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tuliskan ulasan atau tanggapan Anda...',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'batal'),
            child: const Text('Tutup', style: TextStyle(color: Colors.grey)),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'revisi'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange.shade800,
              side: BorderSide(color: Colors.orange.shade800),
            ),
            child: const Text('Perlu Perbaikan'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, 'setuju'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('✓ Setuju Selesai'),
          ),
        ],
      ),
    );

    if (result == null || result == 'batal' || !mounted) return;

    setState(() => _isSubmittingKonfirmasi = true);
    final res = await LaporanService.konfirmasiSelesai(
      widget.laporanId,
      status: result,
      catatan: catatanCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isSubmittingKonfirmasi = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res['message'] ?? 'Konfirmasi berhasil dikirim.'),
        backgroundColor: res['success'] == true ? Colors.green : Colors.red,
      ),
    );
    if (res['success'] == true) {
      await _loadDetail();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _laporan?['nomor'] ?? 'Detail Laporan',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _buildContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget? _buildBottomActions() {
    if (_laporan == null) return null;
    final status = _laporan!['status'] as String? ?? '';
    final canKonfirmasi = _laporan!['can_konfirmasi'] == true || status == 'selesai';

    if (!canKonfirmasi) return null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3))],
      ),
      child: _isSubmittingKonfirmasi
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ElevatedButton.icon(
              onPressed: _showKonfirmasiDialog,
              icon: const Icon(Icons.verified_rounded),
              label: const Text('Konfirmasi Penyelesaian Laporan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
    );
  }

  Widget _buildContent() {
    final l = _laporan!;
    final status     = l['status'] as String? ?? 'baru';
    final statusLabel = l['status_label'] as String? ?? status;
    final foto       = l['foto'] as List? ?? [];
    final riwayat    = l['riwayat'] as List? ?? [];
    final penugasan  = l['penugasan'] as Map?;
    final persentase = (l['persentase'] as num?)?.toInt() ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          _buildStatusBanner(status, statusLabel, persentase),
          const SizedBox(height: 16),

          // Foto
          if (foto.isNotEmpty) ...[
            _sectionHeader('Foto Dokumentasi'),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: foto.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    foto[i]['url'],
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 160,
                      color: AppColors.border,
                      child: const Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Detail Info Card
          _sectionHeader('Informasi Laporan'),
          const SizedBox(height: 10),
          _infoCard([
            ('Nomor',   l['nomor'] ?? '-',                    Icons.tag_rounded),
            ('Kategori',l['kategori']?['nama'] ?? '-',        Icons.category_outlined),
            ('Judul',   l['judul'] ?? '-',                    Icons.title_rounded),
            ('Kecamatan',l['kecamatan']?['nama'] ?? '-',      Icons.map_outlined),
            ('Lokasi',  l['lokasi'] ?? '(tidak diisi)',        Icons.location_on_outlined),
          ]),

          if (l['deskripsi'] != null && (l['deskripsi'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionHeader('Deskripsi'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                l['deskripsi'],
                style: const TextStyle(fontSize: 13.5, color: AppColors.textPrimary, height: 1.5),
              ),
            ),
          ],

          // Penugasan Info
          if (penugasan != null) ...[
            const SizedBox(height: 20),
            _sectionHeader('Informasi Penanganan'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (penugasan['pelaksana'] as String? ?? 'P').substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          penugasan['pelaksana'] ?? 'Petugas Lapangan',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Petugas Pelaksana Lapangan',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                        if (penugasan['catatan'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '"${penugasan['catatan']}"',
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Log Progress Harian Pengerjaan dari Pelaksana
          if ((l['progress_list'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Laporan Harian Pekerjaan Lapangan'),
            const SizedBox(height: 10),
            ...((l['progress_list'] as List).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p['persentase']}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A), fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        p['created_at'] != null ? p['created_at'].toString().split('T').first : '',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  if (p['catatan'] != null && (p['catatan'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p['catatan'],
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                  ],
                  if (p['foto_url'] != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        p['foto_url'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          height: 80,
                          color: AppColors.border,
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ))),
          ],

          // Riwayat Status Timeline
          if (riwayat.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Riwayat Status'),
            const SizedBox(height: 10),
            _buildTimeline(riwayat),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String status, String label, int persentase) {
    final (color, bg) = _statusColors(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_statusIcon(status), color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
              ),
              const Spacer(),
              if (['dikerjakan', 'selesai', 'dikonfirmasi'].contains(status))
                Text(
                  '$persentase%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                ),
            ],
          ),
          if (['dikerjakan'].contains(status)) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: persentase / 100.0,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeline(List riwayat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: riwayat.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value as Map;
          final isLast = i == riwayat.length - 1;
          final (color, _) = _statusColors(r['status_sesudah'] ?? '');
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(width: 2, color: AppColors.border),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeFirst(r['status_sesudah'] ?? ''),
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold, color: color,
                          ),
                        ),
                        if (r['catatan'] != null && (r['catatan'] as String).isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            r['catatan'],
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                        if (r['tanggal'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(r['tanggal']),
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _infoCard(List<(String, String, IconData)> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final (label, value, icon) = e.value;
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(icon, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: Text(label,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ),
                    const Text('  :  ', style: TextStyle(color: AppColors.textMuted)),
                    Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    );
  }

  (Color, Color) _statusColors(String status) {
    return switch (status) {
      'baru'        => (AppColors.statusPending, AppColors.statusPendingBg),
      'ditinjau'    => (AppColors.statusVerification, AppColors.statusVerificationBg),
      'ditolak'     => (AppColors.error, const Color(0xFFFFEBEE)),
      'ditugaskan'  => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'dikerjakan'  => (AppColors.statusProcessing, AppColors.statusProcessingBg),
      'selesai'     => (AppColors.statusCompleted, AppColors.statusCompletedBg),
      'dikonfirmasi'=> (AppColors.statusCompleted, AppColors.statusCompletedBg),
      _             => (AppColors.textSecondary, AppColors.border),
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'baru'        => Icons.fiber_new_rounded,
      'ditinjau'    => Icons.search_rounded,
      'ditolak'     => Icons.cancel_rounded,
      'ditugaskan'  => Icons.assignment_rounded,
      'dikerjakan'  => Icons.engineering_rounded,
      'selesai'     => Icons.check_circle_rounded,
      'dikonfirmasi'=> Icons.verified_rounded,
      _             => Icons.circle,
    };
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')} WIB';
    } catch (_) {
      return iso;
    }
  }
}
