import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

enum CaptureMode { none, mediaProjection, shizuku }

class AudioProvider extends ChangeNotifier {
  // ── Sources ───────────────────────────────────────────────────────────────
  final List<SoundSource> sources = SoundSource.defaults();
  int selectedIndex = 2; // Treble selected by default

  SoundSource get selected => sources[selectedIndex];

  // ── Spatial params ────────────────────────────────────────────────────────
  double roomSize    = 0.40;
  double stereoWidth = 0.80;
  double masterVol   = 0.85;

  // ── EQ ────────────────────────────────────────────────────────────────────
  List<double> eqBands = List.filled(5, 0.0);
  String? activePreset = 'Flat';

  // ── Effects ───────────────────────────────────────────────────────────────
  bool rotationOn  = false;
  bool reverbOn    = true;
  bool is8D        = false;
  double rotSpeed  = 0.18; // Hz

  // ── Capture ───────────────────────────────────────────────────────────────
  CaptureMode captureMode = CaptureMode.none;
  Map<String,bool> shizuku = {'installed':false,'running':false,'authorized':false};
  bool get capturing => captureMode != CaptureMode.none;

  // ── Playback ──────────────────────────────────────────────────────────────
  final _player = AudioPlayer();
  bool playing = false;

  // ── Rotation ─────────────────────────────────────────────────────────────
  Timer? _rotTimer;
  double _rotAngle = 0;
  static const _rotRadius = 0.36;

  // ── Channel ───────────────────────────────────────────────────────────────
  static const _ch = MethodChannel('com.example.soundspace/audio_engine');

  // ── Init ─────────────────────────────────────────────────────────────────
  AudioProvider() {
    _player.playerStateStream.listen((s) {
      playing = s.playing; notifyListeners();
    });
    _load();
    _checkShizukuSilent();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    roomSize    = p.getDouble('roomSize')    ?? 0.40;
    stereoWidth = p.getDouble('stereoWidth') ?? 0.80;
    masterVol   = p.getDouble('masterVol')   ?? 0.85;
    rotationOn  = p.getBool('rotation')      ?? false;
    reverbOn    = p.getBool('reverb')        ?? true;
    rotSpeed    = p.getDouble('rotSpeed')    ?? 0.18;
    activePreset= p.getString('preset')      ?? 'Flat';
    final b = p.getStringList('eq');
    if (b != null && b.length == 5) eqBands = b.map(double.parse).toList();
    if (rotationOn) _startRotation();
    notifyListeners();
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('roomSize', roomSize);
    await p.setDouble('stereoWidth', stereoWidth);
    await p.setDouble('masterVol', masterVol);
    await p.setBool('rotation', rotationOn);
    await p.setBool('reverb', reverbOn);
    await p.setDouble('rotSpeed', rotSpeed);
    if (activePreset != null) await p.setString('preset', activePreset!);
    await p.setStringList('eq', eqBands.map((e) => e.toString()).toList());
  }

  // ── Source ────────────────────────────────────────────────────────────────
  void selectSource(int i) { selectedIndex = i; notifyListeners(); }

  void moveSource(Offset pos) {
    sources[selectedIndex] = sources[selectedIndex].clone(
      pos: Offset(pos.dx.clamp(.03,.97), pos.dy.clamp(.03,.97)));
    _pushNative(); notifyListeners();
  }

  void setGain(int i, double g) {
    sources[i] = sources[i].clone(gain: g.clamp(0,1.5));
    _pushNative(); notifyListeners();
  }

  void toggleMute(int i) {
    sources[i] = sources[i].clone(muted: !sources[i].muted);
    _pushNative(); notifyListeners();
  }

  void toggleSolo(int i) {
    final was = sources[i].soloed;
    for (var k = 0; k < sources.length; k++)
      sources[k] = sources[k].clone(soloed: false);
    if (!was) sources[i] = sources[i].clone(soloed: true);
    _pushNative(); notifyListeners();
  }

  // ── Room ─────────────────────────────────────────────────────────────────
  void setRoomSize(double v)    { roomSize=v.clamp(0,1); _ch.invokeMethod('setRoomSize',{'size':v}).catchError((_){}); _save(); notifyListeners(); }
  void setStereoWidth(double v) { stereoWidth=v.clamp(0,1); _ch.invokeMethod('setStereoWidth',{'width':v}).catchError((_){}); _save(); notifyListeners(); }
  void setMasterVol(double v)   { masterVol=v.clamp(0,1); _player.setVolume(_overallVol); notifyListeners(); }

