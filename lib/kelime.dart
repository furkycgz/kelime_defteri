import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       home: Scaffold(
        appBar: AppBar(title: const Text('Kelime Öğrenme Uygulaması')),

        body: Column(
          children: [
            SizedBox(height: 20),
            Center(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Kelime Girin',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}