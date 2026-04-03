import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/app/router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/themes/default/bg/home.png'),
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
      icon: Icon(icon, color: AppColors.blue800),
      iconSize: 40,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }

  /// Welcome Section with Logo/Title
  Widget _buildWelcomeSection(BuildContext context) {
    return Column(
      children: [
        // App Logo or Icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white.withAlpha(200),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.blue600.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.music_note,
            size: 60,
            color: AppColors.blue600,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'LingSix',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 36,
            shadows: [
              Shadow(
                color: AppColors.blue900.withAlpha(150),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'เรียนรู้และพัฒนาทักษะของคุณ',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white.withAlpha(220),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  /// Main Feature Cards Grid
  Widget _buildFeatureCards(BuildContext context) {
    return Column(
      children: [
        // Row 1: Lessons & Quiz
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.menu_book,
                title: 'บทเรียน',
                subtitle: 'เรียนรู้ทฤษฎีดนตรี',
                color: AppColors.blue500,
                gradientColors: [AppColors.blue400, AppColors.blue600],
                onTap: () => Navigator.pushNamed(context, AppRouter.lessons),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFeatureCard(
                context: context,
                icon: Icons.quiz,
                title: 'ทดสอบ',
                subtitle: 'ทดสอบความรู้',
                color: AppColors.yellow500,
                gradientColors: [AppColors.yellow400, AppColors.yellow600],
                onTap: () => Navigator.pushNamed(context, AppRouter.quiz),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Row 2: Dashboard (Full Width)
        _buildFeatureCard(
          context: context,
          icon: Icons.bar_chart,
          title: 'ผลการทดสอบ',
          subtitle: 'ดูความก้าวหน้าและสถิติของคุณ',
          color: AppColors.greenLight,
          gradientColors: [AppColors.greenLight, AppColors.success],
          onTap: () => Navigator.pushNamed(context, AppRouter.dashboard),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isFullWidth ? 100 : 160,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(100),
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
              child: isFullWidth
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(64),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withAlpha(200),
                          size: 20,
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(64),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(220),
                            fontSize: 12,
                          ),
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
                description: 'เรียนรู้ทฤษฎีดนตรีและหลักการต่างๆ',
              ),
              _buildGuideItem(
                icon: Icons.quiz,
                title: 'ทดสอบ',
                description: 'ทดสอบความรู้ด้วยแบบทดสอบที่หลากหลาย',
              ),
              _buildGuideItem(
                icon: Icons.bar_chart,
                title: 'ผลการทดสอบ',
                description: 'ดูสถิติและความก้าวหน้าของคุณ',
              ),
              _buildGuideItem(
                icon: Icons.settings,
                title: 'การตั้งค่า',
                description: 'ปรับแต่งเสียงและการแสดงผล',
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
