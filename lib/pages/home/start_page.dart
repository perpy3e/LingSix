import 'package:flutter/material.dart';
import 'package:lingsix/app/theme.dart';
import 'package:lingsix/app/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lingsix/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

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
                onError: (error, stackTrace) {},
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // Character image
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Image.asset(
                      'assets/common/illustrations/start_character.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser;

                          if (user == null) {
                            Navigator.pushNamed(context, AppRouter.login);
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppRouter.avatarSelected,
                            );
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.yellow700,
                          side: const BorderSide(color: Colors.white, width: 2),
                          backgroundColor: AppColors.yellow200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "แตะเพื่อเริ่ม",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
