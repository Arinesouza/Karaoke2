import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<String> enviarAudio(
    String audioPath,
    String titulo,
    String artista,
  ) async {
    final uri = Uri.parse(baseUrl);

    final request = http.MultipartRequest("POST", uri);

    request.fields["titulo"] = titulo;
    request.fields["artista"] = artista;

    request.files.add(await http.MultipartFile.fromPath("audio", audioPath));

    final resposta = await request.send();
    final corpo = await resposta.stream.bytesToString();

    if (resposta.statusCode == 200) {
      return corpo;
    } else {
      return '{"erro": true, "mensagem": "$corpo"}';
    }
  }
}
