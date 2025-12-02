import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'kelime.dart';
import 'db_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Kelime Öğreniyorum',
      debugShowCheckedModeBanner: false,
      home: AnaSayfa(),
    );
  }
}

class AnaSayfa extends StatefulWidget {
  const AnaSayfa({super.key});

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> {
  final TextEditingController _newListController = TextEditingController();
  final DBHelper _db = DBHelper();
  List<Map<String, dynamic>> _lists = [];
  // Web fallback storage (non-persistent)
  static final List<Map<String, dynamic>> _webLists = [];

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  Future<void> _loadLists() async {
    if (kIsWeb) {
      setState(() {
        // display existing web lists in uppercase
        _lists = _webLists
            .map(
              (e) => {
                'id': e['id'],
                'name': (e['name'] as String).toUpperCase(),
              },
            )
            .toList();
      });
      return;
    }
    final lists = await _db.getLists();
    setState(() {
      // normalize to uppercase for display
      _lists = lists
          .map(
            (e) => {'id': e['id'], 'name': (e['name'] as String).toUpperCase()},
          )
          .toList();
    });
  }

  Future<void> _createListFromName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Liste başlığı boş bırakılmamalı.')));
      return;
    }
    final upper = trimmed.toUpperCase();
    try {
      if (kIsWeb) {
        final id = DateTime.now().microsecondsSinceEpoch;
        _webLists.insert(0, {'id': id, 'name': upper});
        setState(() {
          _lists = List.from(_webLists);
        });
      } else {
        await _db.createList(upper);
        await _loadLists();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Liste oluşturuldu.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Liste oluşturulamadı: $e')));
    }
  }

  Future<void> _showCreateListDialog() async {
    _newListController.clear();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Yeni Liste Oluştur',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Builder(
          builder: (ctx) => TextField(
            controller: _newListController,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => Navigator.pop(ctx, true),
            decoration: InputDecoration(
              labelText: 'Liste Başlığı Giriniz',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 250, 29),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _createListFromName(_newListController.text);
    }
  }

  Future<void> _deleteList(int id) async {
    try {
      if (kIsWeb) {
        _webLists.removeWhere((e) => e['id'] == id);
        await _loadLists();
        return;
      }
      await _db.deleteList(id);
      await _loadLists();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Liste silindi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme başarısız: $e')));
    }
  }

  @override
  void dispose() {
    _newListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kelime Öğrenme Uygulaması',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 4,
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔵 Büyük Modern Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 28),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Yeni Kelime Listesi Oluştur',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 250, 29),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                onPressed: _showCreateListDialog,
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _lists.isEmpty
                  ? const Center(
                      child: Text(
                        'Henüz liste yok.\nButona basarak oluşturabilirsin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _lists.length,
                      itemBuilder: (context, index) {
                        final item = _lists[index];
                        final id = item['id'] as int;
                        final name = item['name'] as String;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) =>
                                      KelimePage(listId: id, listeAdi: name),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  tooltip: 'Listeye Git',
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (ctx) => KelimePage(
                                          listId: id,
                                          listeAdi: name,
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
                                            child: const Text(
                                              'Sil',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) await _deleteList(id);
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
    );
  }
}
