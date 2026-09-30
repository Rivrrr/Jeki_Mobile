import 'package:flutter/material.dart';
import 'package:infrast/core/constants/api_constants.dart';
import 'package:infrast/core/constants/app_colors.dart';
import 'package:infrast/core/services/storage_service.dart';
import 'package:infrast/features/auth/data/auth_service.dart';

enum DialogType { error, warning, info, success }

class UserFriendlyDialog {
  UserFriendlyDialog._();

  /// Menampilkan Pop-up Dialog yang ramah dan mudah dimengerti orang awam.
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    DialogType type = DialogType.error,
    List<String>? solutionSteps,
    String primaryButtonText = 'Mengerti',
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    Color headerColor;
    IconData headerIcon;

    switch (type) {
      case DialogType.error:
        headerColor = AppColors.error;
        headerIcon = Icons.error_outline_rounded;
        break;
      case DialogType.warning:
        headerColor = AppColors.warning;
        headerIcon = Icons.warning_amber_rounded;
        break;
      case DialogType.info:
        headerColor = Colors.blue.shade600;
        headerIcon = Icons.info_outline_rounded;
        break;
      case DialogType.success:
        headerColor = AppColors.success;
        headerIcon = Icons.check_circle_outline_rounded;
        break;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          backgroundColor: AppColors.cardSurface,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Icon Header Lingkaran
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: headerColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(headerIcon, color: headerColor, size: 36),
                ),
                const SizedBox(height: 18),

                // Judul
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                // Pesan Penjelasan
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),

                // Langkah Solusi (Jika Ada)
                if (solutionSteps != null && solutionSteps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lightbulb_outline_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 6),
                            Text(
                              'Panduan Langkah:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...solutionSteps.map((step) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                              Expanded(
                                child: Text(
                                  step,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Tombol Aksi
                Row(
                  children: [
                    if (secondaryButtonText != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            onSecondaryPressed?.call();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            side: BorderSide(color: AppColors.border),
                          ),
                          child: Text(
                            secondaryButtonText,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onPrimaryPressed?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: headerColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: Text(
                          primaryButtonText,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  /// Modal Pengaturan Server URL dengan Uji Koneksi Langsung
  static Future<void> showServerConfigModal(
    BuildContext context, {
    VoidCallback? onSaved,
  }) async {
    final currentUrl = await ApiConstants.getActiveBaseUrl();
    final urlController = TextEditingController(text: currentUrl);

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return _ServerConfigSheet(
          initialUrl: currentUrl,
          controller: urlController,
          onSaved: onSaved,
        );
      },
    );
  }
}

class _ServerConfigSheet extends StatefulWidget {
  final String initialUrl;
  final TextEditingController controller;
  final VoidCallback? onSaved;

  const _ServerConfigSheet({
    required this.initialUrl,
    required this.controller,
    this.onSaved,
  });

  @override
  State<_ServerConfigSheet> createState() => _ServerConfigSheetState();
}

class _ServerConfigSheetState extends State<_ServerConfigSheet> {
  bool _isTesting = false;
  String? _testMessage;
  bool? _isTestSuccess;

  void _testConnection(String url) async {
    setState(() {
      _isTesting = true;
      _testMessage = null;
      _isTestSuccess = null;
    });

    try {
      final res = await AuthService.checkHealth(url.trim());
      if (res['success'] == true) {
        setState(() {
          _isTestSuccess = true;
          _testMessage = 'Terhubung! Server Laravel backend aktif.';
        });
      } else {
        setState(() {
          _isTestSuccess = false;
          _testMessage = res['message'] ?? 'Tidak dapat menjangkau server.';
        });
      }
    } catch (e) {
      setState(() {
        _isTestSuccess = false;
        _testMessage = 'Gagal menghubungi: ${e.toString()}';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  void _applyPreset(String url) {
    widget.controller.text = url;
    _testConnection(url);
  }

  void _saveUrl() async {
    final newUrl = widget.controller.text.trim();
    if (newUrl.isEmpty) return;

    await StorageService.saveBaseUrl(newUrl);
    ApiConstants.resetCache();
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSaved?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alamat server disimpan: $newUrl'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetToDefault() async {
    await StorageService.clearBaseUrl();
    ApiConstants.resetCache();
    final defaultUrl = ApiConstants.defaultBaseUrl;
    widget.controller.text = defaultUrl;
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onSaved?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alamat server direset ke default: $defaultUrl'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.dns_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Pengaturan Server Backend',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesuaikan alamat backend Laravel agar aplikasi dapat terhubung:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),

            // Presets Cepat
            const Text(
              'Pilih Lingkungan Cepat:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.wifi_rounded, size: 16),
                  label: const Text('HP Fisik / Wi-Fi (192.168.1.13:8000)', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.background,
                  onPressed: () => _applyPreset('http://192.168.1.13:8000/api'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.phone_android_rounded, size: 16),
                  label: const Text('Android Emulator (10.0.2.2:8000)', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.background,
                  onPressed: () => _applyPreset('http://10.0.2.2:8000/api'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.laptop_chromebook_rounded, size: 16),
                  label: const Text('Komputer / Desktop (127.0.0.1:8000)', style: TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.background,
                  onPressed: () => _applyPreset('http://127.0.0.1:8000/api'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input Field
            TextField(
              controller: widget.controller,
              decoration: InputDecoration(
                labelText: 'URL API Backend',
                hintText: 'http://127.0.0.1:8000/api',
                prefixIcon: const Icon(Icons.link_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Uji Koneksi',
                  icon: _isTesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check_rounded, color: AppColors.primary),
                  onPressed: _isTesting ? null : () => _testConnection(widget.controller.text),
                ),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),

            if (_testMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (_isTestSuccess == true ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (_isTestSuccess == true ? AppColors.success : AppColors.error).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isTestSuccess == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      size: 16,
                      color: _isTestSuccess == true ? AppColors.success : AppColors.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isTestSuccess == true ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Tombol Simpan & Reset
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetToDefault,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Reset Bawaan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveUrl,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Simpan & Pakai'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
