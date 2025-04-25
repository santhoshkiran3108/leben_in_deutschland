import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(LebenInDeutschlandApp());
}

class LebenInDeutschlandApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leben in Deutschland',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Leben in Deutschland")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizPage()),
                );
              },
              child: Text("Practice All 300 Questions"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizPage(resumeFromLast: true)),
                );
              },
              child: Text("Continue Quiz"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SelectBundeslandPage()),
                );
              },
              child: Text("State-wise Questions"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuizPage(showOnlyMarked: true)),
                );
              },
              child: Text("Review Marked Questions"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TopicCategoryPage()),
                );
              },
              child: Text("Topic-wise Questions"),
            ),
          ],
        ),
      ),
    );
  }
}

class TopicCategoryPage extends StatefulWidget {
  @override
  _TopicCategoryPageState createState() => _TopicCategoryPageState();
}

class _TopicCategoryPageState extends State<TopicCategoryPage> {
  Map<String, List<int>> topics = {};

  @override
  void initState() {
    super.initState();
    loadTopics();
  }

  Future<void> loadTopics() async {
    final String jsonString = await rootBundle.loadString('assets/topic.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    final parsed = jsonMap.map((key, value) => MapEntry(key, List<int>.from(value)));
    setState(() {
      topics = parsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Topic")),
      body: topics.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: topics.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      final String jsonString = await rootBundle.loadString('assets/questions.json');
                      final Map<String, dynamic> jsonMap = json.decode(jsonString);
                      final allQuestions = jsonMap.entries.map((e) => Question.fromJson(e.value)).toList();
                      final filtered = <Question>[];
                      for (var i = 0; i < allQuestions.length; i++) {
                        if (entry.value.contains(i + 1)) {
                          filtered.add(allQuestions[i]);
                        }
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(overrideQuestions: filtered),
                        ),
                      );
                    },
                    child: Text(entry.key),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
class SelectBundeslandPage extends StatelessWidget {
  final List<String> bundeslaender = [
    'Baden-Württemberg', 'Bayern', 'Berlin', 'Brandenburg', 'Bremen', 'Hamburg',
    'Hessen', 'Mecklenburg-Vorpommern', 'Niedersachsen', 'Nordrhein-Westfalen',
    'Rheinland-Pfalz', 'Saarland', 'Sachsen', 'Sachsen-Anhalt',
    'Schleswig-Holstein', 'Thüringen'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bundesland auswählen")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bundeslaender.length,
        itemBuilder: (context, index) {
          final name = bundeslaender[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ElevatedButton(
              onPressed: () {
                final path = 'assets/Bundesland/${name.replaceAll(' ', '-')}.json';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizPage(customPath: path),
                  ),
                );
              },
              child: Text(name),
            ),
          );
        },
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final bool showOnlyMarked;
  final bool resumeFromLast;
  final String? customPath;
  final List<Question>? overrideQuestions;

  QuizPage({
    this.showOnlyMarked = false,
    this.resumeFromLast = false,
    this.customPath,
    this.overrideQuestions,
  });

  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  List<Question> allQuestions = [];
  List<Question> questions = [];
  int currentIndex = 0;
  int? selectedOption;
  bool showAnswer = false;

  late BannerAd _bannerAd;
  bool _isBannerAdReady = false;

  final List<String> imageFiles = [
    'assets/img/301.png', 'assets/img/308.png', 'assets/img/311.png', 'assets/img/318.png',
    'assets/img/321.png', 'assets/img/328.png', 'assets/img/331.png', 'assets/img/338.png',
    'assets/img/341.png', 'assets/img/348.png', 'assets/img/351.png', 'assets/img/358.png',
    'assets/img/361.png', 'assets/img/368.png', 'assets/img/371.png', 'assets/img/378.png',
    'assets/img/381.png', 'assets/img/388.png', 'assets/img/391.png', 'assets/img/398.png',
    'assets/img/401.png', 'assets/img/408.png', 'assets/img/411.png', 'assets/img/418.png',
    'assets/img/421.png', 'assets/img/428.png', 'assets/img/431.png', 'assets/img/438.png',
    'assets/img/441.png', 'assets/img/448.png', 'assets/img/451.png', 'assets/img/458.png',
  ];

  Map<String, Map<int, String>> imageMapping = {};

  @override
  void initState() {
    super.initState();
    buildImageMapping();
    loadQuestions();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Ad Unit
      request: AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdReady = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  void buildImageMapping() {
    final List<String> bundeslandFiles = [
      'assets/Bundesland/Baden-Württemberg.json', 'assets/Bundesland/Bayern.json',
      'assets/Bundesland/Berlin.json', 'assets/Bundesland/Brandenburg.json',
      'assets/Bundesland/Bremen.json', 'assets/Bundesland/Hamburg.json',
      'assets/Bundesland/Hessen.json', 'assets/Bundesland/Mecklenburg-Vorpommern.json',
      'assets/Bundesland/Niedersachsen.json', 'assets/Bundesland/Nordrhein-Westfalen.json',
      'assets/Bundesland/Rheinland-Pfalz.json', 'assets/Bundesland/Saarland.json',
      'assets/Bundesland/Sachsen.json', 'assets/Bundesland/Sachsen-Anhalt.json',
      'assets/Bundesland/Schleswig-Holstein.json', 'assets/Bundesland/Thüringen.json',
    ];
    for (int i = 0; i < bundeslandFiles.length; i++) {
      if (i * 2 + 1 >= imageFiles.length) break;
      imageMapping[bundeslandFiles[i]] = {
        1: imageFiles[i * 2],
        8: imageFiles[i * 2 + 1],
      };
    }
  }

  Future<void> loadQuestions() async {
  if (widget.overrideQuestions != null) {
    questions = widget.overrideQuestions!;
    setState(() {});
    return;
  }

  final path = widget.customPath ?? 'assets/questions.json';
  final String jsonString = await rootBundle.loadString(path);
  final Map<String, dynamic> jsonMap = json.decode(jsonString);
  allQuestions = jsonMap.entries.map((entry) {
    return Question.fromJson(entry.value);
  }).toList();

  if (widget.showOnlyMarked) {
    final prefs = await SharedPreferences.getInstance();
    final markedTexts = prefs.getStringList('marked') ?? [];
    questions = allQuestions.where((q) => markedTexts.contains(q.text)).toList();
  } else {
    questions = allQuestions;
  }

  if (widget.resumeFromLast && !widget.showOnlyMarked) {
    await loadProgress();
  }

  setState(() {});
}
  void nextQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastIndex', currentIndex + 1);
    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
      selectedOption = null;
      showAnswer = false;
    });
  }

  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIndex = prefs.getInt('lastIndex') ?? 0;
    setState(() {
      currentIndex = savedIndex;
    });
  }

  void markQuestion() async {
    final question = questions[currentIndex];
    final prefs = await SharedPreferences.getInstance();
    List<String> saved = prefs.getStringList('marked') ?? [];
    if (!saved.contains(question.text)) {
      saved.add(question.text);
      await prefs.setStringList('marked', saved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Frage markiert zum Wiederholen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Leben in Deutschland Quiz")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final question = questions[currentIndex];
    final int questionNumber = currentIndex + 1;
    String? imagePath;
    if (widget.customPath != null &&
        imageMapping.containsKey(widget.customPath) &&
        (questionNumber == 1 || questionNumber == 8)) {
      imagePath = imageMapping[widget.customPath]?[questionNumber];
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Leben in Deutschland Quiz"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Frage $questionNumber von ${questions.length}",
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    question.text,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  if (imagePath != null) ...[
                    SizedBox(height: 16),
                    Image.asset(imagePath, height: 200, fit: BoxFit.contain),
                  ],
                  SizedBox(height: 24),
                  ...List.generate(question.options.length, (index) {
                    final isCorrect = index == question.correctAnswerIndex;
                    final isSelected = selectedOption == index;
                    Color? optionColor;
                    if (showAnswer && isSelected) {
                      optionColor = isCorrect ? Colors.green : Colors.red;
                    }
                    return Card(
                      color: optionColor,
                      child: ListTile(
                        title: Text(question.options[index]),
                        onTap: () {
                          if (showAnswer) return;
                          setState(() {
                            selectedOption = index;
                            showAnswer = true;
                            if (!isCorrect) markQuestion();
                          });
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: showAnswer ? nextQuestion : null,
                    child: Text("Nächste Frage"),
                  ),
                ],
              ),
            ),
          ),
          if (_isBannerAdReady)
            Container(
              height: _bannerAd.size.height.toDouble(),
              width: _bannerAd.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd),
            ),
        ],
      ),
    );
  }
}

class Question {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  Question({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final optionsMap = json['options'] as Map<String, dynamic>;
    final correctAnswerMap = json['correct_answer'] as Map<String, dynamic>;
    final optionKeys = ['A', 'B', 'C', 'D'];
    final optionList = optionKeys.map((k) => (optionsMap[k] ?? '').toString()).toList();
    final correctKey = correctAnswerMap.keys.first;
    final correctIndex = optionKeys.indexOf(correctKey);
    return Question(
      text: json['question'],
      options: optionList,
      correctAnswerIndex: correctIndex,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Question &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          options.toString() == other.options.toString();

  @override
  int get hashCode => text.hashCode ^ options.hashCode;
}
