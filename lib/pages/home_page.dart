import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sound_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _openSoundSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SoundSettingsPage()),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('LingSix Home'),
        actions: [
          IconButton(
            tooltip: 'Sound Settings',
            icon: const Icon(Icons.volume_up),
            onPressed: () => _openSoundSettings(context),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (user != null) Text('Welcome, ${user.email ?? user.uid}'),
            const SizedBox(height: 30),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/quiz-menu'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 32),
                      child: Text('Play Game', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/dashboard'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                      child: Text('User Dashboard', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('LingSix — Select an action above'),
          ],
        ),
      ),
    );
  }
}
