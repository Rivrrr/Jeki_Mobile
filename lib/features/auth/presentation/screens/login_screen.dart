import 'package:flutter/material.dart';
import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/constants/app_sizes.dart';
import 'package:infrast/features/auth/data/auth_service.dart';
import 'package:infrast/features/auth/presentation/screens/register_screen.dart';
import 'package:infrast/features/pelaksana/presentation/main_pelaksana_page.dart';
import 'package:infrast/features/masyarakat/presentation/pages/main_navigation_page.dart';
import 'package:infrast/presentation/widgets/animated_blob_background.dart';
import 'package:infrast/presentation/widgets/dialogs/user_friendly_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Pemanasan auto-discovery base URL di background
    ApiConstants.warmup();
  }

  // Validasi format email
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email tidak boleh kosong';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid';
    }
    return null;
  }

  // Validasi password
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kata sandi tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Kata sandi minimal 6 karakter';
    }
    return null;
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final role = result['role'] as String? ?? 'masyarakat';

      // Routing berdasarkan role
      final Widget destination = role == 'pelaksana'
          ? const MainPelaksanaPage()
          : const MainNavigation();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    } else {
      // Penanganan error ramah pengguna
      if (result['isNetworkError'] == true) {
        UserFriendlyDialog.show(
          context: context,
          type: DialogType.error,
          title: ApiConstants.userNetworkTitle,
          message: ApiConstants.userNetworkMessage,
          solutionSteps: ApiConstants.userNetworkSteps,
          primaryButtonText: 'Coba Lagi',
        );
      } else if (result['role_mismatch'] == true) {
        UserFriendlyDialog.show(
          context: context,
          type: DialogType.warning,
          title: 'Akun Tidak Dapat Masuk',
          message:
              result['message'] ??
              'Akun ini tidak dapat menggunakan aplikasi JEKI di HP.',
          solutionSteps: const [
            'Aplikasi ini digunakan oleh warga dan petugas pelaksana.',
            'Jika Anda petugas administrasi, silakan masuk melalui situs resmi JEKI.',
          ],
          primaryButtonText: 'Mengerti',
        );
      } else {
        UserFriendlyDialog.show(
          context: context,
          type: DialogType.error,
          title: 'Gagal Masuk',
          message:
              result['message'] ??
              'Email atau kata sandi yang Anda masukkan salah.',
          solutionSteps: const [
            'Pastikan email dan kata sandi sudah benar.',
            'Periksa huruf besar/kecil pada kata sandi.',
          ],
          primaryButtonText: 'Coba Lagi',
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // â”€â”€ Curved Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            ClipPath(
              clipper: CustomHeaderClipper(),
              child: Container(
                width: double.infinity,
                height: AppSizes.headerHeight(context),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: AnimatedBlobBackground(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: AppSizes.responsiveWidth(context, 66),
                            height: AppSizes.responsiveWidth(context, 66),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              color: Colors.white.withValues(alpha: 0.22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFB50060)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.home_rounded,
                              color: Colors.white,
                              size: AppSizes.responsiveWidth(context, 34),
                            ),
                          ),
                          SizedBox(
                            height: AppSizes.responsiveSpacing(context, 16),
                          ),
                          Text(
                            'Masuk Ke Akun',
                            style: TextStyle(
                              fontSize: AppSizes.responsiveWidth(context, 25),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(
                            height: AppSizes.responsiveSpacing(context, 6),
                          ),
                          Text(
                            'Masuk untuk melaporkan infrastruktur',
                            style: TextStyle(
                              fontSize: AppSizes.responsiveWidth(context, 13),
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(
                            height: AppSizes.responsiveSpacing(context, 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // â”€â”€ Floating Form Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        decoration: InputDecoration(
                          hintText: 'Alamat Email',
                          prefixIcon: const Icon(
                            Icons.mail_outline_rounded,
                            color: AppColors.textMuted,
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        decoration: InputDecoration(
                          hintText: 'Kata Sandi',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.textMuted,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.textMuted,
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.error,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                      ),

                      // â”€â”€ Quick-fill demo accounts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      const SizedBox(height: 16),
                      const Text(
                        'Isi Cepat Akun Demo:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Demo akun masyarakat
                      _quickFillChip(
                        label: 'ðŸ‘¤ Warga: masyarakat@jeki.id',
                        onTap: () {
                          _emailController.text = 'masyarakat@jeki.id';
                          _passwordController.text = 'password';
                        },
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 6),

                      // Demo akun pelaksana
                      _quickFillChip(
                        label: 'ðŸ”§ Pelaksana: budi.pelaksana@jeki.id',
                        onTap: () {
                          _emailController.text = 'budi.pelaksana@jeki.id';
                          _passwordController.text = 'password';
                        },
                        color: const Color(0xFF0369A1),
                      ),

                      const SizedBox(height: 20),

                      // â”€â”€ Tombol Login â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primary.withValues(alpha: 0.4),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                      ),

                      const SizedBox(height: 16),

                      // â”€â”€ Divider OR â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'ATAU',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.border,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // â”€â”€ Google SSO (non-fungsi) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      Tooltip(
                        message: 'Segera hadir',
                        child: OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            side: BorderSide(
                              color: AppColors.border.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Masuk dengan Google',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textMuted.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Segera',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
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
              ),
            ),

            // â”€â”€ Footer: daftar & info pelaksana â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Transform.translate(
              offset: const Offset(0, -30),
              child: Column(
                children: [
                  // Link daftar (hanya untuk masyarakat)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Belum punya akun? ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Daftar Sekarang',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Info akun pelaksana didaftarkan admin
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0369A1).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF0369A1).withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: Color(0xFF0369A1),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Akun Petugas Pelaksana hanya bisa didaftarkan oleh Administrator Dinas melalui Web Dashboard.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0C4A6E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickFillChip({
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.flash_on_rounded, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 48);

    // Smooth organic wave dipping on left and swooping across
    path.cubicTo(
      size.width * 0.28,
      size.height - 12,
      size.width * 0.65,
      size.height - 75,
      size.width,
      size.height - 42,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
