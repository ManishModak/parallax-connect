import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/storage/config_storage.dart';
import '../../chat/data/chat_repository.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLocal = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingConfig() async {
    final storage = ref.read(configStorageProvider);
    if (storage.hasConfig()) {
      setState(() {
        _urlController.text = storage.getBaseUrl() ?? '';
        _isLocal = storage.getIsLocal();
        _passwordController.text = storage.getPassword() ?? '';
      });
    }
  }

  Future<void> _saveAndConnect() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isConnecting = true);

      // Check connectivity for cloud mode
      if (!_isLocal) {
        final connectivityService = ref.read(connectivityServiceProvider);
        final hasInternet = await connectivityService.hasInternetConnection;

        if (!hasInternet) {
          setState(() => _isConnecting = false);
          if (!mounted) return;
          _showErrorSnackBar(
            'No internet connection. Cloud mode requires an active internet connection.',
            LucideIcons.wifiOff,
          );
          return;
        }
      }

      // Save config temporarily for testing
      final storage = ref.read(configStorageProvider);
      await storage.saveConfig(
        baseUrl: _urlController.text.trim(),
        isLocal: _isLocal,
        password: _passwordController.text.trim().isEmpty
            ? null
            : _passwordController.text.trim(),
      );

      // Test connection
      final chatRepository = ref.read(chatRepositoryProvider);
      final isConnected = await chatRepository.testConnection();

      setState(() => _isConnecting = false);

      if (!mounted) return;

      if (isConnected) {
        _showSuccessSnackBar('Successfully connected to server!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        context.go(AppRoutes.chat);
      } else {
        _showErrorSnackBar(
          'Failed to connect to server. Please check the URL and try again.',
          LucideIcons.serverOff,
        );
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.checkCircle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Connection Setup',
          style: GoogleFonts.inter(color: AppColors.primary),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Connection Mode',
                style: GoogleFonts.inter(
                  color: AppColors.secondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              // Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLocal = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLocal
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              'Cloud (Ngrok)',
                              style: GoogleFonts.inter(
                                color: !_isLocal
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isLocal = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLocal
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Center(
                            child: Text(
                              'Local (LAN)',
                              style: GoogleFonts.inter(
                                color: _isLocal
                                    ? AppColors.primary
                                    : AppColors.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Input Field
              TextFormField(
                controller: _urlController,
                style: GoogleFonts.sourceCodePro(color: AppColors.primary),
                decoration: InputDecoration(
                  hintText: _isLocal
                      ? 'http://192.168.1.X:8000'
                      : 'https://xxxx-xx.ngrok-free.app',
                  hintStyle: GoogleFonts.sourceCodePro(color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary),
                  ),
                  prefixIcon: Icon(
                    _isLocal ? LucideIcons.wifi : LucideIcons.globe,
                    color: AppColors.secondary,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a URL';
                  }
                  if (!value.startsWith('http')) {
                    return 'URL must start with http:// or https://';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                style: GoogleFonts.inter(color: AppColors.primary),
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Password (optional)',
                  hintText: 'Leave empty if not set',
                  hintStyle: GoogleFonts.inter(color: AppColors.accent),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.secondary),
                  ),
                  prefixIcon: const Icon(
                    LucideIcons.lock,
                    color: AppColors.secondary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Instructions Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isLocal
                        ? Colors.blue.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLocal ? LucideIcons.info : LucideIcons.cloud,
                          color: _isLocal ? Colors.blue : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLocal ? 'Local Mode Setup' : 'Cloud Mode Setup',
                          style: GoogleFonts.inter(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'To connect, set up the server on your computer first.',
                      style: GoogleFonts.inter(
                        color: AppColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final url = Uri.parse(
                                'https://github.com/ManishModak/parallax-connect/blob/main/SERVER_SETUP.md',
                              );
                              try {
                                final launched = await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (!launched && mounted) {
                                  _showErrorSnackBar(
                                    'Unable to open the setup guide. Copy the URL manually.',
                                    LucideIcons.alertTriangle,
                                  );
                                }
                              } on PlatformException catch (error, stackTrace) {
                                developer.log(
                                  'Failed to launch setup guide',
                                  error: error,
                                  stackTrace: stackTrace,
                                );
                                if (!mounted) return;
                                _showErrorSnackBar(
                                  'Unable to open the setup guide. Copy the URL manually.',
                                  LucideIcons.alertTriangle,
                                );
                              }
                            },
                            icon: const Icon(
                              LucideIcons.externalLink,
                              size: 16,
                            ),
                            label: Text(
                              'View Server Setup Guide',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Tooltip(
                          message: 'Copy guide link',
                          child: OutlinedButton(
                            onPressed: () async {
                              await Clipboard.setData(
                                const ClipboardData(
                                  text:
                                      'https://github.com/ManishModak/parallax-connect/blob/main/SERVER_SETUP.md',
                                ),
                              );
                              if (!mounted) return;
                              _showSuccessSnackBar(
                                'Server setup link copied to clipboard.',
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary),
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: const Icon(LucideIcons.copy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'After the server starts, copy the URL shown in the terminal '
                      'or scan the QR code from that terminal to paste it here.',
                      style: GoogleFonts.inter(
                        color: AppColors.secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isLocal
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isLocal ? LucideIcons.wifi : LucideIcons.globe,
                                size: 16,
                                color: _isLocal
                                    ? Colors.blue.shade300
                                    : Colors.orange.shade300,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLocal ? 'Local Mode' : 'Cloud Mode',
                                style: GoogleFonts.inter(
                                  color: _isLocal
                                      ? Colors.blue.shade300
                                      : Colors.orange.shade300,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isLocal
                                ? 'Both devices must be on the same Wi-Fi.'
                                : 'Internet connection required on both devices.',
                            style: GoogleFonts.inter(
                              color: _isLocal
                                  ? Colors.blue.shade200
                                  : Colors.orange.shade200,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              const Spacer(),

              // Connect Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConnecting ? null : _saveAndConnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: AppColors.accent,
                  ),
                  child: _isConnecting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.background,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Connecting...',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Connect',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
