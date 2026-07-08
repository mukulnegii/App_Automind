import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VoiceRecorder {

  final Record _recorder = Record();
  String? _path;

  Future<void> start() async {

    if (await _recorder.hasPermission()) {

      final dir = await getTemporaryDirectory();
      _path = "${dir.path}/voice_input.wav";

      await _recorder.start(
        path: _path!,
        encoder: AudioEncoder.wav,
        samplingRate: 16000,
        bitRate: 128000,
      );

      print("Recording -> $_path");
    }
  }

  Future<String?> stop() async {
    return await _recorder.stop();
  }
}
