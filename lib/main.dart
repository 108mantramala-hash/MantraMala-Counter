import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:just_audio/just_audio.dart";
import "package:shared_preferences/shared_preferences.dart";
import "dart:math" as math;
import "dart:async";

void main() {
  runApp(const MantraMalaApp());
}

class MantraMalaApp extends StatelessWidget {
  const MantraMalaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "MantraMala",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD6A54B),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF1C1E3A),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFFF8F5F0),
            fontWeight: FontWeight.bold,
            fontSize: 48,
          ),
          displayMedium: TextStyle(
            color: Color(0xFFF8F5F0),
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          bodyLarge: TextStyle(
            color: Color(0xFFF8F5F0),
            fontSize: 18,
          ),
          bodyMedium: TextStyle(
            color: Color(0xFFA0A0A8),
            fontSize: 16,
          ),
        ),
      ),
      home: const MantraMalaHome(),
    );
  }
}

class MantraMalaHome extends StatefulWidget {
  const MantraMalaHome({super.key});

  @override
  State<MantraMalaHome> createState() => _MantraMalaHomeState();
}

class _MantraMalaHomeState extends State<MantraMalaHome> {
  int _currentCount = 0;
  int _targetCount = 108;
  bool _isCompleted = false;
  late AudioPlayer _tapPlayer;
  late AudioPlayer _bellPlayer;
  late SharedPreferences _prefs;
  Timer? _completionSoundTimer;
  Timer? _completionSoundStopTimer;
  int _totalMantras = 0; // All-time mantra count
  //String _lastSessionDate = "2025-12-01";
  double _volume = 0.8; // 0.0 - 1.0
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;
  bool _tapAnywhere = false;
  // Disable tap sound globally (tab.mp3)
  bool _tapClickSoundEnabled = false;
  int _defaultTarget = 108;

