import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'test.dart';

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

  String? _centerMessage;

  void _showCenterMessage(String msg, {int seconds = 3}) {
    _centerMessage = msg;
    setState(() {});
    Timer(Duration(seconds: seconds), () {
      if (mounted) {
        setState(() {
          _centerMessage = null;
        });
      }
    });
  }

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
      // Prevent duplicates (case-insensitive by word)
      if (kIsWeb) {
        final existing = (_webStore[widget.listId] ?? []).any(
          (e) => (e['word'] as String).toLowerCase() == kelime.toLowerCase(),
        );
        if (existing) {
          if (!mounted) return;
          _showCenterMessage('Bu kelime listede zaten var.');
          return;
        }
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
        final exists = await _db.itemExists(widget.listId, kelime);
        if (exists) {
          if (!mounted) return;
          _showCenterMessage('Bu kelime listede zaten var.');
          return;
        }
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
    return Stack(
      children: [
        Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              // Start test only if at least 4 entries
              if (_entries.length < 4) {
                _showCenterMessage('Yeterli kelime yok. Yeterli kelime = 4');
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => TestPage(
                    listId: widget.listId,
                    listeAdi: widget.listeAdi,
                    entries: List.from(_entries),
                  ),
                ),
              );
            },
            label: const Text('Test Et'),
            icon: const Icon(Icons.quiz),
          ),
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
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        enableSuggestions: true,
                        autocorrect: true,
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
                        keyboardType: TextInputType.text,
                        textCapitalization: TextCapitalization.none,
                        enableSuggestions: true,
                        autocorrect: true,
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
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
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
        ),
        // Centered warning card overlay
        if (_centerMessage != null)
          Positioned.fill(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _centerMessage = null;
                  });
                },
                child: Card(
                  elevation: 8,
                  color: Colors.yellow[100],
                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, color: Colors.black87),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _centerMessage!,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _centerMessage = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
