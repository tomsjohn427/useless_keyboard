// lib/main.dart
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(ChaoticKeyboardApp());
}

class ChaoticKeyboardApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keyboard of Chaos',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ChaoticKeyboardDemo(),
    );
  }
}

class ChaoticKeyboardDemo extends StatefulWidget {
  @override
  _ChaoticKeyboardDemoState createState() => _ChaoticKeyboardDemoState();
}

class _ChaoticKeyboardDemoState extends State<ChaoticKeyboardDemo> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // Base key pool (letters, digits, and some symbols)
  List<String> _baseKeys = [
    // letters
    'q','w','e','r','t','y','u','i','o','p',
    'a','s','d','f','g','h','j','k','l',
    'z','x','c','v','b','n','m',
    // digits
    '0','1','2','3','4','5','6','7','8','9',
    // symbols
    '!','@','#','\$','%','^','&','*','(',')',
    '-','_','=','+','[',']','{','}',';','\'',':','"',',','.','/','?','\\','|','`','~'
  ];

  List<String> _keys = [];
  bool _caps = false;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _resetKeys();
  }

  void _resetKeys() {
    // Start with a shuffled copy of base keys
    _keys = List<String>.from(_baseKeys)..shuffle(_rand);
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '␣') {
        _controller.text += ' ';
      } else if (key == '⌫') {
        final text = _controller.text;
        if (text.isNotEmpty) {
          _controller.text = text.substring(0, text.length - 1);
        }
      } else if (key == '⏎') {
        _controller.text += '\n';
      } else if (key == '⇧') {
        _caps = !_caps;
      } else {
        _controller.text += _caps ? key.toUpperCase() : key;
      }

      // After every typing (except Shift toggle), shuffle keys
      if (key != '⇧') {
        _keys.shuffle(_rand);
      }

      // Keep cursor at end
      _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length));
    });
  }

  Widget _buildKey(String label, {double height = 48}) {
    final displayLabel = (label == '␣' || label == '⌫' || label == '⏎' || label == '⇧')
        ? label
        : (_caps ? label.toUpperCase() : label);

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _onKeyPress(label),
          child: Center(
            child: Text(
              displayLabel,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  // Build a keyboard grid using current _keys list
  Widget _buildKeyboard() {
    // We'll show most keys in a grid, plus a bottom row for special keys
    // Choose how many columns - responsive
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 12 : 8;

    // Make a trimmed copy so the GridView looks tidy (you can expand)
    final visibleKeys = _keys;

    return Column(
      children: [
        // Grid of normal keys
        Flexible(
          child: GridView.count(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.6,
            children: visibleKeys.map((k) => _buildKey(k)).toList(),
          ),
        ),
        // Bottom special row
        Container(
          color: Colors.grey.shade200,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            children: [
              Expanded(flex: 2, child: _buildKey('⇧', height: 48)),
              Expanded(flex: 6, child: _buildKey('␣', height: 48)),
              Expanded(flex: 2, child: _buildKey('⌫', height: 48)),
              SizedBox(width: 8),
              Expanded(flex: 2, child: _buildKey('⏎', height: 48)),
            ],
          ),
        ),
      ],
    );
  }

  // Optional: quick toggle to switch between simple alphabet-only mode
  void _switchToAlphabetOnly() {
    setState(() {
      _keys = List<String>.from([
        'q','w','e','r','t','y','u','i','o','p',
        'a','s','d','f','g','h','j','k','l',
        'z','x','c','v','b','n','m'
      ])..shuffle(_rand);
    });
  }

  void _switchToFullMode() {
    setState(() {
      _resetKeys();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _switchToAlphabetOnly,
            child: Text('Alphabet Only'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _switchToFullMode,
            child: Text('Full Mode'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Clear text
              setState(() {
                _controller.clear();
              });
            },
            child: Text('Clear'),
          ),
          SizedBox(width: 8),
          Text('Caps: ${_caps ? "ON" : "OFF"}'),
          Spacer(),
          Text('Shuffle after each press ✓'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keyboard of Chaos'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopControls(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: true, // prevent system keyboard
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Type here using the chaotic keyboard below...',
                  border: OutlineInputBorder(),
                ),
                onTap: () {
                  // keep focus to show caret
                  _focusNode.requestFocus();
                },
              ),
            ),
            SizedBox(height: 8),
            Expanded(child: _buildKeyboard()),
          ],
        ),
      ),
    );
  }
}