  final List<int> presets = [27, 54, 108];

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _loadData();
  }

  @override
  void dispose() {
    _completionSoundTimer?.cancel();
    _completionSoundStopTimer?.cancel();
    _tapPlayer.dispose();
    _bellPlayer.dispose();
    super.dispose();
  }

  Future<void> _initializeAudio() async {
    // Initialize players and attempt to preload assets if present
    _tapPlayer = AudioPlayer();
    _bellPlayer = AudioPlayer();
    try {
      await _tapPlayer.setVolume(_volume);
      await _bellPlayer.setVolume(_volume);
      // Try set asset sources; if assets are missing/invalid, fallback will be used
      try {
        // Load the correct asset (pubspec lists assets/sounds/tab.mp3)
        await _tapPlayer.setAudioSource(AudioSource.asset("assets/sounds/tab.mp3"));
      } catch (_) {}
      try {
        await _bellPlayer.setAudioSource(AudioSource.asset("assets/sounds/bell.mp3"));
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentCount = _prefs.getInt("currentCount") ?? 0;
      _targetCount = _prefs.getInt("targetCount") ?? 108;
      _isCompleted = _prefs.getBool("isCompleted") ?? false;
      _totalMantras = _prefs.getInt("totalMantras") ?? 0;
     // _lastSessionDate = _prefs.getString("lastSessionDate") ?? "";
      _volume = _prefs.getDouble("volume") ?? 0.8;
      _soundEnabled = _prefs.getBool("soundEnabled") ?? true;
      _hapticsEnabled = _prefs.getBool("hapticsEnabled") ?? true;
      _tapAnywhere = _prefs.getBool("tapAnywhere") ?? false;
      _defaultTarget = _prefs.getInt("defaultTarget") ?? 108;
      // If app just opened and currentCount is zero, apply default target
      if (_currentCount == 0) {
        _targetCount = _defaultTarget;
      }
    });
    try {
      await _tapPlayer.setVolume(_volume);
      await _bellPlayer.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> _saveData() async {
    await _prefs.setInt("currentCount", _currentCount);
    await _prefs.setInt("targetCount", _targetCount);
    await _prefs.setBool("isCompleted", _isCompleted);
    await _prefs.setInt("totalMantras", _totalMantras);
    await _prefs.setString("lastSessionDate", DateTime.now().toString().split(" ")[0]);
    await _prefs.setDouble("volume", _volume);
    await _prefs.setBool("soundEnabled", _soundEnabled);
    await _prefs.setBool("hapticsEnabled", _hapticsEnabled);
    await _prefs.setBool("tapAnywhere", _tapAnywhere);
    await _prefs.setInt("defaultTarget", _defaultTarget);
  }

  Future<void> _playTapSound() async {
    // Respect global disable for tap sound
    if (!_soundEnabled || !_tapClickSoundEnabled) return;
    // Prefer just_audio if source set; otherwise system click
    try {
      if (_tapPlayer.audioSource != null) {
        await _tapPlayer.seek(Duration.zero);
        await _tapPlayer.play();
      } else {
        // Intentionally disabled: no system click fallback
      }
    } catch (_) {
      // Intentionally disabled: no system click fallback
    }
  }

  void _startCompletionSoundLoop() {
    // Completion sound disabled for v1.0
    return;
  }

  void _stopCompletionSoundLoop() {
    _completionSoundTimer?.cancel();
    _completionSoundStopTimer?.cancel();
    // Re-disable tap click sound after completion window
    _tapClickSoundEnabled = false;
  }

  void _setTarget(int target) {
    setState(() {
      _targetCount = target;
      _currentCount = 0;
      _isCompleted = false;
    });
    _saveData();
  }

  void _incrementCounter() {
    if (!_isCompleted) {
      setState(() {
        _currentCount++;
        _totalMantras++;
        if (_currentCount >= _targetCount) {
          _isCompleted = true;
          // Strong haptic feedback when target is reached
          if (_hapticsEnabled) HapticFeedback.heavyImpact();
          // Only enable tab.mp3 after the UI shows green status.
          // Schedule the loop to start after the current frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isCompleted) {
              _startCompletionSoundLoop();
            }
          });
          _showCompletionSheet();
        } else {
          // Light tap haptic feedback on each count
          if (_hapticsEnabled) HapticFeedback.lightImpact();
          _playTapSound();
        }
      });
      _saveData();
    }
  }

  void _resetCounter() {
    _stopCompletionSoundLoop();
    setState(() {
      _currentCount = 0;
      _isCompleted = false;
    });
    _saveData();
  }

  void _showCompletionSheet() {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2A2C48),
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Color(0xFFD6A54B), size: 32),
                  const SizedBox(width: 8),
                  Text(
                    "Session Complete",
                    style: Theme.of(ctx).textTheme.displayMedium?.copyWith(color: const Color(0xFFD6A54B)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "You reached $_targetCount mantras.",
                style: Theme.of(ctx).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                "Total mantras: $_totalMantras",
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _stopCompletionSoundLoop();
                        Navigator.of(ctx).pop();
                        _resetCounter();
                      },
                      icon: const Icon(Icons.restart_alt, size: 24),
                      label: const Text("Reset"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_targetCount < _defaultTarget)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _stopCompletionSoundLoop();
                          Navigator.of(ctx).pop();
                          // Increase target to next preset or +10%
                          final presetsSorted = [...presets]..sort();
                          int next = _targetCount;
                          for (final p in presetsSorted) {
                            if (p > _targetCount) { next = p; break; }
                          }
                          if (next == _targetCount) {
                            next = (_targetCount * 1.1).round();
                          }
                          _setTarget(next);
                        },
                        icon: const Icon(Icons.trending_up, size: 24),
                        label: const Text("Increase Target"),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    _stopCompletionSoundLoop();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      // Stop the loop when the sheet is closed (by any means)
      _stopCompletionSoundLoop();
    });
  }

  double _getProgressPercentage() {
    if (_targetCount == 0) return 0;
    return (_currentCount / _targetCount).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Global pointer listener: stop completion sound on any interaction
    return Listener(
      onPointerDown: (_) {
        _stopCompletionSoundLoop();
      },
      child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        toolbarHeight: 80,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFD6A54B), Color(0xFFF8F5F0), Color(0xFFD6A54B)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ).createShader(bounds),
              child: const Text(
                'MantraMala',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Japa • Chant • Meditate',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                color: Color(0xFFD0D0D0),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1C1E3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, size: 32),
            tooltip: "Settings",
            onPressed: () async {
              // Stop any completion sound loop on interaction
              if (_isCompleted) _stopCompletionSoundLoop();
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => SettingsPage(
                  volume: _volume,
                  soundEnabled: _soundEnabled,
                  hapticsEnabled: _hapticsEnabled,
                  tapAnywhere: _tapAnywhere,
                  defaultTarget: _defaultTarget,
                  presets: presets,
                  onChanged: (s) async {
                    setState(() {
                      _volume = s.volume;
                      _soundEnabled = s.soundEnabled;
                      _hapticsEnabled = s.hapticsEnabled;
                      _tapAnywhere = s.tapAnywhere;
                      _defaultTarget = s.defaultTarget;
                      // If session not started, apply default target immediately
                      if (_currentCount == 0) {
                        _targetCount = _defaultTarget;
                      }
                    });
                    try {
                      await _tapPlayer.setVolume(_volume);
                      await _bellPlayer.setVolume(_volume);
                    } catch (_) {}
                    _saveData();
                  },
                  onResetTotalMantras: () async {
                    setState(() {
                      _totalMantras = 0;
                    });
                    await _prefs.setInt("totalMantras", 0);
                  },
                  onResetTodaysTarget: () async {
                    setState(() {
                      _currentCount = 0;
                      _isCompleted = false;
                      _targetCount = _defaultTarget;
                    });
                    await _saveData();
                  },
                ),
              ));
            },
          )
        ],
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_isCompleted) {
              _stopCompletionSoundLoop();
            } else if (_tapAnywhere) {
              _incrementCounter();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.05,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                _buildStatsBar(context, screenWidth),
                SizedBox(height: screenHeight * 0.03),
                _buildPresetButtons(context, screenWidth),
                SizedBox(height: screenHeight * 0.03),
                _buildCircularCounter(context, screenWidth),
                SizedBox(height: screenHeight * 0.02),
                _buildStatusText(context),
                SizedBox(height: screenHeight * 0.02),
                _buildTapButton(context, screenWidth),
                SizedBox(height: screenHeight * 0.015),
                _buildResetButton(context, screenWidth),
              ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildStatsBar(BuildContext context, double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF3A3C58).withValues(alpha: 0.4),
            const Color(0xFF2A2C48).withValues(alpha: 0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF4A4C6E).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 2.0,
            colors: [
              const Color(0xFF2A2C48),
              const Color(0xFF1C1E3A),
              const Color(0xFF14162A),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                "Total Mantras",
                _totalMantras.toString(),
              ),
            ),
            Container(
              width: 1.5,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF4A4C6E).withValues(alpha: 0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                "Today's Target",
                _targetCount.toString(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFFA0A0A8).withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFD96A),
              Color(0xFFD6A54B),
            ],
          ).createShader(bounds),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0x60000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPresetButtons(BuildContext context, double screenWidth) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: presets.map((preset) => _buildPresetButton(context, preset, screenWidth)).toList(),
    );
  }

  Widget _buildPresetButton(BuildContext context, int preset, double screenWidth) {
    final isActive = _targetCount == preset;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFD6A54B).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xFFFFD96A).withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: -2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: -3,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: isActive
              ? const LinearGradient(
                  colors: [
                    Color(0xFFFFD96A),
                    Color(0xFFD6A54B),
                    Color(0xFFB8873D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : RadialGradient(
                  center: Alignment.topLeft,
                  radius: 2.0,
                  colors: [
                    const Color(0xFF3A3C58).withValues(alpha: 0.6),
                    const Color(0xFF2A2C48),
                    const Color(0xFF1C1E3A),
                  ],
                ),
          border: Border.all(
            color: isActive
                ? const Color(0xFFFFD96A).withValues(alpha: 0.5)
                : const Color(0xFF4A4C6E).withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            gradient: isActive
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  )
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_isCompleted) _stopCompletionSoundLoop();
                _setTarget(preset);
              },
              borderRadius: BorderRadius.circular(17),
              splashColor: isActive
                  ? Colors.white.withValues(alpha: 0.2)
                  : const Color(0xFFD6A54B).withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: ShaderMask(
                  shaderCallback: (bounds) => isActive
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF1C1E3A),
                            Color(0xFF0A0B1A),
                          ],
                        ).createShader(bounds)
                      : const LinearGradient(
                          colors: [
                            Color(0xFFFFD96A),
                            Color(0xFFD6A54B),
                          ],
                        ).createShader(bounds),
                  child: Text(
                    preset.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: isActive
                          ? [
                              const Shadow(
                                color: Color(0x40000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : [
                              Shadow(
                                color: const Color(0xFFD6A54B).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircularCounter(BuildContext context, double screenWidth) {
    final counterSize = screenWidth * 0.65;
    final progress = _getProgressPercentage();
    return Container(
      width: counterSize,
      height: counterSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: -5,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: const Color(0xFFD6A54B).withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: -10,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.topLeft,
            radius: 1.2,
            colors: [
              const Color(0xFF3A3C58).withValues(alpha: 0.9),
              const Color(0xFF2A2C48),
              const Color(0xFF1C1E3A),
              const Color(0xFF14162A),
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFF4A4C6E).withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.05),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background track with inner shadow effect
              CustomPaint(
                size: Size(counterSize, counterSize),
                painter: CircleProgressPainter(
                  progress: 1.0,
                  color: const Color(0xFF0D0E1A).withValues(alpha: 0.6),
                  strokeWidth: 12,
                ),
              ),
              // Subtle glow track
              CustomPaint(
                size: Size(counterSize, counterSize),
                painter: CircleProgressPainter(
                  progress: 1.0,
                  color: const Color(0xFF3A3C4E).withValues(alpha: 0.2),
                  strokeWidth: 11,
                ),
              ),
              // Progress arc with gradient effect
              CustomPaint(
                size: Size(counterSize, counterSize),
                painter: GradientCircleProgressPainter(
                  progress: progress,
                  strokeWidth: 12,
                ),
              ),
              // Outer glow on progress
              if (progress > 0)
                CustomPaint(
                  size: Size(counterSize, counterSize),
                  painter: CircleProgressPainter(
                    progress: progress,
                    color: const Color(0xFFFFD96A).withValues(alpha: 0.3),
                    strokeWidth: 16,
                  ),
                ),
              // Content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFFFFFFF),
                        const Color(0xFFE8E8E8),
                      ],
                    ).createShader(bounds),
                    child: Text(
                      _currentCount.toString(),
                      style: const TextStyle(
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Color(0x40000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "/ $_targetCount",
                    style: TextStyle(
                      fontSize: 18,
                      color: const Color(0xFFA0A0A8).withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: progress >= 1.0
                            ? [
                                const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                const Color(0xFF45A049).withValues(alpha: 0.2),
                              ]
                            : [
                                const Color(0xFFD6A54B).withValues(alpha: 0.2),
                                const Color(0xFFB8873D).withValues(alpha: 0.15),
                              ],
                      ),
                      border: Border.all(
                        color: progress >= 1.0
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                            : const Color(0xFFD6A54B).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: progress >= 1.0
                            ? [
                                const Color(0xFF66BB6A),
                                const Color(0xFF4CAF50),
                              ]
                            : [
                                const Color(0xFFFFD96A),
                                const Color(0xFFD6A54B),
                              ],
                      ).createShader(bounds),
                      child: Text(
                        "${(progress * 100).toStringAsFixed(0)}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context) {
    if (_isCompleted) {
      return ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [
            Color(0xFF66BB6A),
            Color(0xFF4CAF50),
          ],
        ).createShader(bounds),
        child: Text(
          "Target Complete ✓",
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Color(0x404CAF50),
                blurRadius: 12,
                offset: Offset(0, 0),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTapButton(BuildContext context, double screenWidth) {
    return Center(
      child: Container(
        width: screenWidth * 0.8,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          gradient: _isCompleted
              ? LinearGradient(
                  colors: [
                    const Color(0xFF3A3C4E).withValues(alpha: 0.8),
                    const Color(0xFF2A2C48).withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFFFD96A),
                    Color(0xFFD6A54B),
                    Color(0xFFB8873D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
          boxShadow: _isCompleted
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFD6A54B).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFD96A).withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: -5,
                    offset: const Offset(0, 0),
                  ),
                ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: _isCompleted
                ? null
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.5],
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCompleted ? null : _incrementCounter,
              borderRadius: BorderRadius.circular(35),
              splashColor: Colors.white.withValues(alpha: 0.2),
              highlightColor: Colors.white.withValues(alpha: 0.1),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) => _isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFFA0A0A8), Color(0xFFA0A0A8)],
                        ).createShader(bounds)
                      : const LinearGradient(
                          colors: [
                            Color(0xFF1C1E3A),
                            Color(0xFF0A0B1A),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ).createShader(bounds),
                  child: Text(
                    _isCompleted ? "Completed ✓" : "Tap to Count",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: Color(0x40000000),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, double screenWidth) {
    return Center(
      child: Container(
        width: screenWidth * 0.6,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          color: const Color(0xFF2A2C48),
          border: Border.all(
            color: const Color(0xFF3A3C4E),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_isCompleted) _stopCompletionSoundLoop();
              _resetCounter();
            },
            borderRadius: BorderRadius.circular(27),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.restart_alt,
                  size: 20,
                  color: Color(0xFFF8F5F0),
                ),
                const SizedBox(width: 8),
                Text(
                  "Reset",
                  style: TextStyle(
                    color: const Color(0xFFF8F5F0),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsData {
  final double volume;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool tapAnywhere;
  final int defaultTarget;

  const SettingsData({
    required this.volume,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.tapAnywhere,
    required this.defaultTarget,
  });
}

class SettingsPage extends StatefulWidget {
  final double volume;
  final bool soundEnabled;
  final bool hapticsEnabled;
  final bool tapAnywhere;
  final int defaultTarget;
  final List<int> presets;
  final Future<void> Function(SettingsData) onChanged;
  final Future<void> Function() onResetTotalMantras;
  final Future<void> Function() onResetTodaysTarget;

  const SettingsPage({
    super.key,
    required this.volume,
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.tapAnywhere,
    required this.defaultTarget,
    required this.presets,
    required this.onChanged,
    required this.onResetTotalMantras,
    required this.onResetTodaysTarget,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late double _volume;
  late bool _soundEnabled;
  late bool _hapticsEnabled;
  late bool _tapAnywhere;
  late int _defaultTarget;

  @override
  void initState() {
    super.initState();
    _volume = widget.volume;
    _soundEnabled = widget.soundEnabled;
    _hapticsEnabled = widget.hapticsEnabled;
    _tapAnywhere = widget.tapAnywhere;
    _defaultTarget = widget.defaultTarget;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Default Target", style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.presets.map((p) {
                final active = p == _defaultTarget;
                return ChoiceChip(
                  label: Text(p.toString()),
                  selected: active,
                  onSelected: (_) => setState(() => _defaultTarget = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Switch(value: _soundEnabled, onChanged: (v) => setState(() => _soundEnabled = v)),
              const SizedBox(width: 8),
              const Text("Enable Sound"),
            ]),
            Row(children: [
              Switch(value: _hapticsEnabled, onChanged: (v) => setState(() => _hapticsEnabled = v)),
              const SizedBox(width: 8),
              const Text("Enable Haptics"),
            ]),
            Row(children: [
              Switch(value: _tapAnywhere, onChanged: (v) => setState(() => _tapAnywhere = v)),
              const SizedBox(width: 8),
              const Text("Tap Anywhere to Count"),
            ]),
            const SizedBox(height: 16),
            Text("Volume", style: Theme.of(context).textTheme.bodyLarge),
            Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: (_volume * 100).round().toString(),
              onChanged: (v) => setState(() => _volume = v),
            ),
            const Spacer(),
            // Save Button
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD6A54B), Color(0xFFB8873D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD6A54B).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      // Capture context-bound objects before awaiting
                      final nav = Navigator.of(context);
                      await widget.onChanged(SettingsData(
                        volume: _volume,
                        soundEnabled: _soundEnabled,
                        hapticsEnabled: _hapticsEnabled,
                        tapAnywhere: _tapAnywhere,
                        defaultTarget: _defaultTarget,
                      ));
                      if (mounted) nav.pop();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 24, color: Color(0xFF1C1E3A)),
                        SizedBox(width: 8),
                        Text(
                          "Save Settings",
                          style: TextStyle(
                            color: Color(0xFF1C1E3A),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Reset Actions Section
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2C48),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF3A3C4E), width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      "Reset Actions",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFFA0A0A8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Reset Total Mantras Button
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFF3A3C4E),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            // Capture messenger before awaiting
                            final messenger = ScaffoldMessenger.of(context);
                            await widget.onResetTotalMantras();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text("Total mantras reset")),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delete_sweep, size: 22, color: Color(0xFFF8F5F0)),
                              SizedBox(width: 8),
                              Text(
                                "Reset Total Mantras",
                                style: TextStyle(
                                  color: Color(0xFFF8F5F0),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircleProgressPainter({required this.progress, required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = strokeWidth..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    canvas.drawArc(Rect.fromCenter(center: center, width: radius * 2, height: radius * 2), -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}

class GradientCircleProgressPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;

  GradientCircleProgressPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) {
      // Nothing to paint for zero progress; avoids invalid SweepGradient angles
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCenter(center: center, width: radius * 2, height: radius * 2);

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + (2 * math.pi * progress),
      colors: const [
        Color(0xFFFFD96A),
        Color(0xFFD6A54B),
        Color(0xFFB8873D),
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(GradientCircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.strokeWidth != strokeWidth;
  }
}
