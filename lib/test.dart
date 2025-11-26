import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'db_helper.dart';

class TestPage extends StatefulWidget {
  final int listId;
  final String? listeAdi;
  final List<Map<String, dynamic>>? entries;

  const TestPage({
    super.key,
    required this.listId,
    this.listeAdi,
    this.entries,
  });

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final DBHelper _db = DBHelper();
  List<Map<String, dynamic>> _items = [];
  List<int> _order = [];
  int _current = 0;
  int _score = 0;
  bool _answered = false;
  int? _selectedIndex;
  List<String> _choices = [];
  int _correctChoiceIndex = 0;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    if (widget.entries != null) {
      _items = List.from(widget.entries!);
    } else {
      _items = await _db.getItems(widget.listId);
    }
    if (_items.length < 4) {
      // shouldn't happen because caller checks, but guard
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Yeterli kelime yok.')));
        Navigator.pop(context);
      }
      return;
    }
    // create order (shuffle indices)
    _order = List.generate(_items.length, (i) => i);
    _order.shuffle(Random());
    _current = 0;
    _score = 0;
    _prepareQuestion();
    setState(() {});
  }

  void _prepareQuestion() {
    _answered = false;
    _selectedIndex = null;
    final idx = _order[_current];
    final correctMeaning = _items[idx]['meaning'] as String;
    // get other meanings
    final otherMeanings = _items
        .where((e) => e != _items[idx])
        .map((e) => e['meaning'] as String)
        .toList();
    otherMeanings.shuffle(Random());
    final choices = <String>[];
    choices.add(correctMeaning);
    choices.addAll(otherMeanings.take(3));
    choices.shuffle(Random());
    _choices = choices;
    _correctChoiceIndex = _choices.indexOf(correctMeaning);
  }

  void _onSelect(int i) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _selectedIndex = i;
      if (i == _correctChoiceIndex) {
        _score++;
      }
    });
    // move to next after short delay
    Timer(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      if (_current + 1 >= _order.length) {
        _showResult();
      } else {
        setState(() {
          _current++;
          _prepareQuestion();
        });
      }
    });
  }

  void _showResult() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Test Sonucu'),
        content: Text('Skorunuz: $_score / ${_order.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Tamam'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // restart
              setState(() {
                _order.shuffle(Random());
                _current = 0;
                _score = 0;
                _prepareQuestion();
              });
            },
            child: const Text('Yeniden Başlat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.listeAdi ?? 'Test')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final idx = _order[_current];
    final word = _items[idx]['word'] as String;
    return Scaffold(
      appBar: AppBar(title: Text(widget.listeAdi ?? 'Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Soru ${_current + 1} / ${_order.length}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '$word kelimesinin anlamı nedir ?',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(4, (i) {
              final isSelected = _selectedIndex == i;
              Color? color;
              if (_answered) {
                if (i == _correctChoiceIndex) {
                  color = Colors.green[300];
                } else if (isSelected && i != _correctChoiceIndex) {
                  color = Colors.red[300];
                } else {
                  color = null;
                }
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                  ),
                  onPressed: () => _onSelect(i),
                  child: Row(
                    children: [
                      Text(
                        '${String.fromCharCode(65 + i)}) ',
                        style: const TextStyle(fontSize: 16),
                      ),
                      Expanded(
                        child: Text(
                          _choices[i],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            Text('Skor: $_score', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
