import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class SettingsTab extends StatelessWidget {
  final VoidCallback onSetup;
  const SettingsTab({super.key, required this.onSetup});

  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder:(_,p,__) =>
      SingleChildScrollView(
        physics:const BouncingScrollPhysics(),
        padding:const EdgeInsets.fromLTRB(18,0,18,110),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          _CaptureCard(p:p, onSetup:onSetup),
          const SizedBox(height:22),
          _Section('Audio Engine'),
          _Tile(icon:Icons.memory_rounded, ic:SS.cyan, title:'DSP Engine',
            sub:'Oboe · 48 kHz · Exclusive mode', right:_Badge('Active',SS.green)),
          _Tile(icon:Icons.graphic_eq_rounded, ic:SS.amber, title:'Crossover',
            sub:'4-band Biquad · Bass/Vocal/Lead/Treble'),
          _Tile(icon:Icons.compress_rounded, ic:SS.violet, title:'Sample Rate',
            sub:'48000 Hz · PCM 16-bit stereo'),
          const SizedBox(height:22),
          _Section('Permissions'),
          _PermTile(icon:Icons.mic_rounded, title:'Microphone',
            sub:'Required for audio capture', ok:true),
          _PermTile(icon:Icons.notifications_rounded, title:'Notifications',
            sub:'Foreground service', ok:true),
          _PermTile(icon:Icons.security_rounded, title:'CAPTURE_AUDIO_OUTPUT',
            sub:p.shizuku['authorized']==true
              ?'Granted via Shizuku / ADB':'Not granted — tap to setup',
            ok:p.shizuku['authorized']??false, onTap:onSetup),
          const SizedBox(height:22),
          _Section('About'),
          _Tile(icon:Icons.spatial_audio_rounded, ic:SS.cyan,
            title:'SoundSpace', sub:'v1.0.0 · Flutter + Oboe NDK'),
          _Tile(icon:Icons.code_rounded, ic:SS.t2,
            title:'Stack', sub:'Flutter · Kotlin · C++ · Oboe · Shizuku'),
          const SizedBox(height:16),
          Center(child:Text('Made with ♥ for audiophiles',
            style:const TextStyle(color:SS.t3,fontSize:12))),
        ]),
      ),
    );
  }
}

class _CaptureCard extends StatelessWidget {
  final AudioProvider p; final VoidCallback onSetup;
  const _CaptureCard({required this.p, required this.onSetup});
  @override Widget build(BuildContext context) {
    final active = p.capturing;
    final shiz = p.shizuku['authorized']??false;
    final c = active ? SS.green : SS.pink;
    return Container(
      padding:const EdgeInsets.all(18),
      decoration:BoxDecoration(
        gradient:LinearGradient(colors:[c.withOpacity(.1),SS.card],begin:Alignment.topLeft,end:Alignment.bottomRight),
        borderRadius:BorderRadius.circular(20),border:Border.all(color:c.withOpacity(.28))),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          Container(width:42,height:42,
            decoration:BoxDecoration(color:c.withOpacity(.15),borderRadius:BorderRadius.circular(13)),
            child:Icon(active?Icons.bolt_rounded:Icons.warning_amber_rounded,color:c,size:23)),
          const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Text(active?'System Capture Active':'System Capture Off',
              style:TextStyle(color:c,fontSize:15,fontWeight:FontWeight.w700)),
            Text(active?'Processing all apps':'Test track only',
              style:const TextStyle(color:SS.t3,fontSize:11)),
          ])),
        ]),
        const SizedBox(height:14),
        Row(children:[
          _Chip('Shizuku',shiz?'Authorized':'Not ready',shiz?SS.green:SS.pink),
          const SizedBox(width:8),
          _Chip('Mode',active?p.captureMode.name:'Inactive',active?SS.cyan:SS.t3),
        ]),
        const SizedBox(height:14),
        Row(children:[
          Expanded(child:_ActBtn(
            label:active?'Stop':'Start',icon:active?Icons.stop_rounded:Icons.play_arrow_rounded,
            color:active?SS.pink:SS.cyan,
            onTap:()=>active?p.stopCapture():p.startCapture(privileged:shiz))),
          const SizedBox(width:10),
          Expanded(child:_ActBtn(label:'Shizuku Setup',icon:Icons.settings_rounded,
            color:SS.amber, onTap:onSetup)),
        ]),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final String l,v; final Color c;
  const _Chip(this.l,this.v,this.c);
  @override Widget build(_) => Container(
    padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
    decoration:BoxDecoration(color:c.withOpacity(.1),borderRadius:BorderRadius.circular(10),
      border:Border.all(color:c.withOpacity(.25))),
    child:Row(mainAxisSize:MainAxisSize.min,children:[
      Text('$l: ',style:const TextStyle(color:SS.t3,fontSize:11)),
      Text(v,style:TextStyle(color:c,fontSize:11,fontWeight:FontWeight.w700)),
    ]));
}

