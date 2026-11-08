import 'package:flutter/material.dart';
import 'package:infrast/core/utils/foto_helper.dart';

class StepKonfirmasi extends StatelessWidget {
  final String reportId;
  final String? kategori;
  final String? kecamatan;
  final String alamat;
  final List<PhotoItem> photos;
  final String deskripsi;
  final double? latitude;
  final double? longitude;
  final bool isAgreed;
  final ValueChanged<bool?> onAgreeChanged;
  final VoidCallback onEditKategori;
  final VoidCallback onEditLokasi;
  final VoidCallback onEditFoto;
  final VoidCallback onEditDeskripsi;

  const StepKonfirmasi({
    super.key,
    required this.reportId,
    required this.kategori,
    this.kecamatan,
    required this.alamat,
    required this.photos,
    required this.deskripsi,
    this.latitude,
    this.longitude,
    required this.isAgreed,
    required this.onAgreeChanged,
    required this.onEditKategori,
    required this.onEditLokasi,
    required this.onEditFoto,
    required this.onEditDeskripsi,
  });

  @override
  Widget build(BuildContext context) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final now = DateTime.now();
    final dateStr = '${now.day} ${months[now.month]} ${now.year}';
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pastikan semua informasi sudah benar sebelum dikirim',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          
          // Summary Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  label: 'KATEGORI',
                  value: kategori ?? '-',
                  icon: _getKategoriIcon(kategori),
                  onEdit: onEditKategori,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildSummaryRow(
                  label: 'WILAYAH KECAMATAN',
                  value: kecamatan != null ? 'Kec. $kecamatan' : '-',
                  icon: '📍',
                  onEdit: onEditLokasi,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildSummaryRow(
                  label: 'ALAMAT LOKASI',
                  value: alamat.isEmpty ? '-' : alamat,
                  onEdit: onEditLokasi,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildSummaryRow(
                  label: 'KOORDINAT GPS LOKASI',
                  value: '',
                  customValueWidget: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.my_location, size: 16, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            latitude != null && longitude != null
                                ? '$latitude, $longitude'
                                : 'Terkunci otomatis dari foto',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Auto-tag GPS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  onEdit: onEditFoto,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildSummaryRow(
                  label: 'FOTO BUKTI',
                  value: '',
                  customValueWidget: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: photos.map((p) {
                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            p.bytes,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  onEdit: onEditFoto,
                ),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                _buildSummaryRow(
                  label: 'DESKRIPSI',
                  value: deskripsi.isEmpty ? '-' : deskripsi,
                  onEdit: onEditDeskripsi,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Report ID Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_outlined, color: Color(0xFFE91E63), size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor Laporan (akan dibuat)',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reportId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Agreement Checkbox
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: isAgreed,
                  onChanged: onAgreeChanged,
                  activeColor: const Color(0xFFE91E63),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Saya menyatakan bahwa laporan ini benar dan dapat dipertanggungjawabkan sesuai peraturan Kabupaten Jember. Laporan palsu dapat dikenakan sanksi.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildSummaryRow({
    required String label,
    required String value,
    String? icon,
    Widget? customValueWidget,
    required VoidCallback onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                if (customValueWidget != null)
                  customValueWidget
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Text(icon, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Ubah',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE91E63),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getKategoriIcon(String? kategori) {
    if (kategori == null) return '📄';
    final lower = kategori.toLowerCase();
    if (lower.contains('jalan')) return '🛣️';
    if (lower.contains('jembatan')) return '🌉';
    if (lower.contains('lampu')) return '💡';
    if (lower.contains('drainase') || lower.contains('saluran')) return '🌊';
    if (lower.contains('fasilitas')) return '🏛️';
    return '📄';
  }
}
