import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:lingsix/pages/lessons/category_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:lingsix/pages/lessons/category_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {

  bool _popupShown = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );

    // ✅ Show popup AFTER page rendered (no lag)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showReminderPopup();
    });
  }

  void _showReminderPopup() {
    if (_popupShown) return;
    _popupShown = true;

    _controller.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(80),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _ReminderPopup(controller: _controller),
        );
      },
    );

    // auto close after 7 sec
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ ONLY ONE BUILD METHOD (this was your main bug)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('home')),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final layout =
                            _HomeLayout.fromConstraints(constraints);
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: layout.horizontalPadding,
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: layout.topSpacing),
                              _buildWelcomeSection(
                                context,
                                logoSize: layout.logoSize,
                              ),
                              SizedBox(height: layout.sectionSpacing),
                              _buildFeatureCards(context, layout),
                              SizedBox(height: layout.bottomSpacing),
                            ],
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

  

  /// Top Navigation Bar with Settings, Help, and Profile
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Settings Button
          _buildIconButton(
            icon: Icons.settings,
            tooltip: 'การตั้งค่า',
            onPressed: () => Navigator.pushNamed(context, AppRouter.soundSettings),
          ),
          
          const Spacer(),
          
          // Help/Guide Button
          _buildIconButton(
            icon: Icons.help_outline,
            tooltip: 'คู่มือการใช้งาน',
            onPressed: () => _showGuideDialog(context),
          ),
          
          const SizedBox(width: 8),
          
          // Profile Button
          _buildIconButton(
            icon: Icons.account_circle,
            tooltip: 'โปรไฟล์',
            onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: AppColors.blue800, size: 28),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  /// Welcome Section with Logo/Title
  Widget _buildWelcomeSection(BuildContext context, {required double logoSize}) {
    return Column(
      children: [
        // App Logo
        Image.asset(
          'assets/common/logo/app_logo.png',
          width: logoSize,
          height: logoSize,
        ),
      ],
    );
  }

  /// Main Feature Cards Grid
  Widget _buildFeatureCards(BuildContext context, _HomeLayout layout) {
    return Column(
      children: [
        // Row 1: Lessons
        _buildFeatureCard(
          context: context,
          imageAsset: 'assets/common/illustrations/home/learn.png',
          title: 'บทเรียน',
          backgroundColor: const Color(0xFFBB240A),
          height: layout.cardHeight,
          iconSize: layout.iconSize,
          titleFontSize: layout.titleFontSize,
          arrowSize: layout.arrowSize,
          padding: layout.cardPadding,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPage(),
            ),
          ),
        ),

        SizedBox(height: layout.cardSpacing),

        // Row 2: Quiz
        _buildFeatureCard(
          context: context,
          imageAsset: 'assets/common/illustrations/home/quiz.png',
          title: 'ทดสอบ',
          backgroundColor: const Color(0xFFEDCC4D),
          height: layout.cardHeight,
          iconSize: layout.iconSize,
          titleFontSize: layout.titleFontSize,
          arrowSize: layout.arrowSize,
          padding: layout.cardPadding,
          onTap: () => Navigator.pushNamed(context, AppRouter.quiz),
        ),

        SizedBox(height: layout.cardSpacing),

        // Row 3: Result
        _buildFeatureCard(
          context: context,
          imageAsset: 'assets/common/illustrations/home/result.png',
          title: 'ผลการทดสอบ',
          backgroundColor: const Color(0xFF016FBA),
          height: layout.cardHeight,
          iconSize: layout.iconSize,
          titleFontSize: layout.titleFontSize,
          arrowSize: layout.arrowSize,
          padding: layout.cardPadding,
          onTap: () => Navigator.pushNamed(context, AppRouter.dashboard),
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String imageAsset,
    required String title,
    required Color backgroundColor,
    required VoidCallback onTap,
    required double height,
    required double iconSize,
    required double titleFontSize,
    required double arrowSize,
    required double padding,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withAlpha(100),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Row(
                children: [
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: AppColors.gray550,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withAlpha(220),
                    size: arrowSize,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Show Guide Dialog
  void _showGuideDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(102),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          constraints: const BoxConstraints(maxWidth: 360),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header - Icon and Title
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.blue600.withAlpha(26), AppColors.blue500.withAlpha(13)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: AppColors.blue600,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'คู่มือการใช้งาน',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'เรียนรู้วิธีการใช้งานแอปพลิเคชัน',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray550,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Guide Items as Cards
                _buildGuideCard(
                  imagePath: 'assets/common/illustrations/home/learn.png',
                  title: 'บทเรียน',
                  description: 'ฝึกฟังและทำความรู้จักเสียงต่าง ๆ',
                  accentColor: AppColors.blue600,
                ),
                const SizedBox(height: 10),
                _buildGuideCard(
                  imagePath: 'assets/common/illustrations/home/quiz.png',
                  title: 'แบบทดสอบ',
                  description: 'ทดสอบความรู้ผ่านแบบทดสอบที่หลากหลาย',
                  accentColor: AppColors.yellow600,
                ),
                const SizedBox(height: 10),
                _buildGuideCard(
                  imagePath: 'assets/common/illustrations/home/result.png',
                  title: 'ผลการทดสอบ',
                  description: 'ดูสถิติและความก้าวหน้าของคุณ',
                  accentColor: AppColors.blue500,
                ),
                const SizedBox(height: 10),
                _buildGuideCard(
                  icon: Icons.settings,
                  title: 'การตั้งค่า',
                  description: 'ปรับและล็อคระดับเสียงตามความต้องการ',
                  accentColor: AppColors.yellow500,
                ),
                
                const SizedBox(height: 20),
                
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'เข้าใจแล้ว',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    String? imagePath,
    IconData? icon,
    required String title,
    required String description,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withAlpha(20),
            accentColor.withAlpha(8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withAlpha(38),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: imagePath != null ? Colors.white : accentColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withAlpha(51),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.blue800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray550,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


class _HomeLayout {
  final double horizontalPadding;
  final double topSpacing;
  final double sectionSpacing;
  final double cardSpacing;
  final double bottomSpacing;
  final double logoSize;
  final double cardHeight;
  final double cardPadding;
  final double iconSize;
  final double titleFontSize;
  final double arrowSize;

  const _HomeLayout({
    required this.horizontalPadding,
    required this.topSpacing,
    required this.sectionSpacing,
    required this.cardSpacing,
    required this.bottomSpacing,
    required this.logoSize,
    required this.cardHeight,
    required this.cardPadding,
    required this.iconSize,
    required this.titleFontSize,
    required this.arrowSize,
  });

  factory _HomeLayout.fromConstraints(BoxConstraints constraints) {
    const baseLogoSize = 220.0;
    const baseCardHeight = 96.0;
    const baseTopSpacing = 16.0;
    const baseSectionSpacing = 28.0;
    const baseCardSpacing = 12.0;
    const baseBottomSpacing = 16.0;
    const baseCardPadding = 12.0;
    const baseIconSize = 56.0;
    const baseTitleFontSize = 20.0;
    const baseArrowSize = 20.0;
    const maxScale = 1.15;

    final maxHeight = constraints.maxHeight;
    final maxWidth = constraints.maxWidth;
    final baseTotal = baseTopSpacing +
        baseLogoSize +
        baseSectionSpacing +
        (baseCardHeight * 3) +
        (baseCardSpacing * 2) +
        baseBottomSpacing;

    final scale = baseTotal > 0 ? maxHeight / baseTotal : 1.0;
    final effectiveScale = scale > maxScale ? maxScale : scale;

    return _HomeLayout(
      horizontalPadding: (maxWidth * 0.06).clamp(16.0, 32.0),
      topSpacing: baseTopSpacing * effectiveScale,
      sectionSpacing: baseSectionSpacing * effectiveScale,
      cardSpacing: baseCardSpacing * effectiveScale,
      bottomSpacing: baseBottomSpacing * effectiveScale,
      logoSize: baseLogoSize * effectiveScale,
      cardHeight: baseCardHeight * effectiveScale,
      cardPadding: baseCardPadding * effectiveScale,
      iconSize: baseIconSize * effectiveScale,
      titleFontSize: baseTitleFontSize * effectiveScale,
      arrowSize: baseArrowSize * effectiveScale,
    );
  }
}

class _ReminderPopup extends StatelessWidget {
  final AnimationController controller;

  const _ReminderPopup({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// 🔔 ICON + TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5E5), // soft red bg
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Color(0xFFD64545), // red muted
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "คำแนะนำ",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB23A3A), // darker red
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            /// 📌 MESSAGE
            const Text(
              "อย่าลืมตั้งค่าเสียงก่อนเริ่มแบบทดสอบทุกครั้งน้า",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            /// 🔴 PROGRESS BAR (RED SOFT)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      // background
                      Container(
                        height: 10,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),

                      // animated fill
                      FractionallySizedBox(
                        widthFactor: 1 - controller.value,
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF6B6B), // soft red
                                Color(0xFFD64545), // deeper muted red
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            /// ⏱ OPTIONAL TEXT (UX เพิ่ม clarity)
            AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final secondsLeft = (7 * (1 - controller.value)).ceil();
                return Text(
                  "ปิดอัตโนมัติใน $secondsLeft วินาที",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}