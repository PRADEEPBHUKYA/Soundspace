import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class PlayButton extends StatefulWidget {
  const PlayButton({super.key});
  @override State<PlayButton> createState() => _PlayButtonState();
}

class _PlayButtonState extends State<PlayButton> with SingleTickerProviderStateMixin {
  late final _sc = AnimationController(vsync:this,duration:const Duration(milliseconds:90),
    lowerBound:.93,upperBound:1.0,value:1.0);
  @override void dispose() { _sc.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder:(_, p, __){
      final c = p.playing ? SS.pink : SS.cyan;
      return ScaleTransition(scale:_sc, child:GestureDetector(
        onTapDown:(_)=>_sc.reverse(),
        onTapUp:(_){ _sc.forward(); HapticFeedback.mediumImpact(); p.togglePlay(); },
        onTapCancel:()=>_sc.forward(),
        child:AnimatedContainer(
          duration:const Duration(milliseconds:300),
          width:74,height:74,
          decoration:BoxDecoration(
            shape:BoxShape.circle, color:c,
            boxShadow:[BoxShadow(color:c.withOpacity(.45),blurRadius:24,spreadRadius:2)]),
          child:AnimatedSwitcher(
            duration:const Duration(milliseconds:180),
            child:Icon(
              p.playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              key:ValueKey(p.playing), color:Colors.white, size:36)),
        ),
      ));
    });
  }
}
