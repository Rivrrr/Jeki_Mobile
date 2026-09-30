import 'package:flutter/material.dart';
import 'package:infrast/core/services/laporan_service.dart';

class StepKategori extends StatefulWidget {
  final int? selectedKategoriId;
  final String? selectedKategoriNama;
  final void Function(int id, String nama) onSelect;

  const StepKategori({
    super.key,
    required this.selectedKategoriId,
    required this.selectedKategoriNama,
    required this.onSelect,
  });

  @override
  State<StepKategori> createState() => _StepKategoriState();
}

class _StepKategoriState extends State<StepKategori> {
  List<Map<String, dynamic>> _kategoriList = [];
  bool _loading = true;
  String? _error;

  // Emoji mapping berdasarkan nama kategori
  String _getEmoji(String nama) {
    final lower = nama.toLowerCase();
    if (lower.contains('jalan')) return '🛣️';
    if (lower.contains('jembatan')) return '🌉';
    if (lower.contains('lampu')) return '💡';
    if (lower.contains('drainase') || lower.contains('selokan')) return '🌊';
    if (lower.contains('fasilitas') || lower.contains('taman')) return '🏛️';
    if (lower.contains('sampah')) return '🗑️';
    if (lower.contains('air') || lower.contains('saluran')) return '💧';
    return '🔧';
  }

  static const _colors = [
    Color(0xFFFCE4EC),
    Color(0xFFF3E5F5),
    Color(0xFFFFF8E1),
    Color(0xFFE0F7FA),
    Color(0xFFE8F5E9),
    Color(0xFFE3F2FD),
    Color(0xFFFFF3E0),
    Color(0xFFF9FBE7),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await LaporanService.fetchKategori();
    if (!mounted) return;
    if (res['success'] == true) {
      final raw = res['data']?['data'] ?? res['data'] ?? [];
      setState(() {
        _kategoriList = List<Map<String, dynamic>>.from(raw);
        _loading = false;
      });
    } else {
      setState(() { _error = res['message'] ?? 'Gagal memuat kategori.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE91E63)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, color: Color(0xFFE91E63), size: 40),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE91E63), foregroundColor: Colors.white),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih kategori infrastruktur yang bermasalah',
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: _kategoriList.length,
            itemBuilder: (context, index) {
              final kat = _kategoriList[index];
              final id   = kat['id'] as int;
              final nama = kat['nama'] as String? ?? '';
              final isSelected = widget.selectedKategoriId == id;

              return GestureDetector(
                onTap: () => widget.onSelect(id, nama),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFE91E63).withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _colors[index % _colors.length],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(_getEmoji(nama), style: const TextStyle(fontSize: 24)),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          nama,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
