import 'package:flutter/material.dart';

void main() {
  runApp(const AnaSayfa());
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final List<TextEditingController> _controllers = [];

  Widget _listeAdiField(TextEditingController controller) {
    return SizedBox(
      width: double.infinity,
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Liste Adı Girin',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Kelime Öğrenme Uygulaması')),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _controllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Liste Oluştur'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _controllers.isEmpty
                    ? const Center(
                        child: Text('Henüz liste yok. Butona basın.'),
                      )
                    : ListView.builder(
                        itemCount: _controllers.length,
                        itemBuilder: (context, index) {
                          final controller = _controllers[index];
                          return Card(
                            key: ValueKey(controller),
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Expanded(child: _listeAdiField(controller)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.open_in_new),
                                    tooltip: 'Listeye Git',
                                    onPressed: () {
                                      final name = controller.text;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Listeye gidiliyor: ${name.isEmpty ? 'İsim yok' : name}',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Sil',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Silme Onayı'),
                                          content: const Text(
                                            'Bu kelime listesini silmek istediğinize emin misiniz?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('İptal'),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Sil'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        setState(() {
                                          _controllers[index].dispose();
                                          _controllers.removeAt(index);
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
