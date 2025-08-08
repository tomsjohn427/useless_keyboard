import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Added for haptic feedback

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

  late List<String> _letterKeys;
  late List<String> _symbolKeys;
  List<String> _keys = [];
  String _mode = 'letters';
  bool _caps = false;
  final Random _rand = Random();

  // New features: Typing test
  final List<String> _sentences = [
    'the children laugh loudly',
    'we watch movies on Fridays',
    'the sun rises in the east',
    'he drinks milk every morning',
    'he writes with a pen',
    'she wears a red dress',
    'the baby is sleeping now',
    'birds fly in the sky',
    'dogs are friendly animals',
    'the stars shine at night',
    'the fish swim in the water',
    'it is a sunny day',
    'I like to eat apples',
    'the cat sat on the mat',
    'the car moves on the road',
    'the flowers bloom in spring',
    'she likes to read books',
    'they play football on weekends',
    'he runs fast in the park',
    'we go to school every day',
  ];
  String _currentSentence = '';
  Timer? _timer;
  bool _isTyping = false;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _letterKeys = _baseKeys.sublist(0, 26);
    _symbolKeys = _baseKeys.sublist(26);
    _resetKeys();
    _resetTest();
  }

  void _resetKeys() {
    setState(() {
      if (_mode == 'letters') {
        _keys = List<String>.from(_letterKeys)..shuffle(_rand);
      } else {
        _keys = List<String>.from(_symbolKeys)..shuffle(_rand);
      }
    });
  }

  void _onKeyPress(String key) {
    setState(() {
      // Start timer on first typing
      if (!_isTyping && key != '⇧' && key != '?123' && key != 'ABC' && key != '⌫') {
        _startTyping();
      }

      if (key == '␣') {
        _controller.text += ' ';
      } else if (key == '⌫') {
        final text = _controller.text;
        if (text.isNotEmpty) {
          _controller.text = text.substring(0, text.length - 1);
        }
        HapticFeedback.lightImpact(); // Short haptic feedback for backspace
        return; // Don't shuffle on backspace
      } else if (key == '⏎') {
        _controller.text += '\n';
      } else if (key == '⇧') {
        _caps = !_caps;
        return; // Don't shuffle or vibrate on shift
      } else if (key == '?123') {
        _mode = 'numbers';
        _caps = false; // Reset caps for numbers mode
        _resetKeys();
        return; // Don't vibrate on mode toggle
      } else if (key == 'ABC') {
        _mode = 'letters';
        _resetKeys();
        return; // Don't vibrate on mode toggle
      } else {
        _controller.text += (_caps && _mode == 'letters') ? key.toUpperCase() : key;
      }

      // Shuffle after typing (except specials above)
      _resetKeys();

      // Short haptic feedback for key press
      HapticFeedback.lightImpact();

      // Keep cursor at end
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    });
  }

  void _startTyping() {
    _isTyping = true;
    _startTime = DateTime.now();
    _timer = Timer(Duration(seconds: 30), _endTest);
  }

  void _endTest() {
    if (_startTime == null) return;

    final elapsedMinutes = 0.5; // 30 seconds = 0.5 minutes
    final typedText = _controller.text.trim();
    final wordCount = typedText.isEmpty ? 0 : typedText.split(RegExp(r'\s+')).length;
    final wpm = (wordCount / elapsedMinutes).toStringAsFixed(2);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Typing Test Result'),
        content: Text('Your average WPM: $wpm'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTest();
            },
            child: Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _resetTest() {
    setState(() {
      _controller.clear();
      _currentSentence = _sentences[_rand.nextInt(_sentences.length)];
      _isTyping = false;
      _startTime = null;
      _timer?.cancel();
      _timer = null;
    });
  }

  Widget _buildKey(String label, {double height = 48}) {
    String displayLabel = label;
    if (_mode == 'letters' && _caps && label.length == 1 && label.toLowerCase() != label.toUpperCase()) {
      displayLabel = label.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: SizedBox(
        height: height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          onPressed: () => _onKeyPress(label),
          child: Center(
            child: Text(
              displayLabel,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    // Gboard-like row-based layout for both modes
    List<String> row1, row2, row3;
    String toggleKey = _mode == 'letters' ? '?123' : 'ABC';

    if (_keys.length < 26) {
      // Pad if fewer keys (unlikely)
      _keys.addAll(List.filled(26 - _keys.length, ''));
    }

    row1 = _keys.sublist(0, 10);
    row2 = _keys.sublist(10, 19); // 9 keys
    row3 = _keys.sublist(19, min(26, _keys.length)); // 7 keys or remaining

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1 (10 keys)
        Row(
          children: row1.map((k) => Expanded(child: _buildKey(k))).toList(),
        ),
        // Row 2 (9 keys, centered with padding)
        Row(
          children: [
            SizedBox(width: MediaQuery.of(context).size.width / 20), // Half-key padding
            ...row2.map((k) => Expanded(child: _buildKey(k))),
            SizedBox(width: MediaQuery.of(context).size.width / 20),
          ],
        ),
        // Row 3 (toggle + 7 keys + backspace)
        Row(
          children: [
            Expanded(child: _buildKey(toggleKey)),
            ...row3.map((k) => Expanded(child: _buildKey(k))),
            Expanded(child: _buildKey('⌫')),
          ],
        ),
        // Bottom row (shift/comma/space/period/enter, with wider space)
        Container(
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Expanded(child: _buildKey('⇧')),
              Expanded(child: _buildKey(',')),
              Expanded(flex: 5, child: _buildKey('␣')),
              Expanded(child: _buildKey('.')),
              Expanded(child: _buildKey('⏎')),
            ],
          ),
        ),
      ],
    );
  }

  void _switchToAlphabetOnly() {
    setState(() {
      _mode = 'letters';
      _resetKeys();
    });
  }

  void _switchToFullMode() {
    setState(() {
      _mode = 'numbers';
      _resetKeys();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildTopControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: _switchToAlphabetOnly,
            child: Text('Letters'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _switchToFullMode,
            child: Text('Numbers/Symbols'),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            onPressed: _resetTest,
            child: Text('New Test'),
          ),
          SizedBox(width: 8),
          Text('Caps: ${_caps ? "ON" : "OFF"}'),
          Spacer(),
          Text('Mode: $_mode'),
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
            // Top controls and text field stuck to the top
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
                  _focusNode.requestFocus();
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Test Sentence: $_currentSentence',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            // Spacer to push keyboard to the bottom
            Expanded(child: SizedBox()),
            // Keyboard stuck to the bottom
            Container(
              color: Colors.grey.shade100, // Optional background for keyboard area
              child: _buildKeyboard(),
            ),
          ],
        ),
      ),
    );
  }
}
