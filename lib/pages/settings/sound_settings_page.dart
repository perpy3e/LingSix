import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../app/theme.dart';
import '../../utils/snackbar_helper.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:lingsix/providers/theme_provider.dart';
import '../../utils/responsive.dart';

class SoundSettingsPage extends StatefulWidget {
  const SoundSettingsPage({super.key});

  @override
  State<SoundSettingsPage> createState() => _SoundSettingsPageState();
}

class _SoundSettingsPageState extends State<SoundSettingsPage> {
  final AudioPlayer _player = AudioPlayer();
  double? _selectedDb;
  double? _originalDb;
  final List<double> _dbOptions = [40, 50, 60, 70];

  @override
  void initState() {
    super.initState();
    _loadCurrentVolume();
  }

  Future<void> _loadCurrentVolume() async {
    final volume = await VolumeController.instance.getVolume();
    if (!mounted) return;
    setState(() {
      // Convert volume (0-1) to dB approximation (40-70 range)
      final dbValue = (volume * 100).clamp(40, 70).toDouble();
      // Find closest dB option
      _originalDb = _dbOptions.reduce(
        (a, b) => (a - dbValue).abs() < (b - dbValue).abs() ? a : b,
      );
    });
  }

  bool get _hasChanged => _selectedDb != null && _selectedDb != _originalDb;

  Future<void> _testSound(double db) async {
    await VolumeController.instance.setVolume(db / 100);
    await _player.stop();
    await _player.play(AssetSource('common/sounds/setting.mp3'));
  }

  Future<void> _saveVolume() async {
    if (_selectedDb == null) return;

    // บันทึกระดับเสียงจริง
    await VolumeController.instance.setVolume(_selectedDb! / 100);

    // อัพเดทค่า originalDb เป็นค่าใหม่
    setState(() {
      _originalDb = _selectedDb;
      _selectedDb = null; // รีเซ็ต selection
    });

    if (!mounted) return;

    SnackBarHelper.showSuccess(
      context,
      "บันทึกระดับเสียง ${_originalDb!.toInt()} dB สำเร็จ",
    );
  }

  void _lockDb() {
    if (_selectedDb == null) return;

    final min = _selectedDb! - 5;
    final max = _selectedDb! + 5;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.braveOrange.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.info_outline_rounded,
                color: AppColors.braveOrange,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text("ล็อคระดับเสียง?"),
          ],
        ),
        content: Text(
          "คุณต้องการล็อคระดับเสียงที่ ${_selectedDb!.toInt()} dB (อยู่ในช่วง $min–$max dB) ใช่หรือไม่?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _saveVolume();
            },
            child: const Text("ยืนยัน"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.responsive;

    return Scaffold(
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(themeProvider.getWallpaperPath('settings')),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Header
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
                          "การตั้งค่าระดับเสียง",
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: AppColors.blue800),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: r.spacing(48),
                        ), // Balance the back button
                      ],
                    ),
                  ),

                  // Body content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: r.pagePadding(horizontal: 20),
                      child: ResponsiveContent(
                        maxWidth: r.contentMaxWidth(phone: 520, tablet: 700),
                        child: Column(
                          children: [
                            SizedBox(height: r.spacing(20)),

                            // Current Volume Display Card
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(r.spacing(20)),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.blue100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.speaker_rounded,
                                            color: AppColors.blue600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "ระดับเสียงปัจจุบัน",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.gray700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: r.spacing(16)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${_originalDb?.toInt() ?? '--'}",
                                          style: TextStyle(
                                            fontSize: r.text(48),
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.blue600,
                                          ),
                                        ),
                                        SizedBox(width: r.spacing(8)),
                                        Text(
                                          "dB",
                                          style: TextStyle(
                                            fontSize: r.text(20),
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.gray550,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_hasChanged) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.braveOrange
                                              .withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                              color: AppColors.braveOrange,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              "เปลี่ยนเป็น ${_selectedDb!.toInt()} dB",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.braveOrange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: r.spacing(20)),

                            // Volume Selection Card
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(r.spacing(20)),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.blue100,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.volume_up_rounded,
                                            color: AppColors.blue600,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Expanded(
                                          child: Text(
                                            "เลือกระดับเสียงใหม่",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.gray700,
                                            ),
                                          ),
                                        ),
                                        // Info icon with tap to show
                                        GestureDetector(
                                          onTap: () {
                                            SnackBarHelper.show(
                                              context,
                                              "เลือกระดับเสียงใหม่ที่ต้องการ โปรดกดทดสอบเสียงก่อนยืนยัน",
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColors.blue100,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.info_outline_rounded,
                                              color: AppColors.blue600,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: r.spacing(20)),
                                    const Divider(color: AppColors.gray75),
                                    SizedBox(height: r.spacing(20)),

                                    // Volume buttons
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: _dbOptions.map((db) {
                                        final selected = _selectedDb == db;
                                        final isOriginal =
                                            _originalDb == db &&
                                            _selectedDb == null;
                                        return GestureDetector(
                                          onTap: () =>
                                              setState(() => _selectedDb = db),
                                          child: Container(
                                            width: r.spacing(70),
                                            height: r.spacing(70),
                                            decoration: BoxDecoration(
                                              color: selected
                                                  ? AppColors.braveOrange
                                                  : (isOriginal
                                                        ? AppColors.blue600
                                                        : AppColors.blue100),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: selected
                                                    ? AppColors.braveOrange
                                                    : (isOriginal
                                                          ? AppColors.blue600
                                                          : AppColors.blue300),
                                                width: 2,
                                              ),
                                              boxShadow: selected
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors
                                                            .braveOrange
                                                            .withAlpha(80),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Center(
                                              child: Text(
                                                "${db.toInt()}",
                                                style: TextStyle(
                                                  fontSize: r.text(24),
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      (selected || isOriginal)
                                                      ? Colors.white
                                                      : AppColors.blue700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),

                                    SizedBox(height: r.spacing(12)),
                                    Center(
                                      child: Text(
                                        "dB",
                                        style: TextStyle(
                                          fontSize: r.text(14),
                                          color: AppColors.gray550,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: r.spacing(24)),

                            // Action buttons
                            SizedBox(
                              width: double.infinity,
                              height: r.buttonHeight(56),
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "ทดสอบเสียง",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue600,
                                  disabledBackgroundColor: AppColors.gray300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _selectedDb != null
                                    ? () => _testSound(_selectedDb!)
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              height: r.buttonHeight(56),
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  Icons.lock_rounded,
                                  color: _hasChanged
                                      ? Colors.white
                                      : AppColors.gray550,
                                ),
                                label: Text(
                                  "ล็อคระดับเสียง",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _hasChanged
                                        ? Colors.white
                                        : AppColors.gray550,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _hasChanged
                                      ? AppColors.braveOrange
                                      : AppColors.gray100,
                                  disabledBackgroundColor: AppColors.gray100,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: _hasChanged ? _lockDb : null,
                              ),
                            ),

                            if (!_hasChanged && _selectedDb != null)
                              Padding(
                                padding: EdgeInsets.only(top: r.spacing(8)),
                                child: Text(
                                  "ระดับเสียงเดิมกับที่เลือกเหมือนกัน",
                                  style: TextStyle(
                                    fontSize: r.text(12),
                                    color: AppColors.gray550,
                                  ),
                                ),
                              ),

                            SizedBox(height: r.spacing(30)),
                          ],
                        ),
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
}
