import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infrast/core/utils/foto_helper.dart';
import 'package:infrast/features/pelaksana/data/tugas_service.dart';

/// Formatter otomatis pemisah ribuan Rupiah (contoh: 7500000 -> 7.500.000)
class RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TugasDetailScreen extends StatefulWidget {
  final int tugasId;

  const TugasDetailScreen({super.key, required this.tugasId});

  @override
  State<TugasDetailScreen> createState() => _TugasDetailScreenState();
}

class _TugasDetailScreenState extends State<TugasDetailScreen> {
  Map<String, dynamic>? _tugas;
  Map<String, dynamic>? _laporan;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  static String _formatRupiah(dynamic val) {
    if (val == null) return '-';
    double number = 0;
    if (val is num) {
      number = val.toDouble();
    } else if (val is String) {
      number = double.tryParse(val) ?? 0;
    }
    final intVal = number.toInt();
    final formatted = intVal.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  static int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is num) return val.toInt();
    if (val is String) {
      return (double.tryParse(val) ?? int.tryParse(val) ?? fallback).toInt();
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    final res = await TugasService.fetchTugasDetail(widget.tugasId);
    if (!mounted) return;
    if (res['success'] == true) {
      final data = Map<String, dynamic>.from(res['data']?['data'] ?? res['data'] ?? {});
      setState(() {
        _tugas   = data;
        _laporan = Map<String, dynamic>.from(data['laporan'] ?? {});
        _loading = false;
      });
    } else {
      setState(() { _error = res['message']; _loading = false; });
    }
  }

  Future<void> _mulaiTugas() async {
    final confirm = await _confirmDialog(
      title: 'Mulai Tugas',
      msg: 'Apakah Anda yakin ingin memulai tugas ini?\nStatus akan berubah menjadi "Sedang Dikerjakan".',
      confirmText: 'Mulai',
      confirmColor: const Color(0xFF2563EB),
    );
    if (!confirm || !mounted) return;
    setState(() => _actionLoading = true);
    final res = await TugasService.mulaiTugas(widget.tugasId);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    _showSnack(res['message'] ?? '', isError: res['success'] != true);
    if (res['success'] == true) await _load();
  }

