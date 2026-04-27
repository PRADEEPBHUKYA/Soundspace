import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class CaptureBanner extends StatefulWidget {
  final VoidCallback onTap;
  const CaptureBanner({super.key, required this.onTap});
  @override State<CaptureBanner> createState() => _CaptureBannerState();
}

class _CaptureBannerState extends State<CaptureBanner> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync:this, duration:const Duration(milliseconds:900))..repeat(reverse:true);
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder:(_,p,__){
      final c = p.capturing ? SS.green : const Color(0xFFFF9500);
      final label = p.capturing ? 'SYSTEM CAPTURE: ACTIVE' : 'SYSTEM CAPTURE: TAP TO ENABLE';
      final sub = p.capturing ? 'Spatializing audio from all apps' : 'Requires ADB permission (see Settings)';
      return GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration:const Duration(milliseconds:300),
          padding:const EdgeInsets.symmetric(horizontal:14, vertical:11),
          decoration:BoxDecoration(
            color:c.withOpacity(.07), borderRadius:BorderRadius.circular(16),
            border:Border.all(color:c.withOpacity(.25))),
          child:Row(children:[
            AnimatedBuilder(animation:_pulse, builder:(_,__) {
              final pulseOp = p.capturing ? (0.5 + _pulse.value * 0.5) : 0.9;
              final shadowOp = p.capturing ? (0.4 * _pulse.value) : 0.0;
              return Container(
                width:9, height:9,
                decoration:BoxDecoration(shape:BoxShape.circle,
                  color:c.withOpacity(pulseOp),
                  boxShadow:p.capturing ? [BoxShadow(color:c.withOpacity(shadowOp), blurRadius:6, spreadRadius:2)] : []),
              );
            }),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              Text(label, style:TextStyle(color:c, fontSize:11, fontWeight:FontWeight.w700)),
              const SizedBox(height:1),
              Text(sub, style:const TextStyle(color:SS.t3, fontSize:10)),
            ])),
            Icon(Icons.chevron_right_rounded, color:c.withOpacity(.4), size:16),
          ]),
        ),
      );
    });
  }
}