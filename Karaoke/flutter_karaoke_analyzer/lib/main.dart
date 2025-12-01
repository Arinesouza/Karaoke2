import 'package:flutter/material.dart';
import 'package:flutter_karaoke_analyzer/pages/HomePage.dart';

// Definimos as constantes aqui para facilitar a troca do IP
const String SERVER_IP = '192.168.1.112';
const String SERVER_PORT = '5000'; // Porta padrão do Flask
const String SERVER_URL = 'http://$SERVER_IP:$SERVER_PORT/analisar';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Karaoke App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: HomePage(serverUrl: SERVER_URL),
    );
  }
}
