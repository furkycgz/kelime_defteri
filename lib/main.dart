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
        _lists = List.from(_webLists);
      });
      return;
    }
    final lists = await _db.getLists();
    setState(() {
      _lists = lists;
    });
  }

  Future<void> _createListFromName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    try {
      if (kIsWeb) {
        final id = DateTime.now().microsecondsSinceEpoch;
        _webLists.insert(0, {'id': id, 'name': trimmed});
        setState(() {
          _lists = List.from(_webLists);
        });
      } else {
        await _db.createList(trimmed);
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
        title: const Text('Yeni Liste Oluştur'),
        content: TextField(
          controller: _newListController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Liste Adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
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
        title: const Text('Kelime Öğrenme Uygulaması'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yeni Liste Ekle',
            onPressed: _showCreateListDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: _lists.isEmpty
                  ? const Center(child: Text('Henüz liste yok. Butona basın.'))
                  : ListView.builder(
                      itemCount: _lists.length,
                      itemBuilder: (context, index) {
                        final item = _lists[index];
                        final id = item['id'] as int;
                        final name = item['name'] as String;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            title: Text(
                              name,
                              style: const TextStyle(fontSize: 16),
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
                                            child: const Text('Sil'),
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
