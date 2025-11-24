import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  bool _isPasswordVisible = false;

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

  Future<void> _scanQrCode() async {
    try {
      final scannedValue = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.background,
        builder: (_) => const _QrScannerSheet(),
      );

      if (!mounted || scannedValue == null) return;
      final trimmed = scannedValue.trim();
      if (trimmed.isEmpty) return;

      setState(() {
        _urlController.text = trimmed;
      });
      _urlController.selection = TextSelection.fromPosition(
        TextPosition(offset: trimmed.length),
      );
      _showSuccessSnackBar('URL scanned from QR.');
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'Failed to scan QR code',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      _showErrorSnackBar(
        'Unable to scan QR code. Paste URL manually.',
        LucideIcons.alertTriangle,
      );
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
            const Icon(LucideIcons.checkCircle, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.successDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.primary),
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
      body: SingleChildScrollView(
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Server URL or Address',
                      style: GoogleFonts.inter(
                        color: AppColors.secondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Tooltip(
                    message: 'Scan QR host URL',
                    child: IconButton(
                      icon: const Icon(LucideIcons.scanLine),
                      color: AppColors.secondary,
                      onPressed: _scanQrCode,
                    ),
                  ),
                  Tooltip(
                    message: 'Paste from clipboard',
                    child: IconButton(
                      icon: const Icon(LucideIcons.clipboardPaste),
                      color: AppColors.secondary,
                      onPressed: () async {
                        final clipboard = await Clipboard.getData(
                          Clipboard.kTextPlain,
                        );
                        final text = clipboard?.text?.trim();
                        if (text == null || text.isEmpty) {
                          if (!mounted) return;
                          _showErrorSnackBar(
                            'Clipboard is empty.',
                            LucideIcons.clipboardX,
                          );
                          return;
                        }
                        setState(() {
                          _urlController.text = text;
                        });
                        _urlController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _urlController.text.length),
                        );
                        if (!mounted) return;
                        _showSuccessSnackBar('URL pasted from clipboard.');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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

              Text(
                'Password (optional)',
                style: GoogleFonts.inter(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                style: GoogleFonts.inter(color: AppColors.primary),
                obscureText: !_isPasswordVisible,
                enableSuggestions: false,
                autocorrect: false,
                decoration: InputDecoration(
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
                  suffixIcon: IconButton(
                    tooltip: _isPasswordVisible
                        ? 'Hide password'
                        : 'Show password',
                    icon: Icon(
                      _isPasswordVisible ? LucideIcons.eyeOff : LucideIcons.eye,
                    ),
                    color: AppColors.secondary,
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
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
                        ? AppColors.modeLocal.withOpacity(0.3)
                        : AppColors.modeCloud.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLocal ? LucideIcons.info : LucideIcons.cloud,
                          color: _isLocal
                              ? AppColors.modeLocal
                              : AppColors.modeCloud,
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
                            ? AppColors.modeLocal.withOpacity(0.1)
                            : AppColors.modeCloud.withOpacity(0.1),
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
                                    ? AppColors.modeLocalLight
                                    : AppColors.modeCloudLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isLocal ? 'Local Mode' : 'Cloud Mode',
                                style: GoogleFonts.inter(
                                  color: _isLocal
                                      ? AppColors.modeLocalLight
                                      : AppColors.modeCloudLight,
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
                                  ? AppColors.modeLocalLighter
                                  : AppColors.modeCloudLighter,
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

              const SizedBox(height: 24),

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

class _QrScannerSheet extends StatefulWidget {
  const _QrScannerSheet();

  @override
  State<_QrScannerSheet> createState() => _QrScannerSheetState();
}

class _QrScannerSheetState extends State<_QrScannerSheet> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return SafeArea(
      child: SizedBox(
        height: height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    'Scan Server QR',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close scanner',
                    icon: const Icon(LucideIcons.x, color: AppColors.primary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Align the QR code within the frame to capture the server URL.',
                style: GoogleFonts.inter(
                  color: AppColors.primary.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _controller,
                    onDetect: (capture) {
                      if (_hasDetected) return;
                      for (final barcode in capture.barcodes) {
                        final rawValue = barcode.rawValue;
                        if (rawValue != null && rawValue.isNotEmpty) {
                          setState(() {
                            _hasDetected = true;
                          });
                          Navigator.of(context).pop(rawValue);
                          break;
                        }
                      }
                    },
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.7),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
