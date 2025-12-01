import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../services/audio_recorder_service.dart';
import '../services/api_service.dart';
import '../services/youtube_service.dart';

class HomePage extends StatefulWidget {
  final String serverUrl;

  const HomePage({super.key, required this.serverUrl});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final ApiService api;
  final recorder = AudioRecorderService();
  final yt = YoutubeService();

  YoutubePlayerController? controller;
  String? audioPath;
  String resultado = "";

  final tituloController = TextEditingController();
  final artistaController = TextEditingController();

  bool gravando = false;
  bool enviando = false;

  @override
  void initState() {
    super.initState();
    // Carrega vídeo do YouTube (não pausa durante gravação)
    controller = yt.loadVideo(
      "https://www.youtube.com/watch?v=nSDgHBxUbVQ&list=RDnSDgHBxUbVQ&start_radio=1",
    );

    // Cria ApiService com a URL do servidor
    api = ApiService(baseUrl: widget.serverUrl);
  }

  @override
  void dispose() {
    controller?.dispose();
    recorder.dispose();
    tituloController.dispose();
    artistaController.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      setState(() => gravando = true);
      await recorder.startRecording();
    } catch (e) {
      setState(() => gravando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao iniciar gravação: $e")));
    }
  }

  Future<void> stopRecording() async {
    try {
      audioPath = await recorder.stopRecording();
      setState(() => gravando = false);
    } catch (e) {
      setState(() => gravando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao parar gravação: $e")));
    }
  }

  Future<void> enviar() async {
    if (audioPath == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nenhum áudio gravado!")));
      return;
    }

    if (tituloController.text.isEmpty || artistaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha todos os campos.")),
      );
      return;
    }

    try {
      setState(() => enviando = true);
      final resposta = await api.enviarAudio(
        audioPath!,
        tituloController.text,
        artistaController.text,
      );
      setState(() {
        resultado = resposta;
        enviando = false;
      });
    } catch (e) {
      setState(() => enviando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao enviar áudio: $e")));
    }
  }

  Widget statusCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              gravando ? Icons.mic : Icons.mic_none,
              size: 34,
              color: gravando ? Colors.red : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                gravando
                    ? "Gravando..."
                    : audioPath == null
                    ? "Pronto para gravar"
                    : "Áudio gravado: ${audioPath!.split('/').last}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: gravando ? Colors.red : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: color),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Karaokê Analyzer")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: YoutubePlayer(controller: controller!),
              ),
            const SizedBox(height: 25),
            statusCard(),
            const SizedBox(height: 20),
            TextField(
              controller: tituloController,
              decoration: const InputDecoration(
                labelText: "Título da Música",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: artistaController,
              decoration: const InputDecoration(
                labelText: "Artista",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            buildButton(
              "Iniciar Gravação",
              Icons.mic,
              gravando ? null : startRecording,
            ),
            const SizedBox(height: 10),
            buildButton(
              "Parar Gravação",
              Icons.stop,
              gravando ? stopRecording : null,
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            buildButton(
              enviando ? "Enviando..." : "Enviar para Análise",
              Icons.upload,
              enviando ? null : enviar,
            ),
            const SizedBox(height: 30),
            if (resultado.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(resultado, style: const TextStyle(fontSize: 16)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
