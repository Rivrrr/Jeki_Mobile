import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/masyarakat/data/laporan_service.dart';
import 'package:infrast/features/masyarakat/presentation/pages/laporan/detail/laporan_detail_page.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<Map<String, dynamic>> _notifications = [];
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
      final raw = result['data'] is Map && (result['data'] as Map).containsKey('data') ? result['data']['data'] : result['data'];
      final reports = (raw is List) ? List<Map<String, dynamic>>.from(raw) : <Map<String, dynamic>>[];
      
      setState(() { 
        _notifications = _flattenReportsToNotifications(reports);
        _loading = false; 
      });
    } else {
      setState(() { _error = result['message'] ?? 'Gagal memuat.'; _loading = false; });
    }
  }

  List<Map<String, dynamic>> _flattenReportsToNotifications(List<Map<String, dynamic>> reports) {
    List<Map<String, dynamic>> allNotifs = [];

    for (var r in reports) {
      final reportId = r['id'];
      final nomor = r['nomor'] ?? '-';
      final riwayat = r['riwayat'] as List? ?? [];

      if (riwayat.isEmpty) {
        allNotifs.add({
          'id': 'init_$reportId',
          'reportId': reportId,
          'message': 'Laporan $nomor telah berhasil dikirim dan sedang menunggu verifikasi.',
          'timestamp': r['created_at'],
          'isRead': false,
          'type': 'info',
        });
      } else {
        for (var h in riwayat) {
          final status = h['status_sesudah'] as String? ?? '';
          final catatan = h['catatan'] as String? ?? '';
          final timestamp = h['tanggal'] ?? h['created_at'];
          
          String message = _getMessageForStatus(status, catatan, nomor);
          
          allNotifs.add({
            'id': '${reportId}_$timestamp',
            'reportId': reportId,
            'message': message,
            'timestamp': timestamp,
            'isRead': false,
            'type': 'update',
          });
        }
      }
    }
    allNotifs.sort((a, b) => (b['timestamp'] as String).compareTo(a['timestamp'] as String));
    return allNotifs;
  }

  String _getMessageForStatus(String status, String catatan, String nomor) {
    if (catatan.isNotEmpty) return 'Update $nomor: $catatan';
    
    return switch (status.toLowerCase()) {
      'baru'         => 'Laporan $nomor telah diterima dan sedang diverifikasi.',
      'ditinjau'     => 'Laporan $nomor sedang ditinjau oleh admin.',
      'ditugaskan'   => 'Laporan $nomor telah ditugaskan kepada petugas.',
      'dikerjakan'   => 'Laporan $nomor sedang dalam proses pengerjaan.',
      'selesai'      => 'Laporan $nomor telah selesai ditangani.',
      'dikonfirmasi' => 'Laporan $nomor telah dikonfirmasi selesai.',
      _              => 'Terdapat pembaruan pada laporan $nomor.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifikasi',
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
              : _notifications.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildNotificationItem(_notifications[i]),
                      ),
                    ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> n) {
    final isRead = n['isRead'] as bool;
    final timestamp = n['timestamp'] as String? ?? '';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          n['isRead'] = true;
        });
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => LaporanDetailPage(laporanId: n['reportId'])),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isRead 
              ? Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1)
              : Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isRead ? Colors.transparent : AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n['message'] ?? '-',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String ts) {
    if (ts.isEmpty) return '-';
    try {
      final dt = DateTime.parse(ts);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0 && diff.inHours < 24) {
        if (diff.inMinutes > 0) return '${diff.inMinutes} menit yang lalu';
        return 'Baru saja';
      }
      if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return ts;
    }
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
                const Text('Belum Ada Notifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                const Text(
                  'Notifikasi pembaruan laporan Anda\nakan muncul di sini.',
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
}
