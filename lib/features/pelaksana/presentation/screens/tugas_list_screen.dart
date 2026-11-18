import 'package:flutter/material.dart';
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
      if (!_tabCtrl.indexIsChanging) _applyFilter(_tabs[_tabCtrl.index].$1);
    });
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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
        _applyFilter('semua');
        _loading = false;
      });
    } else {
      setState(() { _error = res['message']; _loading = false; });
    }
  }

  void _applyFilter(String status) {
    setState(() {
      if (status == 'semua') {
        _filteredList = List.from(_allTugas);
      } else if (status == 'selesai') {
        _filteredList = _allTugas
            .where((t) => ['selesai', 'dikonfirmasi',
                'menunggu_konfirmasi_admin', 'menunggu_konfirmasi_masyarakat']
                .contains(t['laporan']?['status']))
            .toList();
      } else {
        _filteredList = _allTugas
            .where((t) => t['laporan']?['status'] == status)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Daftar Tugas',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          indicatorColor: const Color(0xFF2563EB),
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2563EB),
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
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                    color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(laporan['nomor'] ?? '#',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB))),
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
                    color: Color(0xFF0F172A)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            if (t['catatan'] != null && (t['catatan'] as String).isNotEmpty)
              Text('Catatan: ${t['catatan']}',
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${laporan['kecamatan'] ?? '-'}'
                    '${laporan['lokasi'] != null ? ' · ${laporan['lokasi']}' : ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.category_outlined,
                    size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Text(laporan['kategori'] ?? '-',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
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
                        backgroundColor: const Color(0xFFE2E8F0),
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
                    backgroundColor: const Color(0xFF2563EB),
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
                  color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.assignment_outlined,
                    color: Color(0xFF2563EB), size: 36),
              ),
              const SizedBox(height: 20),
              const Text('Tidak Ada Tugas',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A))),
              const SizedBox(height: 8),
              const Text(
                'Belum ada tugas yang ditugaskan\npada filter ini.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5, color: Color(0xFF64748B), height: 1.5),
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
          const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 48),
          const SizedBox(height: 16),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
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
      'ditugaskan'   => (const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      'dikerjakan'   => (const Color(0xFFD97706), const Color(0xFFFFFBEB)),
      'selesai'      => (const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      'dikonfirmasi' => (const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      _              => (const Color(0xFF94A3B8), const Color(0xFFF8FAFC)),
    };
  }
}
