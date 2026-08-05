import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GoogleSheetQuizScreen(),
    );
  }
}

class GoogleSheetQuizScreen extends StatefulWidget {
  const GoogleSheetQuizScreen({super.key});

  @override
  State<GoogleSheetQuizScreen> createState() => _GoogleSheetQuizScreenState();
}

class _GoogleSheetQuizScreenState extends State<GoogleSheetQuizScreen> {
  List<dynamic> questions = [];
  int questionIndex = 0;
  int score = 0;
  bool isLoading = true;

  // உங்கள் Google Sheet ID
  final String sheetId = '1jhxPyuVN82Yo2rZn1zoQ8cJXjihxsxL7_ZzEZu-ZN0c';

  @override
  void initState() {
    super.initState();
    fetchQuestionsFromGoogleSheet();
  }

  Future<void> fetchQuestionsFromGoogleSheet() async {
    final url =
        'https://docs.google.com/spreadsheets/d/$sheetId/gviz/tq?tqx=out:csv';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // CSV வரிகளாகப் பிரிக்கிறோம்
        List<String> lines = const LineSplitter().convert(response.body);
        List<dynamic> loadedQuestions = [];

        // Header தவிர்த்து முதல் வரியிலிருந்து படிக்கிறோம் (i = 1)
        for (int i = 1; i < lines.length; i++) {
          if (lines[i].trim().isEmpty) continue;

          // CSV Comma Splitting
          RegExp exp = RegExp(r'(?:^|,)(?:"([^"]*)"|([^,]*))');
          Iterable<Match> matches = exp.allMatches(lines[i]);
          List<String> row = [];

          for (Match match in matches) {
            String val = match.group(1) ?? match.group(2) ?? '';
            row.add(val.replaceAll('"', '').trim());
          }

          if (row.length >= 6) {
            loadedQuestions.add({
              'question': row[0],
              'answers': [row[1], row[2], row[3], row[4]],
              'correctAnswer': row[5],
            });
          }
        }

        setState(() {
          questions = loadedQuestions;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Sheet data: $e");
    }
  }

  void answerQuestion(String selectedAnswer) {
    if (selectedAnswer == questions[questionIndex]['correctAnswer']) {
      score++;
    }
    setState(() {
      questionIndex++;
    });
  }

  void resetQuiz() {
    setState(() {
      questionIndex = 0;
      score = 0;
      isLoading = true;
    });
    fetchQuestionsFromGoogleSheet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Quiz App'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 15),
                  Text('Google Sheet-லிருந்து கேள்விகள் லோட் ஆகின்றன...'),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: questionIndex < questions.length
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'கேள்வி ${questionIndex + 1} / ${questions.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          questions[questionIndex]['question'] ?? '',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ...(questions[questionIndex]['answers']
                                as List<dynamic>)
                            .map((answer) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6.0,
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(15),
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () =>
                                      answerQuestion(answer.toString()),
                                  child: Text(
                                    answer.toString(),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              );
                            }),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'வாழ்த்துகள்! Quiz முடிந்தது 🎉',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            'உங்கள் மதிப்பெண்: $score / ${questions.length}',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: resetQuiz,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('மீண்டும் தொடங்கவும்'),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
