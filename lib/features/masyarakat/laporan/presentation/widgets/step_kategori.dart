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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    int jalanId = 1;
    int jembatanId = 2;

    try {
      final res = await LaporanService.fetchKategori();
      if (res['success'] == true) {
        final raw = res['data']?['data'] ?? res['data'] ?? [];
        final list = List<Map<String, dynamic>>.from(raw);
        for (final item in list) {
          final nama = (item['nama'] as String? ?? '').toLowerCase();
          final id = item['id'] as int?;
          if (id != null) {
            if (nama.contains('jalan')) {
              jalanId = id;
            } else if (nama.contains('jembatan')) {
              jembatanId = id;
            }
          }
        }
      }
    } catch (_) {
      // Fallback ke ID default jika offline
    }

    if (!mounted) return;

    setState(() {
      _kategoriList = [
        {
          'id': jalanId,
          'nama': 'Jalan Berlubang atau Rusak',
          'deskripsi': 'Kerusakan aspal jalan, jalan berlubang, retakan, amblas, atau bergelombang.',
          'emoji': '🛣️',
          'iconBg': const Color(0xFFFCE4EC),
        },
        {
          'id': jembatanId,
          'nama': 'Jembatan Rusak atau Retak',
          'deskripsi': 'Kerusakan konstruksi jembatan, lantai jembatan retak/berlubang, atau pagar pengaman rusak.',
          'emoji': '🌉',
          'iconBg': const Color(0xFFE0F7FA),
        },
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE91E63)),
      );
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih jenis kerusakan infrastruktur yang ingin Anda laporkan',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ..._kategoriList.map((kat) {
            final id = kat['id'] as int;
            final nama = kat['nama'] as String;
            final deskripsi = kat['deskripsi'] as String;
            final emoji = kat['emoji'] as String;
            final iconBg = kat['iconBg'] as Color;

            final isSelected = widget.selectedKategoriId == id ||
                (widget.selectedKategoriNama != null &&
                    widget.selectedKategoriNama!.toLowerCase() == nama.toLowerCase());

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                onTap: () => widget.onSelect(id, nama),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE91E63) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFFE91E63).withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.03),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Emoji Icon Container
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: iconBg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title & Description
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nama,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? const Color(0xFFE91E63)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              deskripsi,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isSelected
                                    ? const Color(0xFFBE123C)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Selection Indicator
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? const Color(0xFFE91E63) : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFE91E63)
                                : const Color(0xFFCBD5E1),
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
