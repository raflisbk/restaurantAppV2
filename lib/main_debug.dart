import 'package:flutter/material.dart';

void main() {
  runApp(const DebugApp());
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Debug App',
      home: Scaffold(
        appBar: AppBar(title: const Text('Debug App')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Flutter App is Working!', style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              Text(
                'If you see this, the basic Flutter setup is OK.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
