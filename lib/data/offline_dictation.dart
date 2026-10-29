import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Only invokes a bundled local executable. No OS cloud dictation or network API.
class OfflineDictation {
  static const _channel = MethodChannel('daymark/recorder');
  bool _recording = false;
  bool get recording => _recording;

  Future<void> start() async {
    if (!Platform.isWindows) {
      throw const FormatException(
        'Diktat ist derzeit nur unter Windows verfügbar.',
      );
    }
    await _channel.invokeMethod<void>('start');
    _recording = true;
  }

  Future<String> stopAndTranscribe() async {
    if (!_recording) throw const FormatException('Keine Aufnahme läuft.');
    final dir = await Directory.systemTemp.createTemp('daymark_dictation_');
    final audio = p.join(dir.path, 'note.wav');
    final output = p.join(dir.path, 'transcript');
    try {
      await _channel.invokeMethod<void>('stop', audio);
      _recording = false;
      final appDir = p.dirname(Platform.resolvedExecutable);
      final cli = p.join(appDir, 'data', 'whisper', 'whisper-cli.exe');
      final model = p.join(appDir, 'data', 'whisper', 'ggml-base.bin');
      if (!await File(cli).exists() || !await File(model).exists()) {
        throw const FormatException(
          'Das lokale Sprachmodell fehlt im Programmordner.',
        );
      }
      final result = await Process.run(cli, [
        '-m',
        model,
        '-f',
        audio,
        '-l',
        'de',
        '-otxt',
        '-of',
        output,
      ]);
      if (result.exitCode != 0) {
        throw const FormatException(
          'Die lokale Transkription ist fehlgeschlagen.',
        );
      }
      final transcript = File('$output.txt');
      if (!await transcript.exists()) {
        throw const FormatException('Kein Transkript erzeugt.');
      }
      return (await transcript.readAsString()).trim();
    } finally {
      _recording = false;
      await dir.delete(recursive: true);
    }
  }

  Future<void> cancel() async {
    if (_recording) await _channel.invokeMethod<void>('cancel');
    _recording = false;
  }
}