  Future<void> _kirimTinjauan() async {
    final formKey = GlobalKey<FormState>();
    final catatanCtrl = TextEditingController();
    final bahanCtrl = TextEditingController();
    final biayaCtrl = TextEditingController();
    final waktuCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.assignment_turned_in_outlined, color: Color(0xFFD97706)),
            SizedBox(width: 8),
            Text('Kirim Hasil Tinjauan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Kebutuhan Bahan & Material:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: bahanCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Misal: Batu split 2 truk, aspal instan 10 sak, semen 5 sak...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Kebutuhan bahan & material wajib diisi';
                      }
                      if (val.trim().length < 5) {
                        return 'Tuliskan kebutuhan bahan minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Estimasi Anggaran / Biaya (Rp):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: biayaCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      RupiahInputFormatter(),
                    ],
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        child: Text(
                          'Rp',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706), fontSize: 14),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      hintText: 'Misal: 7.500.000',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Estimasi biaya wajib diisi';
                      }
                      final raw = val.replaceAll(RegExp(r'[^0-9]'), '');
                      final numVal = int.tryParse(raw);
                      if (numVal == null || numVal <= 0) {
                        return 'Estimasi biaya harus berupa angka yang valid';
                      }
                      if (numVal < 10000) {
                        return 'Estimasi biaya minimal Rp 10.000';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Estimasi Waktu Pengerjaan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: waktuCtrl,
                    decoration: InputDecoration(
                      hintText: 'Misal: 3 Hari Kerja',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Estimasi waktu wajib diisi (misal: 3 Hari Kerja)';
                      }
                      if (val.trim().length < 2) {
                        return 'Tuliskan estimasi waktu pengerjaan yang jelas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  const Text('Catatan Hasil Peninjauan Lapangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: catatanCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Rekomendasi teknis kondisi kerusakan & tindak lanjut...',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Catatan hasil tinjauan wajib diisi';
                      }
                      if (val.trim().length < 5) {
                        return 'Tuliskan catatan hasil peninjauan minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Kirim ke Admin'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    final rawBiaya = biayaCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final estimasiBiaya = double.tryParse(rawBiaya);

    try {
      setState(() => _actionLoading = true);
      final res = await TugasService.kirimTinjauan(
        tugasId: widget.tugasId,
        catatan: catatanCtrl.text.trim(),
        bahanKebutuhan: bahanCtrl.text.trim(),
        estimasiBiaya: estimasiBiaya,
        estimasiWaktu: waktuCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _actionLoading = false);
      _showSnack(res['message'] ?? '', isError: res['success'] != true);
      if (res['success'] == true) await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _actionLoading = false);
      _showSnack('Terjadi kendala pengiriman: ${e.toString()}', isError: true);
    }
  }

  Future<void> _updateProgress() async {
    int persentase = _parseInt(_laporan?['persentase']) + 20;
    if (persentase > 100) persentase = 100;
    final catatanCtrl = TextEditingController();
    File? selectedFoto;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.trending_up_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text('Laporan Harian Kerja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kemajuan Fisik: $persentase%',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                const SizedBox(height: 8),
                Slider(
                  value: persentase.toDouble(),
                  min: 0, max: 100, divisions: 20,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (v) => setS(() => persentase = v.toInt()),
                ),
                const SizedBox(height: 12),
                const Text('Apa yang dikerjakan hari ini?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: catatanCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Misal: Pemadatan lapisan dasar dan penuangan aspal hotmix...',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Foto Pengerjaan Hari Ini:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                if (selectedFoto != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(selectedFoto!, height: 140, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 6, right: 6,
                        child: GestureDetector(
                          onTap: () => setS(() => selectedFoto = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                            if (img != null) {
                              setS(() => selectedFoto = File(img.path));
                            }
                          },
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Kamera', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                            if (img != null) {
                              setS(() => selectedFoto = File(img.path));
                            }
                          },
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Galeri', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Simpan Progress'),
            ),
          ],
        ),
      ),
    );
    if (result != true || !mounted) return;
    setState(() => _actionLoading = true);
    final res = await TugasService.updateProgress(
        widget.tugasId, persentase, catatanCtrl.text.trim(), foto: selectedFoto);
    if (!mounted) return;
    setState(() => _actionLoading = false);
    _showSnack(res['message'] ?? '', isError: res['success'] != true);
    if (res['success'] == true) await _load();
  }

  Future<void> _selesaikanTugas() async {
    final formKey = GlobalKey<FormState>();
    final catatanCtrl = TextEditingController();
    PhotoItem? fotoBukti;
    bool isCapturing = false;

    final kecamatanNama = (_tugas?['laporan']?['kecamatan']?['nama'] as String?) ?? 'Jember';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Laporan Penyelesaian',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pekerjaan fisik telah 100% tuntas. Lengkapi catatan dan ambil foto bukti hasil pekerjaan langsung via kamera.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),

                      // Catatan Penyelesaian (Wajib)
                      const Text(
                        'Catatan Pekerjaan Selesai *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: catatanCtrl,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Cth: Pengaspalan jalan lubang sepanjang 25 meter telah rampung dan siap dilalui warga...',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Catatan penyelesaian wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Foto Bukti Penyelesaian (Wajib Kamera)
                      const Text(
                        'Foto Bukti Pekerjaan (Wajib Kamera) *',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 6),

                      if (fotoBukti == null)
                        InkWell(
                          onTap: isCapturing
                              ? null
                              : () async {
                                  setDialogState(() => isCapturing = true);
                                  final foto = await FotoHelper.ambilFotoKamera(
                                    kecamatanNama: kecamatanNama,
                                  );
                                  setDialogState(() {
                                    fotoBukti = foto;
                                    isCapturing = false;
                                  });
                                },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                            ),
                            child: Column(
                              children: [
                                if (isCapturing)
                                  const SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF16A34A)),
                                  )
                                else
                                  const Icon(Icons.camera_alt_rounded, size: 36, color: Color(0xFF16A34A)),
                                const SizedBox(height: 8),
                                Text(
                                  isCapturing ? 'Membuka Kamera & Lokasi...' : 'Ambil Foto Kamera (Wajib)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Wajib dari kamera di lokasi kerja (otomatis rekam GPS)',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Image.memory(
                                    fotoBukti!.bytes,
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () async {
                                        setDialogState(() => isCapturing = true);
                                        final foto = await FotoHelper.ambilFotoKamera(
                                          kecamatanNama: kecamatanNama,
                                        );
                                        setDialogState(() {
                                          fotoBukti = foto;
                                          isCapturing = false;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.65),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.refresh, color: Colors.white, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'Foto Ulang',
                                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 14, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        fotoBukti!.locationLabel,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: const Text(
                                        'âœ“ Geotagged',
                                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Setelah dikirim, laporan akan diverifikasi oleh Admin Dinas terlebih dahulu sebelum diteruskan ke warga pelapor.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState?.validate() != true) return;
                  if (fotoBukti == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto bukti penyelesaian via kamera wajib diambil.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kirim Hasil Selesai (100%)', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    if (result != true || !mounted) return;
    setState(() => _actionLoading = true);

    final res = await TugasService.selesaikanTugas(
      widget.tugasId,
      catatan: catatanCtrl.text.trim(),
      fotoBytes: fotoBukti?.bytes,
      fotoName: fotoBukti?.name,
      latitude: fotoBukti?.latitude,
      longitude: fotoBukti?.longitude,
    );

    if (!mounted) return;
    setState(() => _actionLoading = false);
    _showSnack(res['message'] ?? '', isError: res['success'] != true);
    if (res['success'] == true) await _load();
  }

  Future<bool> _confirmDialog({
    required String title,
    required String msg,
    required String confirmText,
    required Color confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            content: Text(msg),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _laporan?['nomor'] ?? 'Detail Tugas',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Color(0xFFDC2626)),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : _buildContent(),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildContent() {
    final l = _laporan!;
    final status     = l['status'] as String? ?? 'ditugaskan';
    final statusLabel = l['status_label'] as String? ?? status;
    final persentase = _parseInt(l['persentase']);
    final foto       = l['foto'] as List? ?? [];
    final riwayat    = l['riwayat'] as List? ?? [];
    final (color, bg) = _statusStyle(status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: bg, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(_statusIcon(status), color: color, size: 20),
                  const SizedBox(width: 8),
                  Text(statusLabel,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color)),
                  const Spacer(),
                  if (status == 'dikerjakan')
                    Text('$persentase%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                ]),
                if (status == 'dikerjakan') ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: persentase / 100.0,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Catatan dari Admin
          if (_tugas?['catatan'] != null && (_tugas!['catatan'] as String).isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.sticky_note_2_outlined, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Instruksi dari Admin',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD97706))),
                        const SizedBox(height: 4),
                        Text(_tugas!['catatan'],
                            style: const TextStyle(fontSize: 13, color: Color(0xFF92400E), height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Laporan Info
          _sectionHeader('Detail Laporan & Penugasan'),
          const SizedBox(height: 10),
          _infoCard([
            ('No. Laporan', l['nomor'] ?? '-', Icons.tag_rounded),
            ('Jenis Tugas', (_tugas?['jenis'] == 'tinjauan' ? 'Peninjauan Lapangan' : 'Pengerjaan Perbaikan'), Icons.work_outline),
            if (_tugas?['estimasi_waktu'] != null)
              ('Target Waktu', '${_tugas!['estimasi_waktu']}', Icons.timer_outlined),
            if (_tugas?['estimasi_biaya'] != null)
              ('Estimasi Anggaran', _formatRupiah(_tugas!['estimasi_biaya']), Icons.payments_outlined),
            ('Kategori',    l['kategori'] ?? '-', Icons.category_outlined),
            ('Kecamatan',   l['kecamatan'] ?? '-', Icons.map_outlined),
            ('Lokasi',      l['lokasi'] ?? '(tidak spesifik)', Icons.location_on_outlined),
            ('Pelapor',     l['pelapor'] ?? 'Warga', Icons.person_outline),
          ]),

          // Deskripsi
          if (l['deskripsi'] != null && (l['deskripsi'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionHeader('Deskripsi Masalah'),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                l['deskripsi'],
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF334155), height: 1.5),
              ),
            ),
          ],

          // Foto
          if (foto.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Foto Laporan Warga'),
            const SizedBox(height: 10),
            SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: foto.length,
                separatorBuilder: (ctx, idx) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    foto[i]['url'],
                    width: 160, height: 160, fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      width: 160, color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.broken_image_outlined, color: Color(0xFF94A3B8)),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Log Pengerjaan Harian (Foto & Progress)
          if ((l['progress_list'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Log Pengerjaan Harian (Foto & Aktivitas)'),
            const SizedBox(height: 10),
            ...((l['progress_list'] as List).map((p) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p['persentase']}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        p['created_at'] != null ? p['created_at'].toString().split('T').first : '',
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                      ),
                    ],
                  ),
                  if (p['catatan'] != null && (p['catatan'] as String).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      p['catatan'],
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
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
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 80,
                          color: const Color(0xFFF1F5F9),
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ))),
          ],

          // Riwayat Status
          if (riwayat.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader('Riwayat Status'),
            const SizedBox(height: 10),
            _buildTimeline(riwayat),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    if (_laporan == null) return const SizedBox.shrink();
    final status = _laporan!['status'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: _actionLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : switch (status) {
              'menunggu_tinjauan' => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _kirimTinjauan,
                    icon: const Icon(Icons.assignment_turned_in_outlined),
                    label: const Text('Kirim Hasil Tinjauan Lapangan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              'tinjauan_selesai' => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, color: Color(0xFFD97706), size: 20),
                      SizedBox(width: 8),
                      Text('Hasil Tinjauan Terkirim â€” Menunggu Penugasan Admin',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF92400E), fontSize: 12)),
                    ],
                  ),
                ),
              'ditugaskan' => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _mulaiTugas,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Mulai Kerjakan Tugas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              'dikerjakan' => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _updateProgress,
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Laporan Harian', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFF2563EB)),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selesaikanTugas,
                        icon: const Icon(Icons.check_circle_outlined, size: 18),
                        label: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              'menunggu_konfirmasi_admin' => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Color(0xFFEA580C), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pekerjaan Selesai â€” Menunggu Verifikasi Admin',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC2410C), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              'menunggu_konfirmasi_masyarakat' => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF0D9488), size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Diverifikasi Admin â€” Menunggu Konfirmasi Warga (Maks 7 Hari)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F766E), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              _ => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                      SizedBox(width: 8),
                      Text('Tugas Telah Selesai Tuntas', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ),
            },
    );
  }

  Widget _buildTimeline(List riwayat) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: riwayat.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value as Map;
          final isLast = i == riwayat.length - 1;
          final (color, _) = _statusStyle(r['status_sesudah'] ?? '');
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    if (!isLast)
                      Expanded(child: Container(width: 2, color: const Color(0xFFE2E8F0))),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _capitalizeFirst(r['status_sesudah'] ?? ''),
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
                        ),
                        if (r['catatan'] != null && (r['catatan'] as String).isNotEmpty)
                          Text(r['catatan'],
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        if (r['tanggal'] != null)
                          Text(_formatDate(r['tanggal']),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final (label, value, icon) = e.value;
          final isLast = e.key == rows.length - 1;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
                const SizedBox(width: 10),
                SizedBox(
                  width: 80,
                  child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ),
                const Text('  :  ', style: TextStyle(color: Color(0xFFCBD5E1))),
                Expanded(
                  child: Text(value,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                ),
              ]),
            ),
            if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)));
  }

  (Color, Color) _statusStyle(String status) {
    return switch (status) {
      'baru'                           => (const Color(0xFFE91E63), const Color(0xFFFCE4EC)),
      'menunggu_tinjauan'              => (const Color(0xFF9333EA), const Color(0xFFFAF5FF)),
      'tinjauan_selesai'               => (const Color(0xFF4F46E5), const Color(0xFFEEF2FF)),
      'ditinjau'                       => (const Color(0xFF2196F3), const Color(0xFFE3F2FD)),
      'ditugaskan'                     => (const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      'dikerjakan'                     => (const Color(0xFFD97706), const Color(0xFFFFFBEB)),
      'menunggu_konfirmasi_admin'      => (const Color(0xFFEA580C), const Color(0xFFFFF7ED)),
      'menunggu_konfirmasi_masyarakat' => (const Color(0xFF0D9488), const Color(0xFFF0FDFA)),
      'selesai'                        => (const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      'dikonfirmasi'                   => (const Color(0xFF16A34A), const Color(0xFFF0FDF4)),
      _                                => (const Color(0xFF94A3B8), const Color(0xFFF8FAFC)),
    };
  }

  IconData _statusIcon(String status) {
    return switch (status) {
      'ditugaskan'                     => Icons.assignment_rounded,
      'dikerjakan'                     => Icons.engineering_rounded,
      'menunggu_konfirmasi_admin'      => Icons.hourglass_top_rounded,
      'menunggu_konfirmasi_masyarakat' => Icons.mark_chat_unread_rounded,
      'selesai'                        => Icons.check_circle_rounded,
      'dikonfirmasi'                   => Icons.verified_rounded,
      _                                => Icons.circle,
    };
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
}
