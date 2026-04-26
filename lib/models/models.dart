import 'package:flutter/material.dart';
import '../theme/theme.dart';

// ── Sound Source ─────────────────────────────────────────────────────────────
class SoundSource {
  final String id, name;
  final Color color;
  final IconData icon;
  Offset pos;
  double gain;
  bool muted, soloed;

  SoundSource({
    required this.id, required this.name,
    required this.color, required this.icon,
    this.pos = const Offset(.5, .5),
    this.gain = 1.0, this.muted = false, this.soloed = false,
  });

  SoundSource clone({Offset? pos, double? gain, bool? muted, bool? soloed}) => SoundSource(
    id: id, name: name, color: color, icon: icon,
    pos: pos ?? this.pos, gain: gain ?? this.gain,
    muted: muted ?? this.muted, soloed: soloed ?? this.soloed,
  );

  static List<SoundSource> defaults() => [
    SoundSource(id:'bass',   name:'Bass',   color:SS.bassC,   icon:Icons.speaker_rounded,           pos:const Offset(.28,.70)),
    SoundSource(id:'vocal',  name:'Vocal',  color:SS.vocalC,  icon:Icons.mic_rounded,               pos:const Offset(.50,.28)),
    SoundSource(id:'treble', name:'Treble', color:SS.trebleC, icon:Icons.high_quality_rounded,      pos:const Offset(.72,.62)),
    SoundSource(id:'lead',   name:'Lead',   color:SS.leadC,   icon:Icons.music_note_rounded,        pos:const Offset(.44,.76)),
  ];
}

// ── EQ Preset ────────────────────────────────────────────────────────────────
class EQPreset {
  final String name;
  final List<double> bands; // 5 bands, dB -12..+12
  const EQPreset(this.name, this.bands);

  static const all = [
    EQPreset('Flat',        [ 0,  0,  0,  0,  0]),
    EQPreset('Studio',      [ 2,  1,  0,  1,  3]),
    EQPreset('Bass Boost',  [ 9,  6,  0, -2, -1]),
    EQPreset('Vocal',       [-2,  0,  5,  4,  2]),
    EQPreset('Electronic',  [ 6,  2, -1,  3,  5]),
    EQPreset('Classical',   [ 3,  0, -2,  0,  4]),
    EQPreset('Night Mode',  [-3,  2,  4,  2, -1]),
    EQPreset('Hip-Hop',     [ 7,  4,  1,  0,  2]),
  ];
}
