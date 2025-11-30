import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:8000";

  Future<String> enviarAudio(String audioPath, String musica) async {
    final uri = Uri.parse("$baseUrl/analisar");

    final request = http.MultipartRequest("POST", uri);
    request.fields["musica"] = musica;
    request.files.add(await http.MultipartFile.fromPath("audio", audioPath));

    final resposta = await request.send();
    final corpo = await resposta.stream.bytesToString();

    if (resposta.statusCode == 200) {
      return corpo;
    } else {
      return "Erro: $corpo";
    }
  }
}
