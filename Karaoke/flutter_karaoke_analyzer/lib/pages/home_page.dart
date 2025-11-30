import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../services/audio_recorder_service.dart';
import '../services/api_service.dart';
import '../services/youtube_service.dart';


class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final recorder = AudioRecorderService();
  final api = ApiService();
  final yt = YoutubeService();

  YoutubePlayerController? controller;
  String? audioPath;
  String resultado = "";

  @override
  void initState() {
    super.initState();
    controller = yt.loadVideo("https://www.youtube.com/watch?v=dQw4w9WgXcQ");
  }

  @override
  void dispose() {
    controller?.dispose();
    recorder.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      await recorder.startRecording();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao iniciar gravação: $e")),
      );
    }
  }

  Future<void> stopRecording() async {
    try {
      audioPath = await recorder.stopRecording();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao parar gravação: $e")),
      );
    }
  }

  Future<void> enviar() async {
    if (audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhum áudio gravado!")),
      );
      return;
    }

    try {
      final resposta = await api.enviarAudio(audioPath!, "musicaTeste");
      setState(() => resultado = resposta);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao enviar áudio: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Karaokê Analyzer")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (controller != null) YoutubePlayer(controller: controller!),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: startRecording,
              child: const Text("🎤 Iniciar Gravação"),
            ),
            ElevatedButton(
              onPressed: stopRecording,
              child: const Text("🛑 Parar Gravação"),
            ),
            ElevatedButton(
              onPressed: enviar,
              child: const Text("📤 Enviar para Análise"),
            ),

            const SizedBox(height: 20),
            Text("Resultado: $resultado"),
          ],
        ),
      ),
    );
  }
}
