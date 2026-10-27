import 'package:flutter/material.dart';
import 'package:infrast/core/services/laporan_service.dart';
import 'package:infrast/core/utils/foto_helper.dart';
import 'package:infrast/features/laporan/presentation/screens/laporan_berhasil_screen.dart';
import '../widgets/step_kategori.dart';
import '../widgets/step_lokasi.dart';
import '../widgets/step_foto.dart';
import '../widgets/step_konfirmasi.dart';

class CreateLaporanScreen extends StatefulWidget {
  const CreateLaporanScreen({super.key});

  @override
  State<CreateLaporanScreen> createState() => _CreateLaporanScreenState();
}

class _CreateLaporanScreenState extends State<CreateLaporanScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // ── Form State ─────────────────────────────────────────────
  // Step 1: Kategori
  int? _selectedKategoriId;
  String? _selectedKategoriNama;

  // Step 2: Lokasi
  int? _selectedKecamatanId;
  String? _selectedKecamatanNama;
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  // Step 3: Foto, GPS & Deskripsi
  final List<PhotoItem> _photos = [];
  double? _latitude;
  double? _longitude;
  String? _coordinateLabel;
  final TextEditingController _deskripsiController = TextEditingController();

  // Step 4: Konfirmasi
  bool _isAgreed = false;

  // Submitting state
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _alamatController.dispose();
    _detailController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  // ── Judul otomatis dari kategori + kecamatan ───────────────
  String get _judulOtomatis {
    final kat = _selectedKategoriNama ?? 'Laporan';
    final kec = _selectedKecamatanNama != null
        ? ' - Kec. $_selectedKecamatanNama'
        : '';
    return '$kat$kec';
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (!_validateCurrentStep()) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitLaporan();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _jumpToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedKategoriId == null) {
          _showError('Pilih kategori terlebih dahulu');
          return false;
        }
        return true;
      case 1:
        if (_selectedKecamatanId == null) {
          _showError('Pilih kecamatan lokasi kerusakan');
          return false;
        }
        if (_alamatController.text.trim().isEmpty) {
          _showError('Alamat lokasi tidak boleh kosong');
          return false;
        }
        return true;
      case 2:
        if (_photos.isEmpty) {
          _showError('Tambahkan minimal 1 foto bukti kerusakan');
          return false;
        }
        if (_deskripsiController.text.trim().isEmpty) {
          _showError('Deskripsi kondisi kerusakan tidak boleh kosong');
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Menambahkan foto bukti.
  /// Karena dalam tahap pengembangan/testing dan untuk mencegah error kamera di desktop/browser/emulator,
  /// fungsi ini langsung mengisi foto sampel infrastruktur acak yang valid secara in-memory
  /// sekaligus menyematkan koordinat GPS Kabupaten Jember.
  Future<void> _addPhoto() async {
    if (_photos.length >= 3) {
      _showError('Maksimal 3 foto yang dapat diunggah');
      return;
    }

    try {
      // Pastikan koordinat GPS sudah digenerate/terkunci
      if (_latitude == null || _longitude == null) {
        final coord = FotoHelper.generateJemberCoordinate(
          kecamatanNama: _selectedKecamatanNama,
        );
        _latitude = coord['latitude'] as double;
        _longitude = coord['longitude'] as double;
        _coordinateLabel = coord['label'] as String;
      }

      // Ambil foto sampel acak berbasis bytes in-memory (100% aman untuk Web & Native)
      final photoItem = await FotoHelper.getDevSamplePhoto(
        index: _photos.length,
      );
      final label = FotoHelper.getSampleLabel(_photos.length);

      setState(() {
        _photos.add(photoItem);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '📸 Foto ${_photos.length} ditambahkan: $label [📍 $_latitude, $_longitude]',
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError('Gagal menambahkan foto: ${e.toString()}');
    }
  }

  Future<void> _submitLaporan() async {
    if (!_isAgreed) {
      _showError('Anda harus menyetujui pernyataan kebenaran laporan');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final lokasiLengkap = [
        _alamatController.text.trim(),
        _detailController.text.trim(),
      ].where((s) => s.isNotEmpty).join(' — ');

      final result = await LaporanService.createLaporan(
        kategoriId: _selectedKategoriId!,
        kecamatanId: _selectedKecamatanId!,
        judul: _judulOtomatis,
        deskripsi: _deskripsiController.text.trim(),
        lokasi: lokasiLengkap,
        latitude: _latitude,
        longitude: _longitude,
        prioritas: null, // Prioritas ditentukan oleh dinas / admin
        foto: _photos,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (result['success'] == true) {
        final nomor = _extractNomorLaporan(result);

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => LaporanBerhasilScreen(
              nomorLaporan: nomor.isNotEmpty ? nomor : '-',
            ),
          ),
        );
      } else {
        final msg = result['message'] ?? 'Gagal mengirim laporan. Coba lagi.';
        _showError(msg);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showError('Terjadi kesalahan: ${e.toString()}');
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Apa yang ingin dilaporkan?';
      case 1:
        return 'Di mana lokasinya?';
      case 2:
        return 'Foto Bukti & Deskripsi';
      case 3:
        return 'Periksa Kembali';
      default:
        return '';
    }
  }

  String _getStepSubtitle(int step) {
    switch (step) {
      case 0:
        return 'PILIH KATEGORI';
      case 1:
        return 'LOKASI';
      case 2:
        return 'BUKTI & DESKRIPSI';
      case 3:
        return 'KONFIRMASI';
      default:
        return '';
    }
  }

  String _extractNomorLaporan(Map<String, dynamic> result) {
    final payload = result['data'];
    if (payload is Map<String, dynamic>) {
      final candidates = [
        payload['nomor'],
        payload['data'] is Map ? (payload['data'] as Map)['nomor'] : null,
        payload['laporan'] is Map ? (payload['laporan'] as Map)['nomor'] : null,
      ];

      for (final candidate in candidates) {
        if (candidate != null) {
          final text = candidate.toString().trim();
          if (text.isNotEmpty) return text;
        }
      }
    }

    final rawBody = result['raw_body'];
    if (rawBody is Map<String, dynamic>) {
      final nested = rawBody['data'];
      if (nested is Map<String, dynamic>) {
        final nomor = nested['nomor']?.toString().trim();
        if (nomor != null && nomor.isNotEmpty) return nomor;
      }

      final nomor = rawBody['nomor']?.toString().trim();
      if (nomor != null && nomor.isNotEmpty) return nomor;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // ── App Bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _prevStep,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LANGKAH ${_currentStep + 1} DARI $_totalSteps — ${_getStepSubtitle(_currentStep)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE91E63),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStepTitle(_currentStep),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Progress Bar ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 8.0,
              ),
              child: _buildProgressBar(),
            ),
            const SizedBox(height: 16),

            // ── PageView ─────────────────────────────────────────
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) =>
                      setState(() => _currentStep = index),
                  children: [
                    // Step 1: Kategori
                    StepKategori(
                      selectedKategoriId: _selectedKategoriId,
                      selectedKategoriNama: _selectedKategoriNama,
                      onSelect: (id, nama) {
                        setState(() {
                          _selectedKategoriId = id;
                          _selectedKategoriNama = nama;
                        });
                      },
                    ),

                    // Step 2: Lokasi
                    StepLokasi(
                      alamatController: _alamatController,
                      detailController: _detailController,
                      selectedKecamatanId: _selectedKecamatanId,
                      selectedKecamatanNama: _selectedKecamatanNama,
                      latitude: _latitude,
                      longitude: _longitude,
                      onKecamatanSelected: (id, nama) {
                        setState(() {
                          _selectedKecamatanId = id;
                          _selectedKecamatanNama = nama;
                          if (_latitude != null && _longitude != null) {
                            _coordinateLabel = 'Kec. $nama, Kab. Jember';
                          }
                        });
                      },
                      onCoordinateChanged: (lat, lng, label) {
                        setState(() {
                          _latitude = lat;
                          _longitude = lng;
                          _coordinateLabel = label;
                        });
                      },
                    ),

                    // Step 3: Foto, GPS & Deskripsi (Digabungkan)
                    StepFoto(
                      photos: _photos,
                      onAddPhoto: _addPhoto,
                      onRemovePhoto: (index) {
                        setState(() {
                          _photos.removeAt(index);
                        });
                      },
                      deskripsiController: _deskripsiController,
                      latitude: _latitude,
                      longitude: _longitude,
                      coordinateLabel: _coordinateLabel,
                    ),

                    // Step 4: Konfirmasi
                    StepKonfirmasi(
                      kategori: _selectedKategoriNama,
                      kecamatan: _selectedKecamatanNama,
                      alamat: _alamatController.text,
                      photos: _photos,
                      deskripsi: _deskripsiController.text,
                      latitude: _latitude,
                      longitude: _longitude,
                      isAgreed: _isAgreed,
                      onAgreeChanged: (val) =>
                          setState(() => _isAgreed = val ?? false),
                      onEditKategori: () => _jumpToStep(0),
                      onEditLokasi: () => _jumpToStep(1),
                      onEditFoto: () => _jumpToStep(2),
                      onEditDeskripsi: () => _jumpToStep(2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Bottom Navigation ──────────────────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                OutlinedButton(
                  onPressed: _isSubmitting ? null : _prevStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shadowColor: const Color(0xFFE91E63).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _currentStep == _totalSteps - 1
                              ? 'Kirim Laporan'
                              : 'Lanjut',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps * 2 - 1, (index) {
        final stepIndex = index ~/ 2;
        final isLine = index % 2 != 0;
        if (isLine) {
          final isCompleted = _currentStep > stepIndex;
          return Expanded(
            child: Container(
              height: 4,
              color: isCompleted
                  ? const Color(0xFFE91E63)
                  : const Color(0xFFFCE4EC),
            ),
          );
        } else {
          final isActive = _currentStep >= stepIndex;
          return Container(
            width: isActive ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFFE91E63)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }
      }),
    );
  }
}