  // ── EQ ───────────────────────────────────────────────────────────────────
  void setEQBand(int i, double dB) {
    eqBands[i] = dB.clamp(-12,12); activePreset = null;
    _ch.invokeMethod('setEq',{'bands':eqBands}).catchError((_){}); _save(); notifyListeners();
  }

  void applyPreset(EQPreset p) {
    eqBands = List.from(p.bands); activePreset = p.name;
    _ch.invokeMethod('setEq',{'bands':eqBands}).catchError((_){}); _save(); notifyListeners();
  }

  void resetEQ() { eqBands = List.filled(5,0); activePreset='Flat'; _save(); notifyListeners(); }

  // ── Effects ───────────────────────────────────────────────────────────────
  void toggleRotation() {
    rotationOn = !rotationOn;
    rotationOn ? _startRotation() : _stopRotation();
    _save(); notifyListeners();
  }

  void setRotSpeed(double v) { rotSpeed=v.clamp(.05,2); _rotEngine.speed=v; _save(); notifyListeners(); }
  void toggleReverb() { reverbOn=!reverbOn; _ch.invokeMethod('setReverb',{'on':reverbOn}).catchError((_){}); _save(); notifyListeners(); }

  // ── Rotation engine ───────────────────────────────────────────────────────
  _RotEngine _rotEngine = _RotEngine();

  void _startRotation() {
    _rotTimer?.cancel();
    _rotEngine = _RotEngine()..speed = rotSpeed;
    DateTime last = DateTime.now();
    _rotTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final dt = now.difference(last).inMicroseconds / 1e6;
      last = now;
      _rotAngle = (_rotAngle + rotSpeed * 2 * math.pi * dt) % (2 * math.pi);
      for (var k = 0; k < sources.length; k++) {
        final offset = k * math.pi / 2;
        final a = _rotAngle + offset;
        sources[k] = sources[k].clone(
          pos: Offset(
            (.5 + _rotRadius * math.cos(a)).clamp(.05,.95),
            (.5 + _rotRadius * math.sin(a)).clamp(.05,.95),
          ));
      }
      _pushNative(); notifyListeners();
    });
  }

  void _stopRotation() { _rotTimer?.cancel(); _rotTimer = null; }

  // ── Playback ─────────────────────────────────────────────────────────────
  Future<void> togglePlay() async {
    if (playing) {
      await _player.stop(); playing = false; notifyListeners();
    } else {
      try {
        await _player.setUrl('https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3');
        await _player.setVolume(_overallVol);
        await _player.play();
      } catch (e) { debugPrint('play error: $e'); }
    }
  }

  double get _overallVol {
    final active = sources.where((s) => !s.muted);
    if (active.isEmpty) return 0;
    final avgY = active.map((s) => s.pos.dy).reduce((a,b)=>a+b) / active.length;
    return ((0.4 + (1-avgY)*0.6) * masterVol).clamp(0,1);
  }

  double get _overallPan {
    final active = sources.where((s) => !s.muted).toList();
    if (active.isEmpty) return 0;
    final avgX = active.map((s) => s.pos.dx).reduce((a,b)=>a+b) / active.length;
    return ((avgX * 2) - 1).clamp(-1,1);
  }

  void _pushNative() {
    _player.setVolume(_overallVol);
    _player.setPan(_overallPan);
    for (final s in sources) {
      _ch.invokeMethod('updateParams',{
        'id':s.id,'x':s.pos.dx,'y':s.pos.dy,'gain':s.gain,'muted':s.muted
      }).catchError((_){});
    }
  }

  // ── Capture ───────────────────────────────────────────────────────────────
  Future<void> _checkShizukuSilent() async {
    try {
      final m = await _ch.invokeMethod('checkShizuku') as Map;
      shizuku = Map<String,bool>.from(m);
      if (shizuku['authorized']==true) captureMode = CaptureMode.shizuku;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> checkShizuku() => _checkShizukuSilent();

  Future<bool> startCapture({bool privileged=false}) async {
    try {
      final ok = await _ch.invokeMethod('startCapture',{'privileged':privileged}) as bool;
      if (ok) { captureMode = privileged ? CaptureMode.shizuku : CaptureMode.mediaProjection; notifyListeners(); }
      return ok;
    } catch (_) { return false; }
  }

  Future<void> stopCapture() async {
    try { await _ch.invokeMethod('stopCapture'); } catch (_) {}
    captureMode = CaptureMode.none; notifyListeners();
  }

  @override
  void dispose() { _rotTimer?.cancel(); _player.dispose(); super.dispose(); }
}

class _RotEngine { double speed = 0.18; }
