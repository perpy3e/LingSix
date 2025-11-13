import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:volume_controller/volume_controller.dart';
import '../services/auth_service.dart';

class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final AudioPlayer _player = AudioPlayer();
  final AuthService _authService = AuthService();
  double? _selectedDb;
  final List<double> _dbOptions = [40, 50, 60, 70];

  Future<void> _testSound(double db) async {
    VolumeController().setVolume(db / 100);
    await _player.stop();
    await _player.play(AssetSource("ling6/ee.wav"));
  }

  void _lockDb() {
    if (_selectedDb == null) return;

    final min = _selectedDb! - 5;
    final max = _selectedDb! + 5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Lock Volume!"),
        content: Text(
            "You selected ${_selectedDb!.toInt()} dB (range $min–$max dB)"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sound Settings"),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text("Select Volume Level",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            children: _dbOptions.map((db) {
              final selected = _selectedDb == db;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected ? Colors.amber : Colors.blue,
                  minimumSize: const Size(70, 70),
                ),
                onPressed: () => setState(() => _selectedDb = db),
                child: Text("${db.toInt()}",
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
              );
            }).toList(),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _selectedDb != null ? () => _testSound(_selectedDb!) : null,
            child: const Text("Test Sound"),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _lockDb, child: const Text("Lock Volume")),
        ]),
      ),
    );
  }
}
