import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/app/router.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:lingsix/pages/lessons/category_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
              // Top Navigation Bar
              _buildTopBar(context),
              
              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      
                      // Welcome Section
                      _buildWelcomeSection(context),
                      
                      const SizedBox(height: 40),
                      
                      // Main Feature Cards
                      _buildFeatureCards(context),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
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
  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        // App Logo
        Image.asset(
          'assets/common/logo/app_logo.png',
          width: 300,
          height: 300,
        ),
      ],
    );
  }

  /// Main Feature Cards Grid
  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        // Row 1: Lessons
        _buildFeatureCard(
          context: context,
          imageAsset: 'assets/common/illustrations/home/learn.png',
          title: 'บทเรียน',
          backgroundColor: const Color(0xFFBB240A),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CategoryPage(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Row 2: Quiz
        _buildFeatureCard(
          context: context,
          imageAsset: 'assets/common/illustrations/home/quiz.png',
          title: 'ทดสอบ',
          backgroundColor: const Color(0xFFEDCC4D),
          onTap: () => Navigator.pushNamed(context, AppRouter.quiz),
        ),

        const SizedBox(height: 16),

        // Row 3: Result
        _buildFeatureCard(
          context: context,
          imageAsset: 'assets/common/illustrations/home/result.png',
          title: 'ผลการทดสอบ',
          backgroundColor: const Color(0xFF016FBA),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
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
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Image.asset(
                      imageAsset,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
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
                    size: 20,
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
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blue100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: AppColors.blue600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'คู่มือการใช้งาน',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.blue800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              
              // Guide Items
              _buildGuideItem(
                icon: Icons.menu_book,
                title: 'บทเรียน',
                description: 'ฝึกฟังและทำความรู้จักเสียงต่าง ๆ',
              ),
              _buildGuideItem(
                icon: Icons.quiz,
                title: 'แบบทดสอบ',
                description: 'ทดสอบความรู้ผ่านแบบทดสอบที่หลากหลาย',
              ),
              _buildGuideItem(
                icon: Icons.bar_chart,
                title: 'ผลการทดสอบ',
                description: 'ดูสถิติและความก้าวหน้าของคุณ',
              ),
              _buildGuideItem(
                icon: Icons.settings,
                title: 'การตั้งค่า',
                description: 'ปรับและล็อคระดับเสียงตามความต้องการ',
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'เข้าใจแล้ว',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.blue600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.blue800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray550,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
