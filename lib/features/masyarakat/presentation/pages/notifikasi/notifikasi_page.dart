import 'dart:async';

import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/masyarakat/data/notifikasi_service.dart';
import 'package:infrast/features/masyarakat/presentation/pages/laporan/detail/laporan_detail_page.dart';

/// Halaman riwayat notifikasi user.
///
/// Sumber data adalah tabel `notifikasi` di backend — setiap perubahan status
/// laporan membuat satu baris di sana sekaligus mengirim push FCM. Jadi riwayat
/// tetap lengkap walaupun push terlewat atau perangkat sedang offline.
class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  List<Map<String, dynamic>> _items = [];
  int _unread = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await NotifikasiService.fetchAll();
    if (!mounted) return;

    if (result['success'] == true) {
      final raw = result['data'];
      final list = (raw is List)
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList(growable: false)
          : <Map<String, dynamic>>[];
      setState(() {
        _items = list;
        _unread = (result['unread_count'] is int)
            ? result['unread_count'] as int
            : list.where((n) => n['dibaca'] != true).length;
        _loading = false;
      });
    } else {
      setState(() {
        _error = (result['message'] ?? 'Gagal memuat notifikasi.').toString();
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_unread == 0) return;
    final result = await NotifikasiService.markAllRead();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        _unread = 0;
        _items = _items
            .map((n) => {...n, 'dibaca': true})
            .toList(growable: false);
      });
      _toast('Semua notifikasi ditandai dibaca.');
    } else {
      _toast((result['message'] ?? 'Gagal menandai notifikasi.').toString());
    }
  }

  Future<void> _openItem(Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');

    if (item['dibaca'] != true) {
      setState(() {
        final idx = _items.indexWhere((n) => n['id'] == item['id']);
        if (idx >= 0) _items[idx] = {..._items[idx], 'dibaca': true};
        if (_unread > 0) _unread--;
      });
      if (id != null) {
        // Kegagalan menandai dibaca tidak menghalangi user membuka laporan.
        unawaited(NotifikasiService.markAsRead(id));
      }
    }

    final laporanId = _extractLaporanId(item);
    if (laporanId == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LaporanDetailPage(laporanId: laporanId),
      ),
    );
    if (mounted) _load();
  }

  /// Prioritas: kolom `laporan_id` dari API (data tersimpan di tabel notifikasi).
  /// Fallback regex hanya untuk baris notifikasi lama yang dibuat sebelum kolom
  /// itu ada: "#12" atau "laporan 12". Bila tidak ketemu, kartu tetap bisa
  /// dibaca tapi tidak membuka detail.
  int? _extractLaporanId(Map<String, dynamic> item) {
    for (final key in const ['laporan_id', 'ref_id']) {
      final value = item[key];
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }

    final text = '${item['judul'] ?? ''} ${item['pesan'] ?? ''}';
    final match = RegExp(r'#(\d+)').firstMatch(text) ??
        RegExp(r'laporan\s+(\d+)', caseSensitive: false).firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1) ?? '');
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 4,
        title: Row(
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            if (_unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text(
                'Baca semua',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _items.isEmpty
                  ? _buildEmpty()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildItem(_items[i]),
                      ),
                    ),
    );
  }

  Widget _buildItem(Map<String, dynamic> n) {
    final isRead = n['dibaca'] == true;
    final judul = (n['judul'] ?? 'Notifikasi').toString();
    final pesan = (n['pesan'] ?? '').toString();
    final waktu = (n['created_at'] ?? '').toString();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openItem(n),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isRead
                ? Colors.white
                : AppColors.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: isRead
                ? Border.all(color: Colors.black.withValues(alpha: 0.05), width: 1)
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _iconFor(judul, isRead),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isRead ? FontWeight.w600 : FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (pesan.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        pesan,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatTimestamp(waktu),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFor(String judul, bool isRead) {
    final lower = judul.toLowerCase();
    final IconData icon;
    if (lower.contains('selesai') ||
        lower.contains('tuntas') ||
        lower.contains('disetujui')) {
      icon = Icons.check_circle_rounded;
    } else if (lower.contains('tolak') || lower.contains('revisi')) {
      icon = Icons.error_outline_rounded;
    } else if (lower.contains('tugas') || lower.contains('dikerjakan')) {
      icon = Icons.construction_rounded;
    } else {
      icon = Icons.notifications_active_rounded;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isRead
            ? AppColors.background
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 19,
        color: isRead ? AppColors.textSecondary : AppColors.primary,
      ),
    );
  }

  String _formatTimestamp(String ts) {
    if (ts.isEmpty) return '-';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'Baru saja';
      if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
      if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
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
