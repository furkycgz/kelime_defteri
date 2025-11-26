import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class KelimePage extends StatefulWidget {
  final int listId;
  final String? listeAdi;
  const KelimePage({super.key, required this.listId, this.listeAdi});

  @override
  State<KelimePage> createState() => _KelimePageState();
}

class _KelimePageState extends State<KelimePage> {
  final TextEditingController _kelimeController = TextEditingController();
  final TextEditingController _anlamController = TextEditingController();
  final DBHelper _db = DBHelper();
  List<Map<String, dynamic>> _entries =
      []; // each: {id, list_id, word, meaning}

  // In-memory fallback for web where sqflite isn't available
  static final Map<int, List<Map<String, dynamic>>> _webStore = {};

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    if (kIsWeb) {
      setState(() {
        _entries = List.from(_webStore[widget.listId] ?? []);
      });
      return;
    }
    final items = await _db.getItems(widget.listId);
    setState(() {
      _entries = items;
    });
  }

  @override
  void dispose() {
    _kelimeController.dispose();
    _anlamController.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final kelime = _kelimeController.text.trim();
    final anlam = _anlamController.text.trim();
    if (kelime.isEmpty || anlam.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kelime ve anlam boş olmamalı.')),
      );
      return;
    }
    try {
      if (kIsWeb) {
        final id = DateTime.now().microsecondsSinceEpoch;
        final entry = {
          'id': id,
          'list_id': widget.listId,
          'word': kelime,
          'meaning': anlam,
        };
        _webStore.putIfAbsent(widget.listId, () => []);
        setState(() {
          _webStore[widget.listId]!.insert(0, entry);
          _entries = List.from(_webStore[widget.listId]!);
        });
      } else {
        await _db.addItem(widget.listId, kelime, anlam);
        await _loadItems();
      }
      _kelimeController.clear();
      _anlamController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Kelime eklendi.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    }
  }

  Future<void> _removeEntryById(int id) async {
    await _db.deleteItem(id);
    await _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final title = (widget.listeAdi == null || widget.listeAdi!.isEmpty)
        ? 'Kelime Listesi'
        : widget.listeAdi!;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _kelimeController,
                    decoration: const InputDecoration(
                      labelText: 'Kelime (ör: pencil)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _anlamController,
                    decoration: const InputDecoration(
                      labelText: 'Anlamı (ör: kalem)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Ekle'),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    _kelimeController.clear();
                    _anlamController.clear();
                  },
                  icon: const Icon(Icons.clear),
                  label: const Text('Temizle'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Expanded(
              child: _entries.isEmpty
                  ? const Center(child: Text('Henüz kelime yok. Ekleyin.'))
                  : ListView.builder(
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final entry = _entries[index];
                        final id = entry['id'] as int;
                        final word = entry['word'] as String;
                        final meaning = entry['meaning'] as String;
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6.0),
                          child: ListTile(
                            title: Text('$word->$meaning'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeEntryById(id),
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
