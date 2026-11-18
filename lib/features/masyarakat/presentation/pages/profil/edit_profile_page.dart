import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/auth/data/auth_service.dart';

/// Halaman edit profil masyarakat.
///
/// Menampilkan foto profil (dapat diubah lewat galeri/kamera),
/// data yang dapat diubah (nama, nomor HP, alamat, jenis kelamin, tanggal lahir),
/// serta data yang tidak dapat diubah (email).
///
/// Mengembalikan `true` lewat [Navigator.pop] bila profil berhasil diperbarui,
/// sehingga halaman pemanggil dapat memuat ulang datanya.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _picker = ImagePicker();

  String _email = '';
  String _gender = 'Laki-laki';
  DateTime? _birthDate;

  /// URL foto profil aktif. `null` → tampilkan avatar inisial.
  String? _photoUrl;

  /// Foto baru yang dipilih tapi belum diunggah (preview lokal sebelum simpan).
  Uint8List? _pendingPhotoBytes;
  String? _pendingPhotoName;

  bool _photoBusy = false;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = await StorageService.getUser();
    if (!mounted) return;
    setState(() {
      _applyUser(user);
      _loading = false;
    });
    // Coba sinkronkan dengan server agar data terbaru yang tampil.
    try {
      final synced = await AuthService.syncUser();
      if (mounted && synced != null) {
        setState(() => _applyUser(synced));
      }
    } catch (_) {}
  }

  void _applyUser(Map<String, dynamic>? user) {
    if (user == null) return;
    _nameController.text = user['name']?.toString() ?? '';
    _phoneController.text = user['no_hp']?.toString() ?? '';
    _addressController.text = user['address']?.toString() ?? '';
    _email = user['email']?.toString() ?? '';
    final gender = user['gender']?.toString() ?? '';
    _gender = gender == 'Perempuan' ? 'Perempuan' : 'Laki-laki';
    final birth = user['birth_date']?.toString() ?? '';
    final parsed = birth.isNotEmpty ? DateTime.tryParse(birth) : null;
    // Tolak tanggal yang mustahil (sebelum 1900 atau di masa depan) agar
    // showDatePicker tidak menerima initialDate di luar range.
    if (parsed == null) {
      _birthDate = null;
    } else {
      final now = DateTime.now();
      final last = DateTime(now.year, now.month, now.day);
      _birthDate = parsed.isBefore(DateTime(1900)) || parsed.isAfter(last)
          ? null
          : parsed;
    }
    // Foto profil: utamakan URL absolut dari server. Bila hanya path
    // (`profil/xxx.jpg`), bentuk URL lewat base aktif (lihat _resolvePhoto).
    final photo = user['foto_profil_url']?.toString();
    if (photo != null && photo.isNotEmpty) {
      _photoUrl = photo;
    } else {
      final path = user['foto_profil']?.toString();
      _photoUrl = (path == null || path.isEmpty) ? null : path;
    }
  }

  // ─── Foto profil ───────────────────────────────────────────────────────────

  /// Dialog pilihan sumber foto: galeri atau kamera.
  Future<void> _showPhotoSourceSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ubah Foto Profil',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.primary,
              ),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            if (_photoUrl != null || _pendingPhotoBytes != null)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Hapus Foto',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deletePhoto();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source != null) await _pickPhoto(source);
  }

  /// Ambil gambar dari galeri/kamera lalu jadikan preview (belum diunggah).
  Future<void> _pickPhoto(ImageSource source) async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pendingPhotoBytes = bytes;
        _pendingPhotoName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('camera_access_denied')
          ? 'Izin kamera ditolak. Aktifkan izin kamera di pengaturan aplikasi.'
          : e.toString().contains('photo_access_denied')
          ? 'Izin galeri ditolak. Aktifkan izin penyimpanan di pengaturan aplikasi.'
          : 'Gagal mengambil foto. Silakan coba lagi.';
      _showSnack(message, isError: true);
    } finally {
      if (mounted) setState(() => _photoBusy = false);
    }
  }

  /// Unggah foto yang dipilih ke server. Tidak menutup halaman.
  Future<bool> _uploadPendingPhoto() async {
    final bytes = _pendingPhotoBytes;
    if (bytes == null) return true;

    final res = await AuthService.uploadProfilePhoto(
      bytes: bytes,
      fileName: _pendingPhotoName ?? 'foto_profil.jpg',
    );
    if (!mounted) return false;

    if (res['success'] == true) {
      final synced = await StorageService.getUser();
      if (!mounted) return true;
      setState(() {
        _pendingPhotoBytes = null;
        _pendingPhotoName = null;
        _applyUser(synced);
      });
      return true;
    }
    _showSnack(
      res['message']?.toString() ?? 'Gagal mengunggah foto profil',
      isError: true,
    );
    return false;
  }

  /// Hapus foto profil di server.
  Future<void> _deletePhoto() async {
    if (_photoBusy) return;
    setState(() => _photoBusy = true);
    final res = await AuthService.deleteProfilePhoto();
    if (!mounted) return;

    if (res['success'] == true) {
      final synced = await StorageService.getUser();
      if (!mounted) return;
      setState(() {
        _pendingPhotoBytes = null;
        _pendingPhotoName = null;
        _applyUser(synced);
        _photoUrl = null;
      });
      _showSnack('Foto profil berhasil dihapus', isError: false);
    } else {
      _showSnack(
        res['message']?.toString() ?? 'Gagal menghapus foto profil',
        isError: true,
      );
    }
    if (mounted) setState(() => _photoBusy = false);
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    // Jaga agar initialDate selalu di dalam rentang [firstDate, lastDate].
    // Tanpa clamp, tanggal lahir dari server yang kosong/rusak/masa depan
    // memicu assertion showDatePicker dan aplikasi crash.
    final first = DateTime(1900);
    final last = DateTime(now.year, now.month, now.day);
    var initial = _birthDate ?? DateTime(2000);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Pilih Tanggal Lahir',
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  /// Format tanggal lahir dengan nama bulan Indonesia.
  ///
  /// Locale `id_ID` diinisialisasi di `main()` lewat `initializeDateFormatting`.
  /// Bila karena satu dan lain hal data locale belum siap, jatuh ke format
  /// numerik agar halaman tidak melempar `LocaleDataException`.
  String _formatBirthDate(DateTime date) {
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _saving = true);

    // Foto diunggah lebih dulu supaya bila gagal, data teks tidak setengah tersimpan.
    final photoOk = await _uploadPendingPhoto();
    if (!mounted) return;
    if (!photoOk) {
      setState(() => _saving = false);
      return;
    }

    final res = await AuthService.updateProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      gender: _gender,
      birthDate: _birthDate != null
          ? DateFormat('yyyy-MM-dd').format(_birthDate!)
          : null,
    );
    if (!mounted) return;

    setState(() => _saving = false);
    if (res['success'] == true) {
      _showSnack(
        res['message']?.toString() ?? 'Profil berhasil diperbarui',
        isError: false,
      );
      Navigator.pop(context, true);
    } else {
      _showSnack(
        res['message']?.toString() ?? 'Gagal memperbarui profil',
        isError: true,
      );
    }
  }

  void _showSnack(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatarSection(),
                    const SizedBox(height: 28),
                    _sectionTitle('Informasi Pribadi'),
                    const SizedBox(height: 12),
                    _buildField(
                      label: 'Nama Lengkap',
                      controller: _nameController,
                      hint: 'Masukkan nama lengkap Anda',
                      icon: Icons.person_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        if (value.trim().length < 3) {
                          return 'Nama minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Nomor HP',
                      controller: _phoneController,
                      hint: 'Contoh: 08123456789',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return null;
                        if (!RegExp(r'^[0-9+\-\s]{8,16}$').hasMatch(text)) {
                          return 'Nomor HP tidak valid (8–16 digit)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      label: 'Alamat Lengkap',
                      controller: _addressController,
                      hint: 'Masukkan alamat tempat tinggal',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    _buildGenderField(),
                    const SizedBox(height: 16),
                    _buildBirthDateField(),
                    const SizedBox(height: 28),
                    _sectionTitle('Informasi Akun'),
                    const SizedBox(height: 12),
                    _buildReadOnlyField(
                      label: 'Email',
                      value: _email.isEmpty ? 'Belum tersedia' : _email,
                      icon: Icons.mail_outline,
                      note: 'Email tidak dapat diubah. Hubungi kami jika perlu mengganti email.',
                    ),
                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
    );
  }

  /// Avatar besar (responsif) dengan tombol kamera untuk memilih foto.
  Widget _buildAvatarSection() {
    final name = _nameController.text.trim();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Skala avatar mengikuti lebar layar: HP kecil tidak ketarik, tablet tidak kekecilan.
    final radius = (screenWidth * 0.125).clamp(38.0, 60.0).toDouble();
    final badgeSize = (radius * 0.62).clamp(26.0, 34.0).toDouble();
    final pending = _pendingPhotoBytes;

    Widget inner;
    if (pending != null) {
      inner = Image.memory(
        pending,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
      );
    } else if (_photoUrl != null) {
      inner = Image.network(
        _photoUrl!,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _initialAvatar(radius, initial),
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _initialAvatar(radius, initial),
      );
    } else {
      inner = _initialAvatar(radius, initial);
    }

    return Center(
      child: Column(
        children: [
          SizedBox(
            width: radius * 2 + 8,
            height: radius * 2 + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _photoBusy ? null : _showPhotoSourceSheet,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: AppColors.accentPink,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(child: SizedBox.expand(child: inner)),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _photoBusy ? null : _showPhotoSourceSheet,
                    child: Container(
                      width: badgeSize,
                      height: badgeSize,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: _photoBusy
                          ? const Padding(
                              padding: EdgeInsets.all(6),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              Icons.camera_alt_rounded,
                              size: badgeSize * 0.5,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              name.isEmpty ? 'Pengguna' : name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _photoBusy ? null : _showPhotoSourceSheet,
            icon: const Icon(Icons.photo_camera_outlined, size: 16),
            label: Text(
              pending != null
                  ? 'Foto dipilih — tekan Simpan'
                  : 'Ubah foto profil',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar(double radius, String initial) {
    return Container(
      color: AppColors.accentPink,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.72,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: label == 'Nama Lengkap' ? (_) => setState(() {}) : null,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
      prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Jenis Kelamin'),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _gender,
          decoration: _inputDecoration(
            hint: 'Pilih jenis kelamin',
            icon: Icons.wc_outlined,
          ),
          borderRadius: BorderRadius.circular(14),
          items: const [
            DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki')),
            DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _gender = value);
          },
        ),
      ],
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Tanggal Lahir'),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _pickBirthDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Text(
                  _birthDate == null
                      ? 'Pilih tanggal lahir'
                      : _formatBirthDate(_birthDate!),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _birthDate == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.expand_more, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required String note,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          note,
          style: const TextStyle(
            fontSize: 11.5,
            height: 1.4,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Simpan Perubahan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
