import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const LebenInDeutschlandApp());
}

class LebenInDeutschlandApp extends StatefulWidget {
  const LebenInDeutschlandApp({Key? key}) : super(key: key);

  @override
  State<LebenInDeutschlandApp> createState() => _LebenInDeutschlandAppState();
}

class _LebenInDeutschlandAppState extends State<LebenInDeutschlandApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leben in Deutschland',
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: HomePage(onToggleTheme: toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  final void Function(bool) onToggleTheme;
  const HomePage({Key? key, required this.onToggleTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Leben in Deutschland"),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () => onToggleTheme(!isDarkMode),
            tooltip: isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTile(context, Icons.quiz, "Practice All 300 Questions", () {
            Navigator.push(context, _fadeRoute(PracticeOptionsPage()));
            }),
            _buildTile(context, Icons.map, "State-wise Questions", () {
              Navigator.push(context, _fadeRoute(SelectBundeslandPage()));
            }),
            _buildTile(context, Icons.bookmark, "Review Marked Questions", () {
              Navigator.push(context, _fadeRoute(QuizPage(showOnlyMarked: true)));
            }),
            _buildTile(context, Icons.topic, "Topic-wise Questions", () {
              Navigator.push(context, _fadeRoute(TopicCategoryPage()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 30),
          title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }

  PageRouteBuilder _fadeRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
class PracticeOptionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Practice All Questions")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: Icon(Icons.replay),
              label: Text("Start from Beginning"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => QuizPage(),
                ));
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.play_arrow),
              label: Text("Continue from Last"),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => QuizPage(resumeFromLast: true),
                ));
              },
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

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  Set<String> markedQuestions = {};

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

  final Map<int, String> topicImages = {
  21: 'assets/img/021.png',
  55: 'assets/img/055.png',
  70: 'assets/img/070.png',
  130: 'assets/img/130.png',
  176: 'assets/img/176.png',
  181: 'assets/img/181.png',
  187: 'assets/img/187.png',
  209: 'assets/img/209.png',
  216: 'assets/img/216.png',
  226: 'assets/img/226.png',
  235: 'assets/img/235.png',
};

  Map<String, Map<int, String>> imageMapping = {};

  @override
  void initState() {
    super.initState();
    buildImageMapping();
    loadQuestions();
    _loadBannerAd();
    _loadInterstitialAd();
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

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isBannerAdReady = true),
        onAdFailedToLoad: (ad, error) {
          print('Banner Ad failed: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
      _loadInterstitialAd();
    }
  }

  Future<void> loadQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    markedQuestions = (prefs.getStringList('marked') ?? []).toSet();

    if (widget.overrideQuestions != null) {
      questions = widget.overrideQuestions!;
    } else {
      final path = widget.customPath ?? 'assets/questions.json';
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      allQuestions = jsonMap.entries.map((e) => Question.fromJson(e.value)).toList();

      if (widget.showOnlyMarked) {
        questions = allQuestions.where((q) => markedQuestions.contains(q.text)).toList();
      } else {
        questions = allQuestions;
      }

      if (widget.resumeFromLast && !widget.showOnlyMarked) {
        currentIndex = prefs.getInt('lastIndex') ?? 0;
      }
    }

    setState(() {});
  }

void previousQuestion() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('lastIndex', (currentIndex - 1).clamp(0, questions.length - 1));
  setState(() {
    currentIndex = (currentIndex - 1).clamp(0, questions.length - 1);
    selectedOption = null;
    showAnswer = false;
  });
}

  void nextQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastIndex', currentIndex + 1);

    if ((currentIndex + 1) % 5 == 0) _showInterstitialAd();

    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
      selectedOption = null;
      showAnswer = false;
    });
  }

  Future<void> toggleMarkQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    final questionText = questions[currentIndex].text;

    if (markedQuestions.contains(questionText)) {
      markedQuestions.remove(questionText);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question removed from review')),
      );
    } else {
      markedQuestions.add(questionText);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Question marked for review')),
      );
    }

    await prefs.setStringList('marked', markedQuestions.toList());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Leben in Deutschland Quiz')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final question = questions[currentIndex];
    final questionNumber = currentIndex + 1;
    final isMarked = markedQuestions.contains(question.text);

    String? imagePath;
    if (widget.customPath != null &&
        imageMapping.containsKey(widget.customPath) &&
        (questionNumber == 1 || questionNumber == 8)) {
      imagePath = imageMapping[widget.customPath]?[questionNumber];
    }

    if (imagePath == null) {
    imagePath = topicImages[questionNumber];
    }

    return Scaffold(
      appBar: AppBar(title: Text('Leben in Deutschland Quiz')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
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
                          });
                        },
                      ),
                    );
                  }),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: Icon(isMarked ? Icons.bookmark_remove : Icons.bookmark_add),
                    label: Text(isMarked ? "Remove from Review" : "Mark for Review"),
                    onPressed: toggleMarkQuestion,
                  ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: currentIndex > 0 ? previousQuestion : null,
                        child: Text("Previous Question"),
                      ),
                      ElevatedButton(
                        onPressed: showAnswer ? nextQuestion : null,
                        child: Text("Next Question"),
                      ),
                    ],
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
