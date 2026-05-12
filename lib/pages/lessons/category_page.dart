import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/pages/lessons/lessons_page.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:lingsix/utils/responsive.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  final List<String> categories = const ["ah", "ee", "m", "oo", "s", "sh"];

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('lesson')),
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
                          "เลือกหมวด",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.blue800),
                        ),
                        const Spacer(),
                        SizedBox(width: r.spacing(48)),
                      ],
                    ),
                  ),

                  /// 🔸 GRID
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = r.isTablet ? 3 : 2;
                        final spacing = r.spacing(r.isTablet ? 14 : 12);
                        final padding = r.spacing(r.isTablet ? 20 : 16);
                        final rows = (categories.length / crossAxisCount)
                            .ceil();
                        final availableHeight =
                            constraints.maxHeight -
                            (padding * 2) -
                            spacing * (rows - 1);
                        final rawRowHeight = availableHeight / rows;
                        final rowHeight =
                            rawRowHeight.isFinite && rawRowHeight > 0
                            ? rawRowHeight
                            : r.spacing(120);

                        List<Widget> rowWidgets = [];
                        for (var row = 0; row < rows; row++) {
                          final rowChildren = <Widget>[];
                          for (var col = 0; col < crossAxisCount; col++) {
                            final index = row * crossAxisCount + col;
                            if (index >= categories.length) {
                              rowChildren.add(
                                const Expanded(child: SizedBox()),
                              );
                            } else {
                              final category = categories[index];
                              rowChildren.add(
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              LessonsPage(category: category),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          r.spacing(24),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: r.spacing(6),
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          category.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: r.text(28),
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blue800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (col != crossAxisCount - 1) {
                              rowChildren.add(SizedBox(width: spacing));
                            }
                          }

                          rowWidgets.add(
                            SizedBox(
                              height: rowHeight,
                              child: Row(children: rowChildren),
                            ),
                          );

                          if (row != rows - 1) {
                            rowWidgets.add(SizedBox(height: spacing));
                          }
                        }

                        return Padding(
                          padding: EdgeInsets.all(padding),
                          child: Column(children: rowWidgets),
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
