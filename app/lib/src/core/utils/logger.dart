import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

/// Custom file output for logger
class FileOutput extends LogOutput {
  File? _file;
  IOSink? _sink;

  @override
  Future<void> init() async {
    super.init();
    await _initLogFile();
  }

  Future<void> _initLogFile() async {
    try {
      String logPath;
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');

      // On desktop/development, save to project directory for easy access
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Save to project's logs directory
        logPath = 'logs/debug_$timestamp.txt';
      } else {
        // On mobile,save to app documents
        final dir = await getApplicationDocumentsDirectory();
        logPath = '${dir.path}/logs/debug_$timestamp.txt';
      }

      _file = File(logPath);

      // Create logs directory if it doesn't exist
      await _file!.parent.create(recursive: true);

      // Open file for writing
      _sink = _file!.openWrite(mode: FileMode.append);
      _sink!.writeln('=== Log started at ${DateTime.now()} ===\n');

      print('📝 Logging to: ${_file!.absolute.path}');
    } catch (e) {
      print('Failed to initialize log file: $e');
    }
  }

  @override
  void output(OutputEvent event) {
    if (_sink != null) {
      for (var line in event.lines) {
        _sink!.writeln(line);
      }
    }
  }

  @override
  Future<void> destroy() async {
    await _sink?.close();
    await super.destroy();
  }
}

/// Global logger instance with environment-based configuration
final logger = _createLogger();

Logger _createLogger() {
  // In release mode, use minimal logging
  if (kReleaseMode) {
    return Logger(
      level: Level.warning, // Only log warnings and errors in production
      printer: SimplePrinter(),
      filter: ProductionFilter(),
    );
  }

  // In debug/profile mode, use detailed logging with file output
  return Logger(
    level: Level.debug,
    printer: PrettyPrinter(
      methodCount: 0, // No stack trace for regular logs
      errorMethodCount: 5, // Stack trace for errors
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      excludeBox: {Level.debug: false, Level.trace: false},
    ),
    filter: DevelopmentFilter(),
    output: MultiOutput([
      ConsoleOutput(), // Still log to console
      FileOutput(), // Also log to file
    ]),
  );
}

/// Custom log methods for convenience
extension LoggerExtension on Logger {
  /// Log network request
  void network(String message, [dynamic data]) {
    d(data != null ? '🌐 $message: $data' : '🌐 $message');
  }

  /// Log navigation
  void navigation(String message, [dynamic data]) {
    d(data != null ? '🧭 $message: $data' : '🧭 $message');
  }

  /// Log storage operation
  void storage(String message, [dynamic data]) {
    d(data != null ? '💾 $message: $data' : '💾 $message');
  }

  /// Log API response
  void api(String message, [dynamic data]) {
    d(data != null ? '📡 $message: $data' : '📡 $message');
  }
}
