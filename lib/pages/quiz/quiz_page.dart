import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/pages/quiz/quiz_questions_page.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:lingsix/utils/responsive.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  static final List<Map<String, dynamic>> quizzes = List.generate(5, (index) {
    return {
      "quizId": "quiz_${index + 1}",
      "title": "แบบทดสอบที่ ${index + 1}",
      "topic": "LingSix Sound",
    };
  });

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('quiz')),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  /// 🔹 HEADER with Back Button
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: r.spacing(24),
                      vertical: r.spacing(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.arrow_back,
                            size: r.icon(30),
                            color: AppColors.blue800,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Text(
                          "แบบทดสอบ",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.blue800),
                        ),
                        const Spacer(),
                        SizedBox(width: r.spacing(48)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: r.pagePadding(horizontal: 20, vertical: 8),
                      itemCount: quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = quizzes[index];
                        return Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: r.contentMaxWidth(
                                phone: 520,
                                tablet: 720,
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QuizQuestionsPage(
                                      quizId: quiz["quizId"],
                                      title: quiz["title"],
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: EdgeInsets.only(bottom: r.spacing(16)),
                                padding: EdgeInsets.all(r.spacing(20)),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(230),
                                  borderRadius: BorderRadius.circular(
                                    r.spacing(16),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.quiz, size: r.icon(40)),
                                    SizedBox(width: r.spacing(16)),
                                    Text(
                                      quiz["title"],
                                      style: TextStyle(
                                        fontSize: r.text(18),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.blue800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
