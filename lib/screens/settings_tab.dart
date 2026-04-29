import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';
import 'setup_wizard.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder:(_,p,__) =>
      SingleChildScrollView(
        physics:const BouncingScrollPhysics(),
        padding:const EdgeInsets.fromLTRB(20,0,20,100),
        child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          const Text('Spatial Engine',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:SS.t1)),
          const SizedBox(height:20),
          _Section('Room Acoustics',[
            _Slider('Room Size', p.roomSize, 0, 1, (v)=>p.setRoomSize(v),
              left:'Dry', right:'Reverberant'),
            _Slider('Stereo Width', p.stereoWidth, 0, 1, (v)=>p.setStereoWidth(v),
              left:'Mono', right:'Wide'),
          ]),
          const SizedBox(height:16),
          _Section('Rotation',[
            _Toggle('Auto Rotate', p.rotationOn, ()=>p.toggleRotation()),
            if(p.rotationOn)
              _Slider('Speed', p.rotSpeed, 0.05, 2.0, (v)=>p.setRotSpeed(v),
                left:'Slow', right:'Fast'),
          ]),
          const SizedBox(height:16),
          _Section('Reverb',[
            _Toggle('Reverb FX', p.reverbOn, ()=>p.toggleReverb()),
          ]),
          const SizedBox(height:16),
          _Section('System Audio Capture',[
            _CaptureRow(p, context),
          ]),
          const SizedBox(height:16),
          _Section('About',[
            _InfoRow('Version','1.0.0'),
            _InfoRow('Flutter','3.x'),
            _InfoRow('Audio Engine','just_audio 0.9'),
          ]),
        ]),
      ),
    );
  }
}

class _CaptureRow extends StatelessWidget {
  final AudioProvider p; final BuildContext ctx;
  const _CaptureRow(this.p, this.ctx);
  @override Widget build(BuildContext context) {
    return Padding(padding:const EdgeInsets.symmetric(vertical:6), child:
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Text('Capture Status',style:const TextStyle(color:SS.t1,fontSize:14,fontWeight:FontWeight.w500)),
          const SizedBox(height:2),
          Text(p.capturing?'Active':'Inactive',
            style:TextStyle(color:p.capturing?SS.green:SS.t3,fontSize:12)),
        ]),
        Row(children:[
          if(!p.capturing)
            TextButton(onPressed:(){
              HapticFeedback.lightImpact();
              Navigator.push(ctx,MaterialPageRoute(builder:(_)=>const SetupWizard()));
            }, child:const Text('Setup',style:TextStyle(color:SS.cyan,fontSize:13))),
          const SizedBox(width:8),
          GestureDetector(
            onTap:(){ HapticFeedback.mediumImpact();
              p.capturing ? p.stopCapture() : p.startCapture(); },
            child:AnimatedContainer(duration:const Duration(milliseconds:200),
              padding:const EdgeInsets.symmetric(horizontal:16,vertical:8),
              decoration:BoxDecoration(
                color:p.capturing?SS.green.withOpacity(.15):SS.raised,
                borderRadius:BorderRadius.circular(20),
                border:Border.all(color:p.capturing?SS.green.withOpacity(.4):SS.border)),
              child:Text(p.capturing?'Stop':'Start',
                style:TextStyle(color:p.capturing?SS.green:SS.t1,
                  fontSize:13,fontWeight:FontWeight.w600)))),
        ]),
      ]));
  }
}

class _Section extends StatelessWidget {
  final String title; final List<Widget> children;
  const _Section(this.title, this.children);
  @override Widget build(BuildContext context) => Container(
    padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(18),border:Border.all(color:SS.border)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Text(title,style:const TextStyle(color:SS.t2,fontSize:12,fontWeight:FontWeight.w600,letterSpacing:.5)),
      const SizedBox(height:12),
      ...children,
    ]));
}

class _Toggle extends StatelessWidget {
  final String label; final bool value; final VoidCallback onTap;
  const _Toggle(this.label, this.value, this.onTap);
  @override Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.symmetric(vertical:6),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(label,style:const TextStyle(color:SS.t1,fontSize:14,fontWeight:FontWeight.w500)),
      GestureDetector(onTap:(){ HapticFeedback.lightImpact(); onTap(); },
        child:AnimatedContainer(duration:const Duration(milliseconds:180),
          width:44,height:26,
          decoration:BoxDecoration(
            color:value?SS.cyan.withOpacity(.9):SS.border,
            borderRadius:BorderRadius.circular(13)),
          child:AnimatedAlign(duration:const Duration(milliseconds:180),
            alignment:value?Alignment.centerRight:Alignment.centerLeft,
            child:Container(margin:const EdgeInsets.all(3),width:20,height:20,
              decoration:const BoxDecoration(color:Colors.white,shape:BoxShape.circle))))),
    ]));
}

class _Slider extends StatelessWidget {
  final String label; final double value, min, max;
  final ValueChanged<double> onChange; final String left, right;
  const _Slider(this.label,this.value,this.min,this.max,this.onChange,{required this.left,required this.right});
  @override Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.symmetric(vertical:6),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
        Text(label,style:const TextStyle(color:SS.t1,fontSize:14,fontWeight:FontWeight.w500)),
        Text('${(value*100).round()}%',style:const TextStyle(color:SS.t3,fontSize:12)),
      ]),
      const SizedBox(height:6),
      SliderTheme(data:SliderThemeData(
        trackHeight:3,thumbRadius:8,
        activeTrackColor:SS.cyan,inactiveTrackColor:SS.border,thumbColor:Colors.white,
        overlayShape:SliderComponentShape.noOverlay),
        child:Slider(value:value,min:min,max:max,onChanged:(v){ HapticFeedback.selectionClick(); onChange(v); })),
      Padding(padding:const EdgeInsets.symmetric(horizontal:4),
        child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
          Text(left,style:const TextStyle(color:SS.t3,fontSize:10)),
          Text(right,style:const TextStyle(color:SS.t3,fontSize:10)),
        ])),
    ]));
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);
  @override Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.symmetric(vertical:5),
    child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
      Text(label,style:const TextStyle(color:SS.t2,fontSize:13)),
      Text(value,style:const TextStyle(color:SS.t3,fontSize:13)),
    ]));
}