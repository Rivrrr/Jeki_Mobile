import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/home/data/laporan_service.dart';

class CreateLaporanPage extends StatefulWidget {
  const CreateLaporanPage({super.key});

  @override
  State<CreateLaporanPage> createState() => _CreateLaporanPageState();
}

class _CreateLaporanPageState extends State<CreateLaporanPage>
    with SingleTickerProviderStateMixin {
  // ── Stepper ─────────────────────────────────────────────────────────────────
  int _currentStep = 0;
  final PageController _pageCtrl = PageController();

  // ── Form Data ────────────────────────────────────────────────────────────────
  final _judulCtrl    = TextEditingController();
  final _deskCtrl     = TextEditingController();
  final _lokasiCtrl   = TextEditingController();

  int? _selectedKategoriId;
  String? _selectedKategoriNama;
  int? _selectedKecamatanId;
  String? _selectedKecamatanNama;

  List<Map<String, dynamic>> _kategoriList  = [];
  List<Map<String, dynamic>> _kecamatanList = [];
  bool _loadingRef = true;

  final List<XFile> _selectedPhotos = [];
  final ImagePicker _picker   = ImagePicker();

  bool _submitting = false;

  // ── Form Keys ────────────────────────────────────────────────────────────────
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadReferensi();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskCtrl.dispose();
    _lokasiCtrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadReferensi() async {
    final kRes = await LaporanService.fetchKategori();
    final wRes = await LaporanService.fetchKecamatan();
    if (!mounted) return;
    setState(() {
      if (kRes['success'] == true) {
        _kategoriList = List<Map<String, dynamic>>.from(kRes['data'] ?? []);
      }
      if (wRes['success'] == true) {
        _kecamatanList = List<Map<String, dynamic>>.from(wRes['data'] ?? []);
      }
      _loadingRef = false;
    });
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageCtrl.animateToPage(
      step,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickPhoto() async {
    if (_selectedPhotos.length >= 3) {
      _showSnack('Maksimal 3 foto dapat diunggah.', isError: true);
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (picked != null && mounted) {
      setState(() => _selectedPhotos.add(picked));
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 3) {
      _showSnack('Maksimal 3 foto dapat diunggah.', isError: true);
      return;
    }
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (picked != null && mounted) {
      setState(() => _selectedPhotos.add(picked));
    }
  }

  void _removePhoto(int index) {
    setState(() => _selectedPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final result = await LaporanService.createLaporan(
        judul:        _judulCtrl.text.trim(),
        kategoriId:   _selectedKategoriId!,
        kecamatanId:  _selectedKecamatanId!,
        deskripsi:    _deskCtrl.text.trim().isEmpty ? null : _deskCtrl.text.trim(),
        lokasi:       _lokasiCtrl.text.trim().isEmpty ? null : _lokasiCtrl.text.trim(),
        foto:         _selectedPhotos.isEmpty ? null : _selectedPhotos,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        final nomor = result['data']?['nomor'] ?? '-';
        _showSuccessDialog(nomor);
      } else {
        final errors = result['errors'] as Map?;
        String msg = result['message'] ?? 'Terjadi kesalahan.';
        if (errors != null && errors.isNotEmpty) {
          final first = (errors.values.first as List).first as String;
          msg = first;
        }
        _showSnack(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showSuccessDialog(String nomor) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 44),
              ),
              const SizedBox(height: 20),
              const Text(
                'Laporan Terkirim!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              Text(
                'Laporan Anda berhasil dikirim dengan nomor:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentPink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  nomor,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tim kami akan segera meninjau laporan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                    ..pop()
                    ..pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'Buat Laporan',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: _loadingRef
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Progress Bar
                _buildProgressBar(),
                Expanded(
                  child: PageView(
                    controller: _pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),
                // Bottom Nav Buttons
                _buildBottomNav(),
              ],
            ),
    );
  }

  Widget _buildProgressBar() {
    final steps = ['Informasi', 'Lokasi', 'Foto'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length, (i) {
              final active   = i == _currentStep;
              final completed = i < _currentStep;
              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: completed
                                      ? AppColors.success
                                      : active
                                          ? AppColors.primary
                                          : AppColors.border,
                                ),
                                child: Icon(
                                  completed ? Icons.check_rounded : Icons.circle,
                                  size: completed ? 18 : 10,
                                  color: (active || completed) ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                steps[i],
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: active ? FontWeight.bold : FontWeight.w500,
                                  color: active ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (i < steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 0),
                          decoration: BoxDecoration(
                            color: i < _currentStep ? AppColors.success : AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Step 1: Informasi Laporan ──────────────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Kategori Laporan', isRequired: true),
            const SizedBox(height: 8),
            _buildKategoriGrid(),
            const SizedBox(height: 20),
            _sectionLabel('Judul Laporan', isRequired: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _judulCtrl,
              maxLength: 100,
              decoration: _inputDeco(
                hint: 'Contoh: Jalan berlubang di Jl. Hayam Wuruk',
                icon: Icons.edit_note_rounded,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Judul wajib diisi.';
                if (v.trim().length < 5) return 'Judul minimal 5 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _sectionLabel('Deskripsi (Opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _deskCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: _inputDeco(
                hint: 'Jelaskan masalah secara detail: ukuran kerusakan, kondisi, bahaya, dll.',
                icon: Icons.description_outlined,
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildKategoriGrid() {
    if (_kategoriList.isEmpty) {
      return const Center(child: Text('Tidak ada kategori tersedia.'));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kategoriList.map((k) {
        final isSelected = _selectedKategoriId == k['id'];
        return GestureDetector(
          onTap: () => setState(() {
            _selectedKategoriId   = k['id'];
            _selectedKategoriNama = k['nama'];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: isSelected
                  ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _kategoriIcon(k['nama'] ?? ''),
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  k['nama'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Step 2: Lokasi ──────────────────────────────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Kecamatan', isRequired: true),
            const SizedBox(height: 8),
            _buildKecamatanDropdown(),
            const SizedBox(height: 20),
            _sectionLabel('Alamat / Titik Lokasi (Opsional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lokasiCtrl,
              maxLength: 200,
              decoration: _inputDeco(
                hint: 'Contoh: Depan SPBU, RT.03/RW.05, Gang Melati',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF1976D2), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Semakin detail lokasi yang Anda berikan, semakin cepat laporan dapat ditangani.',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildKecamatanDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedKecamatanId,
      decoration: _inputDeco(hint: 'Pilih kecamatan...', icon: Icons.map_outlined),
      items: _kecamatanList.map((k) {
        return DropdownMenuItem<int>(
          value: k['id'],
          child: Text(k['nama'] ?? '', style: const TextStyle(fontSize: 14)),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        final item = _kecamatanList.firstWhere((k) => k['id'] == val);
        setState(() {
          _selectedKecamatanId   = val;
          _selectedKecamatanNama = item['nama'];
        });
      },
      validator: (v) => v == null ? 'Kecamatan wajib dipilih.' : null,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
    );
  }

  // ── Step 3: Foto ──────────────────────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Foto Dokumentasi (Opsional)'),
          const SizedBox(height: 4),
          Text(
            'Tambahkan foto untuk mempercepat proses verifikasi (maks. 3 foto).',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          // Tombol tambah foto
          if (_selectedPhotos.length < 3)
            Row(
              children: [
                Expanded(
                  child: _photoSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Dari Galeri',
                    onTap: _pickPhoto,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _photoSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Ambil Foto',
                    onTap: _takePhoto,
                    color: const Color(0xFF0288D1),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Grid foto terpilih
          if (_selectedPhotos.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1,
              ),
              itemCount: _selectedPhotos.length,
              itemBuilder: (_, i) => Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(_selectedPhotos[i].path),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Summary sebelum submit
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ringkasan Laporan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Divider(height: 20),
                _summaryRow('Kategori', _selectedKategoriNama ?? '-'),
                _summaryRow('Judul', _judulCtrl.text.trim().isEmpty ? '-' : _judulCtrl.text.trim()),
                _summaryRow('Kecamatan', _selectedKecamatanNama ?? '-'),
                _summaryRow('Lokasi', _lokasiCtrl.text.trim().isEmpty ? '(tidak diisi)' : _lokasiCtrl.text.trim()),
                _summaryRow('Foto', '${_selectedPhotos.length} foto'),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _photoSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const Text('  :  ', style: TextStyle(color: AppColors.textMuted)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation Buttons ─────────────────────────────────────────────
  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            TextButton.icon(
              onPressed: () => _goToStep(_currentStep - 1),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
              label: const Text('Kembali'),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          const Spacer(),
          if (_currentStep < 2)
            ElevatedButton(
              onPressed: () {
                if (_currentStep == 0) {
                  if (_selectedKategoriId == null) {
                    _showSnack('Silakan pilih kategori laporan.', isError: true);
                    return;
                  }
                  if (!(_step1Key.currentState?.validate() ?? false)) return;
                  _goToStep(1);
                } else if (_currentStep == 1) {
                  if (_selectedKecamatanId == null) {
                    _showSnack('Silakan pilih kecamatan.', isError: true);
                    return;
                  }
                  _goToStep(2);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Lanjut', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_ios_rounded, size: 14),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.send_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Kirim Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
      prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  IconData _kategoriIcon(String nama) {
    final n = nama.toLowerCase();
    if (n.contains('jalan')) return Icons.add_road;
    if (n.contains('drainase') || n.contains('saluran')) return Icons.water;
    if (n.contains('lampu') || n.contains('listrik')) return Icons.lightbulb_outline;
    if (n.contains('jembatan')) return Icons.architecture;
    if (n.contains('sampah') || n.contains('kebersihan')) return Icons.delete_outline;
    if (n.contains('air') || n.contains('banjir')) return Icons.water_drop_outlined;
    return Icons.report_problem_outlined;
  }
}
