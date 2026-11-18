import 'package:flutter/material.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/features/masyarakat/presentation/widgets/info_highlight_card.dart';
import 'package:infrast/features/auth/data/auth_service.dart';

/// Halaman keamanan akun: ubah kata sandi.
///
/// Menyimpan kata sandi baru lewat [AuthService.changePassword] yang memanggil
/// endpoint `me/change-password` pada backend Laravel.
class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);
    try {
      final res = await AuthService.changePassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );

      if (!mounted) return;
      if (res['success'] == true) {
        _showSnack(
          res['message']?.toString() ?? 'Kata sandi berhasil diperbarui',
          isError: false,
        );
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      } else {
        _showSnack(
          res['message']?.toString() ?? 'Gagal mengubah kata sandi',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          'Keamanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHero(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPasswordField(
                            controller: _currentPasswordController,
                            label: 'Kata Sandi Saat Ini',
                            hint: 'Masukkan kata sandi lama',
                            icon: Icons.lock_outline,
                            obscure: _obscureCurrent,
                            onToggle: () => setState(
                              () => _obscureCurrent = !_obscureCurrent,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Kata sandi saat ini wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildPasswordField(
                            controller: _newPasswordController,
                            label: 'Kata Sandi Baru',
                            hint: 'Minimal 8 karakter',
                            icon: Icons.password_rounded,
                            obscure: _obscureNew,
                            onToggle: () =>
                                setState(() => _obscureNew = !_obscureNew),
                            validator: (value) {
                              final text = value?.trim() ?? '';
                              if (text.isEmpty) {
                                return 'Kata sandi baru wajib diisi';
                              }
                              if (text.length < 8) {
                                return 'Kata sandi minimal 8 karakter';
                              }
                              if (text ==
                                  _currentPasswordController.text.trim()) {
                                return 'Kata sandi baru harus berbeda dari yang lama';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildPasswordField(
                            controller: _confirmPasswordController,
                            label: 'Konfirmasi Kata Sandi Baru',
                            hint: 'Ulangi kata sandi baru',
                            icon: Icons.verified_user_outlined,
                            obscure: _obscureConfirm,
                            onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Konfirmasi kata sandi wajib diisi';
                              }
                              if (value.trim() !=
                                  _newPasswordController.text.trim()) {
                                return 'Konfirmasi kata sandi tidak cocok';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTipsCard(),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleChangePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.5,
                          ),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Perbarui Kata Sandi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Jaga Keamanan Akun Anda',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gunakan kata sandi yang kuat dan tidak dipakai pada layanan lain.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    const tips = [
      'Minimal 8 karakter, kombinasikan huruf besar, kecil, dan angka.',
      'Hindari tanggal lahir atau nomor HP sebagai kata sandi.',
      'Ganti kata sandi secara berkala dan jangan bagikan ke siapa pun.',
    ];
    return InfoHighlightCard(
      icon: Icons.lock_outline,
      title: 'Tips Kata Sandi Kuat',
      lines: tips,
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13.5,
              color: AppColors.textMuted,
            ),
            prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
            suffixIcon: IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
                color: AppColors.textMuted,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: AppColors.background,
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
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}
