import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class RoomControls extends StatelessWidget {
  const RoomControls({super.key});
  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder: (_, p, __) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        _label('Acoustics'),
        const SizedBox(height:8),
        _Slider(icon:Icons.zoom_out_map_rounded, label:'Room Size',
          value:p.roomSize, color:SS.cyan,
          display:'${(p.roomSize*100).toInt()}%', onChanged:p.setRoomSize),
        const SizedBox(height:10),
        _Slider(icon:Icons.unfold_more_rounded, label:'Stereo Width',
          value:p.stereoWidth, color:SS.violet,
          display:'${(p.stereoWidth*100).toInt()}%', onChanged:p.setStereoWidth),
        const SizedBox(height:10),
        _Slider(icon:Icons.volume_up_rounded, label:'Master Volume',
          value:p.masterVol, color:SS.green,
          display:'${(p.masterVol*100).toInt()}%', onChanged:p.setMasterVol),
        const SizedBox(height:22),
        _label('Effects'),
        const SizedBox(height:8),
        _Toggle(icon:Icons.sync_rounded, label:'Auto 8D Rotation',
          sub:'Circular spatial sweep', value:p.rotationOn,
          color:SS.cyan, onTap:p.toggleRotation),
        if (p.rotationOn) ...[
          const SizedBox(height:8),
          _Slider(icon:Icons.speed_rounded, label:'Rotation Speed',
            value:(p.rotSpeed-.05)/1.95, color:SS.cyan,
            display:'${p.rotSpeed.toStringAsFixed(2)} Hz',
            onChanged:(v)=>p.setRotSpeed(.05+v*1.95)),
        ],
        const SizedBox(height:10),
        _Toggle(icon:Icons.surround_sound_rounded, label:'Room Reverb',
          sub:'Acoustic space simulation', value:p.reverbOn,
          color:SS.pink, onTap:p.toggleReverb),
      ],
    ));
  }

  Widget _label(String t) => Text(t.toUpperCase(), style:const TextStyle(
    color:SS.t3, fontSize:10, fontWeight:FontWeight.w700, letterSpacing:2));
}

class _Slider extends StatelessWidget {
  final IconData icon; final String label, display;
  final double value; final Color color; final ValueChanged<double> onChanged;
  const _Slider({required this.icon,required this.label,required this.display,
    required this.value,required this.color,required this.onChanged});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14,12,14,8),
    decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(16),border:Border.all(color:SS.border)),
    child: Row(children:[
      Icon(icon,size:18,color:color.withOpacity(.8)),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text(label,style:const TextStyle(color:SS.t2,fontSize:13)),
          Text(display,style:TextStyle(color:color,fontSize:12,fontWeight:FontWeight.w700)),
        ]),
        SliderTheme(data:SliderTheme.of(context).copyWith(
          activeTrackColor:color,thumbColor:color,
          overlayColor:color.withOpacity(.15)),
          child:Slider(value:value.clamp(0,1),onChanged:onChanged)),
      ])),
    ]),
  );
}

class _Toggle extends StatelessWidget {
  final IconData icon; final String label, sub;
  final bool value; final Color color; final VoidCallback onTap;
  const _Toggle({required this.icon,required this.label,required this.sub,
    required this.value,required this.color,required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal:14,vertical:13),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(.08) : SS.raised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: value ? color.withOpacity(.3) : SS.border)),
      child: Row(children:[
        Icon(icon, color: value ? color : SS.t2, size:22),
        const SizedBox(width:14),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label, style:TextStyle(color:value?SS.t1:SS.t2,fontSize:14,fontWeight:FontWeight.w500)),
          Text(sub, style:const TextStyle(color:SS.t3,fontSize:11)),
        ])),
        Switch(value:value, onChanged:(_)=>onTap(),
          activeColor:color, activeTrackColor:color.withOpacity(.3),
          inactiveTrackColor:SS.border,
          materialTapTargetSize:MaterialTapTargetSize.shrinkWrap),
      ]),
    ),
  );
}
