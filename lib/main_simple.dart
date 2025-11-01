import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barbearia App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste Barbearia'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.content_cut,
              size: 100,
              color: Colors.amber,
            ),
            const SizedBox(height: 24),
            const Text(
              'App Funcionando!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                print('Botão clicado!');
              },
              child: const Text('Testar Botão'),
            ),
          ],
        ),
      ),
    );
  }
}
