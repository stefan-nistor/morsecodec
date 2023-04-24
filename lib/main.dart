import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms/flutter_sms_web.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_sms/flutter_sms.dart';

const platform = MethodChannel("morsecodec.com/led_control");

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morse codec',
      home: InputPage(),
    );
  }
}

class InputPage extends StatefulWidget {
  @override
  _InputPageState createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  TextEditingController _textEditingController = TextEditingController();
  bool isSending = false;
  String encoded = '';
  String decoded = '';

  @override
  void initState(){
    super.initState();
    // TODO: get latest SMS
    retreiveSms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Morse codec'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                    hintText: 'Enter some text',
                    suffixIcon: IconButton(
                      onPressed:_textEditingController.clear ,
                      icon: const Icon(Icons.clear),
                    )),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    encoded = textToMorse(_textEditingController.text);
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Encoded Morse string'),
                              content: Text(encoded),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    _sendMorseCode(encoded);
                                  },
                                  child: const Text('Light'),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: encoded),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {
                                      Share.share(encoded);
                                    },
                                    icon: (const Icon(
                                      Icons.share,
                                      color: Colors.blueAccent,
                                    ))),
                              ],
                            ));
                  },
                  child: const Text('Encode'),
                ),
                ElevatedButton(
                  onPressed: () {
                    decoded = morseToText(_textEditingController.text);
                    showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                              title: const Text('Decoded Morse string'),
                              content: Text(decoded),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Ok'),
                                ),
                                IconButton(
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(text: encoded),
                                    );
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(
                                    Icons.copy_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ));
                  },
                  child: const Text('Decode'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Do something else with the text
                    _sendMorseCode(encoded);
                  },
                  child: const Text('Light'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMorseCode(String morseCode) async {
    try {
      setState(() {
        isSending = true;
      });
      await platform.invokeMethod(
          'sendMorseCode', <String, dynamic>{"morseCode": morseCode});
    } on PlatformException catch (e) {
      print('Error: ${e.message}');
    } finally {
      setState(() {
        isSending = false;
      });
    }
  }

  Future<void> retreiveSms() async {
    List<SmsMessage> message = await listSms(address: null, count: 1);
    SmsMessage latestMessage = messages.first;
    String? morseCode = extractMorseCode(latestMessage.body);

    setState(() {
      _textEditingController.text = morseCode!;
    });
  }

}

final Map<String, String> toMorseCode = {
  'A': '.-',
  'B': '-...',
  'C': '-.-.',
  'D': '-..',
  'E': '.',
  'F': '..-.',
  'G': '--.',
  'H': '....',
  'I': '..',
  'J': '.---',
  'K': '-.-',
  'L': '.-..',
  'M': '--',
  'N': '-.',
  'O': '---',
  'P': '.--.',
  'Q': '--.-',
  'R': '.-.',
  'S': '...',
  'T': '-',
  'U': '..-',
  'V': '...-',
  'W': '.--',
  'X': '-..-',
  'Y': '-.--',
  'Z': '--..',
  '0': '-----',
  '1': '.----',
  '2': '..---',
  '3': '...--',
  '4': '....-',
  '5': '.....',
  '6': '-....',
  '7': '--...',
  '8': '---..',
  '9': '----.',
  ' ': '/'
};

final Map<String, String> fromMorseCode = {
  '.-': 'A',
  '-...': 'B',
  '-.-.': 'C',
  '-..': 'D',
  '.': 'E',
  '..-.': 'F',
  '--.': 'G',
  '....': 'H',
  '..': 'I',
  '.---': 'J',
  '-.-': 'K',
  '.-..': 'L',
  '--': 'M',
  '-.': 'N',
  '---': 'O',
  '.--.': 'P',
  '--.-': 'Q',
  '.-.': 'R',
  '...': 'S',
  '-': 'T',
  '..-': 'U',
  '...-': 'V',
  '.--': 'W',
  '-..-': 'X',
  '-.--': 'Y',
  '--..': 'Z',
  '-----': '0',
  '.----': '1',
  '..---': '2',
  '...--': '3',
  '....-': '4',
  '.....': '5',
  '-....': '6',
  '--...': '7',
  '---..': '8',
  '----.': '9',
  '/': ' '
};

String textToMorse(String text) {
  String result = '';

  for (var i = 0; i < text.length; i++) {
    final char = text[i].toUpperCase();
    final morse = toMorseCode[char];
    if (morse != null) {
      result += '$morse ';
    }
  }
  return result;
}

String morseToText(String morse) {
  String result = '';
  final morseList = morse.split(' ');

  for (var i = 0; i < morseList.length; i++) {
    final char = fromMorseCode[morseList[i]];
    if (char != null) {
      result += char;
    } else if (morseList[i] == '' &&
        i < morseList.length - 1 &&
        morseList[i + 1] == '') {
      // Check for double spaces indicating a word boundary
      result += ' ';
      i++; // Skip the next empty string
    }
  }
  return result;
}

String? extractMorseCode(String text) {
  // Implement your morse code extraction logic here
  // This could involve using regular expressions to extract the morse code from the text
  // You could also use a third-party morse code library to do this
  // For this example, let's assume the morse code is in all caps and enclosed in brackets
  RegExp morseCodeRegExp = RegExp(r'\[([A-Z ]+)\]');
  Match morseCodeMatch = morseCodeRegExp.firstMatch(text) as Match;
  String? morseCode = morseCodeMatch.group(1)?.trim();
  return morseCode;
}