class _ActBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _ActBtn({required this.label,required this.icon,required this.color,required this.onTap});
  @override Widget build(_) => GestureDetector(onTap:onTap,child:Container(
    padding:const EdgeInsets.symmetric(vertical:11),
    decoration:BoxDecoration(color:color.withOpacity(.12),borderRadius:BorderRadius.circular(13),
      border:Border.all(color:color.withOpacity(.3))),
    child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
      Icon(icon,color:color,size:15),const SizedBox(width:5),
      Text(label,style:TextStyle(color:color,fontSize:12,fontWeight:FontWeight.w700)),
    ])));
}

class _Section extends StatelessWidget {
  final String t; const _Section(this.t);
  @override Widget build(_) => Padding(
    padding:const EdgeInsets.only(bottom:8),
    child:Text(t.toUpperCase(),style:const TextStyle(color:SS.t3,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:2)));
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color ic; final String title, sub; final Widget? right;
  const _Tile({required this.icon,required this.ic,required this.title,required this.sub,this.right});
  @override Widget build(_) => Container(
    margin:const EdgeInsets.only(bottom:8),
    padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),
    decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(15),border:Border.all(color:SS.border)),
    child:Row(children:[
      Container(width:36,height:36,decoration:BoxDecoration(color:ic.withOpacity(.12),borderRadius:BorderRadius.circular(10)),
        child:Icon(icon,size:18,color:ic)),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(color:SS.t1,fontSize:14,fontWeight:FontWeight.w500)),
        Text(sub,style:const TextStyle(color:SS.t3,fontSize:11)),
      ])),
      if(right!=null)...[const SizedBox(width:8),right!],
    ]));
}

class _PermTile extends StatelessWidget {
  final IconData icon; final String title,sub; final bool ok; final VoidCallback? onTap;
  const _PermTile({required this.icon,required this.title,required this.sub,required this.ok,this.onTap});
  @override Widget build(_) => GestureDetector(onTap:onTap,child:Container(
    margin:const EdgeInsets.only(bottom:8),
    padding:const EdgeInsets.symmetric(horizontal:14,vertical:13),
    decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(15),border:Border.all(color:SS.border)),
    child:Row(children:[
      Container(width:36,height:36,
        decoration:BoxDecoration(color:(ok?SS.green:SS.pink).withOpacity(.12),borderRadius:BorderRadius.circular(10)),
        child:Icon(icon,size:18,color:ok?SS.green:SS.pink)),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(title,style:const TextStyle(color:SS.t1,fontSize:14,fontWeight:FontWeight.w500)),
        Text(sub,style:const TextStyle(color:SS.t3,fontSize:11)),
      ])),
      _Badge(ok?'Granted':'Missing',ok?SS.green:SS.pink),
    ])));
}

class _Badge extends StatelessWidget {
  final String l; final Color c; const _Badge(this.l,this.c);
  @override Widget build(_) => Container(
    padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),
    decoration:BoxDecoration(color:c.withOpacity(.12),borderRadius:BorderRadius.circular(9),
      border:Border.all(color:c.withOpacity(.3))),
    child:Text(l,style:TextStyle(color:c,fontSize:11,fontWeight:FontWeight.w700)));
}
