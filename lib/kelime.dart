import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
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
  @override
  Widget build(BuildContext context) {
    final title = (widget.listeAdi == null || widget.listeAdi!.isEmpty)
        ? 'Kelime Listesi'
        : widget.listeAdi!;

    return Stack(
      children: [
        Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color.fromARGB(255, 243, 243, 2),
            onPressed: () {
              if (_entries.length < 4) {
                _showCenterMessage(
                  'Yeterli kelime yok. En az 4 kelime ekleyin.',
                );
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
            label: const Text(
              'Test Et',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            icon: const Icon(Icons.quiz, size: 28),
          ),

          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            elevation: 4,
            centerTitle: true,
            backgroundColor: Colors.deepPurple,
          ),

          body: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // 🔵 EKLEME BÖLÜMÜ - Modern Kart
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _kelimeController,
                                decoration: InputDecoration(
                                  labelText: 'Kelime (ör: pencil)',
                                  prefixIcon: const Icon(Icons.edit),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _anlamController,
                                decoration: InputDecoration(
                                  labelText: 'Anlamı (ör: kalem)',
                                  prefixIcon: const Icon(Icons.translate),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _addEntry,
                                icon: const Icon(Icons.add),
                                label: const Text('Ekle'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                    255,
                                    1,
                                    255,
                                    238,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  _kelimeController.clear();
                                  _anlamController.clear();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Temizle'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: const BorderSide(
                                    color: Colors.deepPurple,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 10),
                const Divider(),

                Expanded(
                  child: _entries.isEmpty
                      ? const Center(
                          child: Text(
                            'Henüz kelime yok.\nHemen ekleyin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final id = entry['id'] as int;
                            final word = entry['word'] as String;
                            final meaning = entry['meaning'] as String;

                            return Card(
                              elevation: 3,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                title: Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  meaning,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  child: Text(
                                    word.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
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

        // 🎛 Modern Uyarı Kutusu — blurred dim background + elevated card
        if (_centerMessage != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _centerMessage = null),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: 1.0,
                child: Stack(
                  children: [
                    // blurred dim layer
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.black45),
                    ),
                    // centered card
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Card(
                          elevation: 14,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 18,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.deepOrange,
                                  child: const Icon(
                                    Icons.warning_amber,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _centerMessage!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _centerMessage = null),
                                  child: const Text('Kapat'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
