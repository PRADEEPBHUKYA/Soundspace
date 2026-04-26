import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class SourceRow extends StatelessWidget {
  const SourceRow({super.key});
  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder: (_, p, __) {
      return SizedBox(height: 88,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          itemCount: p.sources.length,
          itemBuilder: (ctx, i) {
            final s = p.sources[i];
            final sel = p.selectedIndex == i;
            return GestureDetector(
              onTap: () { HapticFeedback.selectionClick(); p.selectSource(i); },
              onLongPress: () { HapticFeedback.mediumImpact(); _sheet(ctx, p, i); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 80, margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? s.color.withOpacity(.12) : SS.raised,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: sel ? s.color.withOpacity(.55) : SS.border,
                    width: sel ? 1.8 : 1),
                  boxShadow: sel ? [BoxShadow(color: s.color.withOpacity(.2), blurRadius:10)] : [],
                ),
                child: Stack(children: [
                  if (s.muted) Positioned(top:6, right:6,
                    child: Container(width:7,height:7,decoration:const BoxDecoration(color:SS.pink,shape:BoxShape.circle))),
                  if (s.soloed && !s.muted) Positioned(top:6, right:6,
                    child: Container(width:7,height:7,decoration:const BoxDecoration(color:SS.amber,shape:BoxShape.circle))),
                  Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const SizedBox(width: double.infinity),
                    Icon(s.icon, size: 24,
                      color: sel ? s.color : s.muted ? SS.t3 : SS.t2),
                    const SizedBox(height: 5),
                    Text(s.name, style: TextStyle(
                      fontSize: 11, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                      color: sel ? Colors.white : SS.t2)),
                  ]),
                ]),
              ),
            );
          },
        ),
      );
    });
  }

  void _sheet(BuildContext ctx, AudioProvider p, int i) {
    final s = p.sources[i];
    showModalBottomSheet(
      context: ctx, useRootNavigator: true,
      backgroundColor: SS.raised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => StatefulBuilder(builder: (ctx2, setState) {
        return SafeArea(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width:36,height:4,margin:const EdgeInsets.only(bottom:18),
              decoration: BoxDecoration(color:SS.border,borderRadius:BorderRadius.circular(2))),
            Row(children: [
              Container(width:42,height:42,
                decoration:BoxDecoration(color:s.color.withOpacity(.15),shape:BoxShape.circle),
                child:Icon(s.icon,color:s.color,size:22)),
              const SizedBox(width:14),
              Text(s.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w600,color:SS.t1)),
            ]),
            const SizedBox(height:20),
            Row(children:[
              const Text('Gain',style:TextStyle(color:SS.t2,fontSize:13)),
              const Spacer(),
              Text('${(s.gain*100).toInt()}%',style:const TextStyle(color:SS.cyan,fontSize:13,fontWeight:FontWeight.w600)),
            ]),
            SliderTheme(data: SliderTheme.of(ctx2).copyWith(activeTrackColor:s.color,thumbColor:s.color),
              child: Slider(value:s.gain,min:0,max:1.5,
                onChanged:(v){ p.setGain(i,v); setState((){}); })),
            const SizedBox(height:4),
            Row(children:[
              Expanded(child:_Btn(
                icon:s.muted?Icons.volume_up_rounded:Icons.volume_off_rounded,
                label:s.muted?'Unmute':'Mute', color:SS.pink,
                onTap:(){ p.toggleMute(i); Navigator.pop(ctx2); })),
              const SizedBox(width:12),
              Expanded(child:_Btn(
                icon:Icons.headphones_rounded,
                label:s.soloed?'Un-solo':'Solo', color:SS.amber,
                onTap:(){ p.toggleSolo(i); Navigator.pop(ctx2); })),
              const SizedBox(width:12),
              Expanded(child:_Btn(
                icon:Icons.center_focus_strong_rounded,
                label:'Center', color:SS.violet,
                onTap:(){ p.moveSource(const Offset(.5,.5)); Navigator.pop(ctx2); })),
            ]),
          ]),
        ));
      }),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _Btn({required this.icon,required this.label,required this.color,required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical:13),
      decoration:BoxDecoration(
        color:color.withOpacity(.1),borderRadius:BorderRadius.circular(14),
        border:Border.all(color:color.withOpacity(.3))),
      child:Column(children:[
        Icon(icon,color:color,size:20),
        const SizedBox(height:4),
        Text(label,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.w600)),
      ]),
    ),
  );
}
