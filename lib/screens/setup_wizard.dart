import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';

class SetupWizard extends StatelessWidget {
  const SetupWizard({super.key});

  static const _adb =
      'adb shell pm grant com.example.soundspace android.permission.CAPTURE_AUDIO_OUTPUT';

  @override Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SS.bg,
      appBar: AppBar(backgroundColor:Colors.transparent,
        title:const Text('Enable System Capture',
          style:TextStyle(fontSize:17, fontWeight:FontWeight.w600)),
        leading:IconButton(icon:const Icon(Icons.close_rounded, color:SS.t2),
          onPressed:()=>Navigator.pop(context))),
      body: SafeArea(child: SingleChildScrollView(
        padding:const EdgeInsets.all(28),
        child:Column(children:[
          const SizedBox(height:16),
          Container(width:96, height:96,
            decoration:BoxDecoration(color:SS.cyan.withOpacity(.1), shape:BoxShape.circle,
              border:Border.all(color:SS.cyan.withOpacity(.3), width:2)),
            child:const Icon(Icons.verified_user_rounded, size:48, color:SS.cyan)),
          const SizedBox(height:24),
          const Text('One ADB Command', textAlign:TextAlign.center,
            style:TextStyle(fontSize:22, fontWeight:FontWeight.w700, color:SS.t1)),
          const SizedBox(height:10),
          const Text(
            'To spatialize audio from all apps, run this command from your PC.',
            textAlign:TextAlign.center,
            style:TextStyle(color:SS.t2, fontSize:15, height:1.55)),
          const SizedBox(height:24),
          _Step('1', 'Enable USB Debugging',
            'Settings > About Phone > tap Build Number 7 times', SS.cyan),
          const SizedBox(height:10),
          _Step('2', 'Download ADB Platform Tools',
            'developer.android.com/tools/releases/platform-tools', SS.amber),
          const SizedBox(height:10),
          _Step('3', 'Run the command below', '', SS.green),
          const SizedBox(height:10),
          Container(width:double.infinity, padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(color:Colors.black54, borderRadius:BorderRadius.circular(16),
              border:Border.all(color:SS.cyan.withOpacity(.25))),
            child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
              const Text('COMMAND', style:TextStyle(color:SS.cyan, fontSize:9, fontWeight:FontWeight.w700, letterSpacing:1.5)),
              const SizedBox(height:8),
              const SelectableText(_adb,
                style:TextStyle(color:SS.t1, fontSize:11, fontFamily:'monospace', height:1.6)),
              const SizedBox(height:8),
              GestureDetector(
                onTap:(){ Clipboard.setData(const ClipboardData(text:_adb));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:Text('Copied!'), duration:Duration(seconds:1)));},
                child:const Row(children:[
                  Icon(Icons.copy_rounded, size:13, color:SS.cyan),
                  SizedBox(width:4),
                  Text('Copy', style:TextStyle(color:SS.cyan, fontSize:11, fontWeight:FontWeight.w600))])),
            ])),
          const SizedBox(height:24),
          SizedBox(width:double.infinity, height:52,
            child:ElevatedButton(
              onPressed:()=>Navigator.pop(context),
              style:ElevatedButton.styleFrom(backgroundColor:SS.cyan, foregroundColor:Colors.black,
                shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),
              child:const Text('Got it', style:TextStyle(fontWeight:FontWeight.w700, fontSize:16)))),
        ]),
      )),
    );
  }
}

class _Step extends StatelessWidget {
  final String num, title, sub; final Color color;
  const _Step(this.num, this.title, this.sub, this.color);
  @override Widget build(_) => Container(
    padding:const EdgeInsets.all(14),
    decoration:BoxDecoration(color:SS.raised, borderRadius:BorderRadius.circular(14), border:Border.all(color:SS.border)),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Container(width:24, height:24, decoration:BoxDecoration(color:color.withOpacity(.15), shape:BoxShape.circle),
        child:Center(child:Text(num, style:TextStyle(color:color, fontSize:12, fontWeight:FontWeight.w700)))),
      const SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        Text(title, style:const TextStyle(color:SS.t1, fontSize:13, fontWeight:FontWeight.w600)),
        if(sub.isNotEmpty)...[const SizedBox(height:3),
          Text(sub, style:const TextStyle(color:SS.t2, fontSize:11, height:1.5))],
      ])),
    ]));
}