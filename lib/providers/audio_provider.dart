import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class AudioProvider extends ChangeNotifier {
  final List<SoundSource> sources = SoundSource.defaults();
  int selectedIndex = 2;
  SoundSource get selected => sources[selectedIndex];

  double roomSize = 0.40, stereoWidth = 0.80, masterVol = 0.85;
  List<double> eqBands = List.filled(5, 0.0);
  String? activePreset = 'Flat';
  bool rotationOn = false, reverbOn = true;
  double rotSpeed = 0.18;
  bool capturing = false;

  final _player = AudioPlayer();
  bool playing = false;
  Timer? _rotTimer;
  double _rotAngle = 0;
  static const _rotRadius = 0.36;

  AudioProvider() {
    _player.playerStateStream.listen((s) { playing = s.playing; notifyListeners(); });
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      roomSize = p.getDouble('roomSize') ?? 0.40;
      stereoWidth = p.getDouble('stereoWidth') ?? 0.80;
      masterVol = p.getDouble('masterVol') ?? 0.85;
      rotationOn = p.getBool('rotation') ?? false;
      reverbOn = p.getBool('reverb') ?? true;
      rotSpeed = p.getDouble('rotSpeed') ?? 0.18;
      activePreset = p.getString('preset') ?? 'Flat';
      final b = p.getStringList('eq');
      if (b != null && b.length == 5) eqBands = b.map(double.parse).toList();
      if (rotationOn) _startRotation();
    } catch (e) { debugPrint('Load error: $e'); }
    notifyListeners();
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setDouble('roomSize', roomSize);
      await p.setDouble('stereoWidth', stereoWidth);
      await p.setDouble('masterVol', masterVol);
      await p.setBool('rotation', rotationOn);
      await p.setBool('reverb', reverbOn);
      await p.setDouble('rotSpeed', rotSpeed);
      if (activePreset != null) await p.setString('preset', activePreset!);
      await p.setStringList('eq', eqBands.map((e) => e.toString()).toList());
    } catch (e) { debugPrint('Save error: $e'); }
  }

  void selectSource(int i) { selectedIndex = i; notifyListeners(); }

  void moveSource(Offset pos) {
    sources[selectedIndex] = sources[selectedIndex].clone(
      pos: Offset(pos.dx.clamp(0.03, 0.97), pos.dy.clamp(0.03, 0.97)));
    _applyPan(); notifyListeners();
  }

  void setGain(int i, double g) { sources[i] = sources[i].clone(gain: g.clamp(0,1.5)); _applyPan(); notifyListeners(); }
  void toggleMute(int i) { sources[i] = sources[i].clone(muted: !sources[i].muted); _applyPan(); notifyListeners(); }
  void toggleSolo(int i) {
    final was = sources[i].soloed;
    for (var k = 0; k < sources.length; k++) sources[k] = sources[k].clone(soloed: false);
    if (!was) sources[i] = sources[i].clone(soloed: true);
    _applyPan(); notifyListeners();
  }

  void setRoomSize(double v)    { roomSize = v.clamp(0,1); _save(); notifyListeners(); }
  void setStereoWidth(double v) { stereoWidth = v.clamp(0,1); _save(); notifyListeners(); }
  void setMasterVol(double v)   { masterVol = v.clamp(0,1); _player.setVolume(_vol); notifyListeners(); }

  void setEQBand(int i, double dB) { eqBands[i] = dB.clamp(-12,12); activePreset = null; _save(); notifyListeners(); }
  void applyPreset(EQPreset p) { eqBands = List.from(p.bands); activePreset = p.name; _save(); notifyListeners(); }
  void resetEQ() { eqBands = List.filled(5, 0.0); activePreset = 'Flat'; _save(); notifyListeners(); }

  void toggleRotation() { rotationOn = !rotationOn; rotationOn ? _startRotation() : _stopRotation(); _save(); notifyListeners(); }
  void setRotSpeed(double v) { rotSpeed = v.clamp(0.05, 2.0); _save(); notifyListeners(); }
  void toggleReverb() { reverbOn = !reverbOn; _save(); notifyListeners(); }

  void _startRotation() {
    _rotTimer?.cancel();
    DateTime last = DateTime.now();
    _rotTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(last).inMicroseconds / 1e6;
      last = now;
      _rotAngle = (_rotAngle + rotSpeed * 2 * math.pi * dt) % (2 * math.pi);
      for (var k = 0; k < sources.length; k++) {
        final a = _rotAngle + k * math.pi / 2;
        sources[k] = sources[k].clone(pos: Offset(
          (0.5 + _rotRadius * math.cos(a)).clamp(0.05, 0.95),
          (0.5 + _rotRadius * math.sin(a)).clamp(0.05, 0.95),
        ));
      }
      _applyPan(); notifyListeners();
    });
  }

  void _stopRotation() { _rotTimer?.cancel(); _rotTimer = null; }

  void _applyPan() { _player.setVolume(_vol); }

  double get _vol {
    final active = sources.where((s) => !s.muted);
    if (active.isEmpty) return 0;
    final avgY = active.map((s) => s.pos.dy).reduce((a,b) => a+b) / active.length;
    return ((0.4 + (1-avgY)*0.6)*masterVol).clamp(0.0,1.0);
  }

  Future<void> togglePlay() async {
    if (playing) {
      await _player.stop(); playing = false; notifyListeners();
    } else {
      try {
        await _player.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
        await _player.setVolume(_vol); await _player.play();
      } catch (e) { debugPrint('Play error: $e'); }
    }
  }

  Future<void> startCapture() async { capturing = true; notifyListeners(); }
  Future<void> stopCapture() async { capturing = false; notifyListeners(); }

  @override
  void dispose() { _rotTimer?.cancel(); _player.dispose(); super.dispose(); }
}