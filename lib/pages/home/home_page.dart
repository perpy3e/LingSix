import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person_outline),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        title: const Text('Start Page'),
      ),
      body: const Center(
        child: Text(
          'Home / Start Page',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
