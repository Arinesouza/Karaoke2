import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _filePath;

  Future<void> startRecording() async {
    if (!await _recorder.hasPermission()) {
      throw Exception("Sem permissão para gravar áudio");
    }

    final dir = await getApplicationDocumentsDirectory();
    _filePath =
        "${dir.path}/gravacao_${DateTime.now().millisecondsSinceEpoch}.m4a";

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: _filePath!,
    );
  }

  Future<String> stopRecording() async {
    final path = await _recorder.stop();

    if (path == null) {
      throw Exception("Nenhum áudio foi gravado");
    }

    return path;
  }

  void dispose() {
    _recorder.dispose();
  }
}
