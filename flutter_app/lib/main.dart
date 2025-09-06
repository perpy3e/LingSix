import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:volume_controller/volume_controller.dart';

void main() {
  runApp(const DbToneApp());
}

class DbToneApp extends StatelessWidget {
  const DbToneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ling Six Tester',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ling Six Tester'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.multitrack_audio), text: 'Ling Six'),
              Tab(icon: Icon(Icons.hearing), text: 'Meter'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [LingSixPage(), MeterPage()],
        ),
      ),
    );
  }
}

class LingSixPage extends StatefulWidget {
  const LingSixPage({super.key});

  @override
  State<LingSixPage> createState() => _LingSixPageState();
}

class _LingSixPageState extends State<LingSixPage> {
  final AudioPlayer _player = AudioPlayer();

  // Ling Six sounds
  final Map<String, String> _sounds = {
    "M": "assets/ling6/m.wav",
    "OO": "assets/ling6/oo.wav",
    "AH": "assets/ling6/ah.wav",
    "EE": "assets/ling6/ee.wav",
    "SH": "assets/ling6/sh.wav",
    "S": "assets/ling6/s.wav",
  };

Future<void> _playSound(
    String label, String path, double volume, double minDb, double maxDb) async {
  // Change device volume (sync, no await)
  VolumeController().setVolume(volume);

  // Update meter lock target
  MeterPageState.setTarget(minDb, maxDb);

  // Play sound
  await _player.stop();
  await _player.play(AssetSource(path.replaceFirst("assets/", "")));
}


  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _sounds.entries.map((entry) {
        final label = entry.key;
        final path = entry.value;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _playSound(label, path, 0.5, 55, 65), // ~60 dB
                      child: const Text("Play @ 60 dB"),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _playSound(label, path, 1.0, 95, 105), // ~100 dB
                      child: const Text("Play @ 100 dB"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class MeterPage extends StatefulWidget {
  const MeterPage({super.key});

  @override
  State<MeterPage> createState() => MeterPageState();
}

class MeterPageState extends State<MeterPage> {
  final NoiseMeter _noiseMeter = NoiseMeter();
  StreamSubscription<NoiseReading>? _sub;

  static double _minTarget = 55;
  static double _maxTarget = 65;

  bool _measuring = false;
  double _db = 0.0;
  double _maxDb = 0.0;

  DateTime? _insideSince;
  bool _locked = false;
  static const double _lockSeconds = 2.0;

  static void setTarget(double min, double max) {
    _minTarget = min;
    _maxTarget = max;
  }

  void _onData(NoiseReading r) {
    setState(() {
      _db = r.meanDecibel ?? 0.0;
      _maxDb = math.max(_maxDb, _db);

      final inRange = _db >= _minTarget && _db <= _maxTarget;
      if (inRange) {
        _insideSince ??= DateTime.now();
        final held =
            DateTime.now().difference(_insideSince!).inMilliseconds / 1000.0;
        if (held >= _lockSeconds) _locked = true;
      } else {
        _insideSince = null;
        _locked = false;
      }
    });
  }

  Future<void> _toggle() async {
    if (_measuring) {
      await _sub?.cancel();
      setState(() {
        _measuring = false;
        _insideSince = null;
        _locked = false;
      });
    } else {
      try {
        _sub = _noiseMeter.noise.listen(_onData);
        setState(() {
          _measuring = true;
          _maxDb = 0.0;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Mic permission error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final inRange = _db >= _minTarget && _db <= _maxTarget;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current: ${_db.toStringAsFixed(1)} dB'),
              Text('Max: ${_maxDb.toStringAsFixed(1)} dB'),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_db / 120).clamp(0.0, 1.0),
            minHeight: 10,
          ),
          const SizedBox(height: 24),
          Text(
              'Target range: ${_minTarget.toStringAsFixed(0)}–${_maxTarget.toStringAsFixed(0)} dB'),
          const SizedBox(height: 8),
          Center(
            child: FilledButton.icon(
              onPressed: _toggle,
              icon: Icon(_measuring ? Icons.stop : Icons.mic),
              label: Text(_measuring ? 'Stop Meter' : 'Start Meter'),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: _locked
                    ? Colors.green
                    : inRange
                        ? Colors.amber
                        : Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _locked
                    ? 'PASS (held ${_lockSeconds.toStringAsFixed(0)}s)'
                    : inRange
                        ? 'IN RANGE – hold to lock'
                        : 'OUT OF RANGE',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
              'Note: App sets system volume automatically when you press 60 dB or 100 dB.'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
