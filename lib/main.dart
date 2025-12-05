import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:just_audio/just_audio.dart";
import "package:audio_session/audio_session.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:in_app_review/in_app_review.dart";
import "dart:math" as math;
import "dart:async";
import "package:url_launcher/url_launcher.dart";

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
  DateTime? _firstLaunchDate;
  bool _hasAskedForReview = false;

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
    // Configure audio session to prevent Live Caption notifications
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.none,
      ));
    } catch (_) {
      // Audio session configuration failed, continue anyway
    }
    
    // Initialize players and attempt to preload assets if present
    _tapPlayer = AudioPlayer();
    _bellPlayer = AudioPlayer();
    try {
      // Set audio source; if assets are missing/invalid, fallback will be used
      await _tapPlayer.setAudioSource(AudioSource.asset("assets/sounds/tab.mp3")).catchError((_) => Duration.zero);
      await _bellPlayer.setAudioSource(AudioSource.asset("assets/sounds/Bell.mp3")).catchError((_) => Duration.zero);
      await _tapPlayer.setVolume(_volume);
      await _bellPlayer.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> _loadData() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Review tracking - initialize first launch date
    final firstLaunchMs = _prefs.getInt("firstLaunchDate");
    if (firstLaunchMs == null) {
      _firstLaunchDate = DateTime.now();
      await _prefs.setInt("firstLaunchDate", _firstLaunchDate!.millisecondsSinceEpoch);
    } else {
      _firstLaunchDate = DateTime.fromMillisecondsSinceEpoch(firstLaunchMs);
    }
    
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
      _hasAskedForReview = _prefs.getBool("hasAskedForReview") ?? false;
      // Set target to default (108) on first install or when count is zero
      _targetCount = _prefs.getInt("targetCount") ?? 108;
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
    await _prefs.setBool("hasAskedForReview", _hasAskedForReview);
  }

  Future<void> _checkAndRequestReview() async {
    // Only ask once
    if (_hasAskedForReview) return;
    
    // Check if 3 days have passed since first launch
    if (_firstLaunchDate == null) return;
    final daysSinceInstall = DateTime.now().difference(_firstLaunchDate!).inDays;
    if (daysSinceInstall < 3) return;
    
    // Check if user has counted at least 10 mantras
    if (_totalMantras < 10) return;
    
    try {
      final InAppReview inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
        _hasAskedForReview = true;
        await _saveData();
      }
    } catch (e) {
      // Silently fail - review request is not critical
    }
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

  void _stopCompletionSoundLoop() {
    _completionSoundTimer?.cancel();
    _completionSoundStopTimer?.cancel();
    // Re-disable tap click sound after completion window
    _tapClickSoundEnabled = false;
  }

  Future<void> _playCompletionSound() async {
    if (!_soundEnabled) return;
    try {
      // Try to play the bell sound
      await _bellPlayer.seek(Duration.zero);
      await _bellPlayer.play();
    } catch (e) {
      // If playing fails, try to reload and play
      try {
        await _bellPlayer.setAudioSource(AudioSource.asset("assets/sounds/Bell.mp3"));
        await _bellPlayer.setVolume(_volume);
        await _bellPlayer.play();
      } catch (_) {
        // Silently fail if sound playback fails
      }
    }
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
      final bool willComplete = (_currentCount + 1) >= _targetCount;
      
      setState(() {
        _currentCount++;
        _totalMantras++;
        if (_currentCount >= _targetCount) {
          _isCompleted = true;
          _showCompletionSheet();
          // Play completion sound once
          _playCompletionSound();
        }
      });
      
      // Haptic feedback and sound/vibration
      if (willComplete) {
        // Strong vibration pattern on completion
        if (_hapticsEnabled) {
          HapticFeedback.heavyImpact();
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted && _hapticsEnabled) HapticFeedback.mediumImpact();
          });
          Future.delayed(const Duration(milliseconds: 400), () {
            if (mounted && _hapticsEnabled) HapticFeedback.mediumImpact();
          });
        }
      } else {
        // Light tap haptic feedback on each count
        if (_hapticsEnabled) HapticFeedback.lightImpact();
        _playTapSound();
      }
      
      _saveData();
      
      // Check if we should request a review
      _checkAndRequestReview();
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
                  if (_targetCount >= _defaultTarget)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _stopCompletionSoundLoop();
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.close, size: 24),
                        label: const Text("Done"),
                      ),
                    ),
                ],
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
                SizedBox(height: screenHeight * 0.04),
                _buildCircularCounter(context, screenWidth * 1.1),
                SizedBox(height: screenHeight * 0.03),
                _buildResetButton(context, screenWidth * 0.35),
                SizedBox(height: screenHeight * 0.02),
                _buildTapButton(context, screenWidth * 0.9),
                SizedBox(height: screenHeight * 0.02),
                _buildStatusText(context),
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
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3A3C4E),
            Color(0xFF2A2C3E),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.5),
            blurRadius: 24,
            spreadRadius: 0,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: const Color(0xFF1A1C2E).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF4A4C5E).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF262835).withValues(alpha: 0.8),
              const Color(0xFF1A1C2E).withValues(alpha: 0.95),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                "Total Count",
                _totalMantras.toString(),
              ),
            ),
            Container(
              width: 2,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF4A4C5E).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                "Target",
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: const Color(0xFF9A9CA8).withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3A3C4E),
                Color(0xFF2A2C3E),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFFFD96A).withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD96A).withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFFE55C),
                Color(0xFFD6A54B),
              ],
            ).createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Color(0x70000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
        child: const SizedBox.shrink(),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTapButton(BuildContext context, double screenWidth) {
    return Center(
      child: Container(
        width: screenWidth * 0.85,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(36),
          gradient: _isCompleted
              ? LinearGradient(
                  colors: [
                    const Color(0xFF3A3C4E).withValues(alpha: 0.9),
                    const Color(0xFF2A2C48).withValues(alpha: 0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFFFFE55C),
                    Color(0xFFE5B84D),
                    Color(0xFFC4934D),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
          boxShadow: _isCompleted
              ? [
                  BoxShadow(
                    color: const Color(0xFF000000).withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFFFFD96A).withValues(alpha: 0.7),
                    blurRadius: 28,
                    spreadRadius: 3,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: const Color(0xFFFFE55C).withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: -8,
                    offset: const Offset(0, 0),
                  ),
                ],
          border: _isCompleted
              ? Border.all(color: const Color(0xFF3A3C4E), width: 1.5)
              : Border.all(
                  color: const Color(0xFFFFF8E7).withValues(alpha: 0.5),
                  width: 2,
                ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            gradient: _isCompleted
                ? null
                : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.6],
                  ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isCompleted ? null : _incrementCounter,
              borderRadius: BorderRadius.circular(36),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      size: 28,
                      color: _isCompleted ? const Color(0xFFA0A0A8) : const Color(0xFF1C1E3A),
                    ),
                    const SizedBox(width: 12),
                    ShaderMask(
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
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Color(0x60000000),
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                            Shadow(
                              color: Color(0x30000000),
                              blurRadius: 12,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
        width: screenWidth * 0.5,
        height: screenWidth * 0.5,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A2C48),
              Color(0xFF1F2131),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFF3A3C4E).withValues(alpha: 0.6),
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
            borderRadius: BorderRadius.circular(screenWidth / 2),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: const Center(
              child: Icon(
                Icons.refresh,
                size: 24,
                color: Color(0xFFF8F5F0),
              ),
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
  late FixedExtentScrollController _thousandsController;
  late FixedExtentScrollController _hundredsController;
  late FixedExtentScrollController _tensController;
  late FixedExtentScrollController _onesController;

  @override
  void initState() {
    super.initState();
    _volume = widget.volume;
    _soundEnabled = widget.soundEnabled;
    _hapticsEnabled = widget.hapticsEnabled;
    _tapAnywhere = widget.tapAnywhere;
    _defaultTarget = widget.defaultTarget;
    
    // Initialize scroll controllers to current target value
    _thousandsController = FixedExtentScrollController(initialItem: (_defaultTarget ~/ 1000) % 2);
    _hundredsController = FixedExtentScrollController(initialItem: (_defaultTarget ~/ 100) % 10);
    _tensController = FixedExtentScrollController(initialItem: (_defaultTarget ~/ 10) % 10);
    _onesController = FixedExtentScrollController(initialItem: _defaultTarget % 10);
  }

  @override
  void dispose() {
    _thousandsController.dispose();
    _hundredsController.dispose();
    _tensController.dispose();
    _onesController.dispose();
    super.dispose();
  }

  void _updateTargetFromPickers() {
    final thousands = _thousandsController.selectedItem % 2; // 0-1 only
    final hundreds = _hundredsController.selectedItem % 10;
    final tens = _tensController.selectedItem % 10;
    final ones = _onesController.selectedItem % 10;
    final newTarget = (thousands * 1000) + (hundreds * 100) + (tens * 10) + ones;
    // Cap at 1008 and ensure minimum is 1
    final cappedTarget = newTarget > 1008 ? 1008 : (newTarget == 0 ? 1 : newTarget);
    setState(() => _defaultTarget = cappedTarget);
  }

  Widget _buildNumberWheel(FixedExtentScrollController controller, String label, {int maxDigit = 9}) {
    final digitCount = maxDigit + 1;
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 5,
            color: Color(0xFFA0A0A8),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 67,
          width: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2C48), Color(0xFF1F2131)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: const Color(0xFFFFD96A).withValues(alpha: 0.2),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Selection highlight in center
              Center(
                child: Container(
                  height: 22,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFD96A).withValues(alpha: 0.15),
                        const Color(0xFFFFD96A).withValues(alpha: 0.25),
                        const Color(0xFFFFD96A).withValues(alpha: 0.15),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Number wheel
              ListWheelScrollView.useDelegate(
                controller: controller,
                itemExtent: 22,
                diameterRatio: 1.5,
                physics: const FixedExtentScrollPhysics(),
                perspective: 0.003,
                onSelectedItemChanged: (_) => _updateTargetFromPickers(),
                childDelegate: ListWheelChildLoopingListDelegate(
                  children: List.generate(digitCount, (index) {
                    return Center(
                      child: Text(
                        index.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFFFD96A),
                          height: 1.0,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD96A), Color(0xFFD6A54B), Color(0xFFB8873D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD96A).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  "Set Your Target",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1C1E3A),
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "Scroll the wheels to set your daily target",
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFFA0A0A8).withValues(alpha: 0.9),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Rolling Number Picker (Slot Machine Style)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF262835), Color(0xFF1A1C2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFFD96A).withValues(alpha: 0.3),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD96A).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Current Target Display
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD96A), Color(0xFFD6A54B)],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _defaultTarget.toString().padLeft(4, '0'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1C1E3A),
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Rolling Number Wheels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildNumberWheel(_thousandsController, "1000s", maxDigit: 1),
                        const SizedBox(width: 5),
                        _buildNumberWheel(_hundredsController, "100s"),
                        const SizedBox(width: 5),
                        _buildNumberWheel(_tensController, "10s"),
                        const SizedBox(width: 5),
                        _buildNumberWheel(_onesController, "1s", maxDigit: 8),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Scroll to select target (1-1008)",
                      style: TextStyle(
                        fontSize: 6,
                        color: const Color(0xFFA0A0A8).withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Switch(value: _soundEnabled, onChanged: (v) => setState(() => _soundEnabled = v)),
              const SizedBox(width: 8),
              const Text("Enable Sound"),
            ]),
            Row(children: [
              Switch(value: _tapAnywhere, onChanged: (v) => setState(() => _tapAnywhere = v)),
              const SizedBox(width: 8),
              const Text("Tap Anywhere to Count"),
            ]),
            const SizedBox(height: 20),
            // Donation Button (UPI for India, Ko-fi for International)
            Center(
              child: Builder(
                builder: (context) {
                  final isIndianUser = Localizations.localeOf(context).countryCode == 'IN';
                  
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4A90E2).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          if (isIndianUser) {
                            // UPI Payment for Indian users
                            // Replace with your UPI ID: yourname@paytm / yourname@okaxis / yourphone@ybl
                            final upiUrl = Uri.parse('upi://pay?pa=6472084641@icici&pn=MantraMala&cu=INR');
                            if (await canLaunchUrl(upiUrl)) {
                              await launchUrl(upiUrl, mode: LaunchMode.externalApplication);
                            }
                          } else {
                            // Ko-fi for International users
                            // Replace with your Ko-fi username
                            final kofiUrl = Uri.parse('https://ko-fi.com/mantramala');
                            if (await canLaunchUrl(kofiUrl)) {
                              await launchUrl(kofiUrl, mode: LaunchMode.externalApplication);
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.volunteer_activism, size: 22, color: Color(0xFFFF4444)),
                            SizedBox(width: 10),
                            Text(
                              "Support Us to Build Better",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
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
            const SizedBox(height: 24),
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
