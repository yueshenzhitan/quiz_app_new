import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const QuizApp());

class Question {
  final int id;
  final String type; // 'single', 'multiple', 'true_false'
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  Question({
    required this.id,
    required this.type,
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      type: json['type'],
      question: json['question'],
      options: List<String>.from(json['options'] ?? []),
      answer: json['answer'],
      explanation: json['explanation'],
    );
  }
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '技能大赛刷题',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const QuizHome(),
    );
  }
}

class QuizHome extends StatefulWidget {
  const QuizHome({super.key});

  @override
  State<QuizHome> createState() => _QuizHomeState();
}

class _QuizHomeState extends State<QuizHome> {
  late Future<List<Question>> _questionsFuture;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _loadQuestions();
  }

  Future<List<Question>> _loadQuestions() async {
    final jsonString = await rootBundle.loadString('assets/questions.json');
    final jsonList = json.decode(jsonString) as List;
    return jsonList.map((e) => Question.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('技能大赛刷题 App')),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          } else {
            final questions = snapshot.data!;
            return ListView.builder(
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                String typeText = '';
                if (q.type == 'single') typeText = '【单选】';
                else if (q.type == 'multiple') typeText = '【多选】';
                else if (q.type == 'true_false') typeText = '【判断】';

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text('${index + 1}. ${q.question}'),
                    subtitle: Text(typeText),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuestionDetail(question: q),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

class QuestionDetail extends StatefulWidget {
  final Question question;

  const QuestionDetail({super.key, required this.question});

  @override
  State<QuestionDetail> createState() => _QuestionDetailState();
}

class _QuestionDetailState extends State<QuestionDetail> {
  Set<String> _selected = {};
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;

    Widget optionsWidget;
    if (q.type == 'true_false') {
      optionsWidget = Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButton('正确', '正确'),
          _buildButton('错误', '错误'),
        ],
      );
    } else {
      optionsWidget = Wrap(
        spacing: 8,
        runSpacing: 8,
        children: List.generate(q.options.length, (i) {
          String label = String.fromCharCode('A'.codeUnitAt(0) + i);
          return _buildButton('$label. ${q.options[i]}', label);
        }),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('题目详情')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.question, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            optionsWidget,
            const SizedBox(height: 30),
            if (_showAnswer) ...[
              const Text('✅ 正确答案：', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(q.answer),
              if (q.explanation.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('📝 解析：', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(q.explanation),
              ],
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _showAnswer = !_showAnswer;
                  });
                },
                child: Text(_showAnswer ? '隐藏答案' : '查看答案'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String text, String value) {
    bool isSelected = _selected.contains(value);
    Color color = isSelected ? Colors.blue : Colors.grey;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(side: BorderSide(color: color)),
      onPressed: () {
        setState(() {
          if (_selected.contains(value)) {
            _selected.remove(value);
          } else {
            if (widget.question.type == 'true_false') {
              _selected = {value};
            } else {
              _selected.add(value);
            }
          }
        });
      },
      child: Text(text),
    );
  }
}
