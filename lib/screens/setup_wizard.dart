import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class SetupWizard extends StatefulWidget {
  const SetupWizard({super.key});
  @override State<SetupWizard> createState() => _SetupWizardState();
}

class _SetupWizardState extends State<SetupWizard> {
  final _pc = PageController();
  int _step = 0;
  bool _loading = false;

  static const _adb = 'adb shell pm grant com.example.soundspace android.permission.CAPTURE_AUDIO_OUTPUT';

  @override void dispose() { _pc.dispose(); super.dispose(); }

  void _next() => _pc.nextPage(duration:const Duration(milliseconds:350),curve:Curves.easeOutCubic);

  Future<void> _authorize() async {
    setState(()=>_loading=true);
    final p = context.read<AudioProvider>();
    await p.checkShizuku();
    await Future.delayed(const Duration(milliseconds:500));
    if ((p.shizuku['authorized']??false) && mounted) {
      final ok = await p.startCapture(privileged:true);
      if (ok && mounted) {
        _showSuccess();
      } else {
        setState(()=>_loading=false);
        _showError();
      }
    } else {
      setState(()=>_loading=false);
      _showError();
    }
  }

  void _showSuccess() => showDialog(context:context,builder:(_)=>AlertDialog(
    backgroundColor:SS.raised,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22)),
    title:const Text('Unlocked!',style:TextStyle(color:SS.green,fontWeight:FontWeight.w700,fontSize:20)),
    content:const Text('SoundSpace now spatializes audio from ALL apps.',
      style:TextStyle(color:SS.t2)),
    actions:[TextButton(onPressed:(){ Navigator.pop(context); Navigator.pop(context); },
      child:const Text('Done',style:TextStyle(color:SS.cyan,fontWeight:FontWeight.w700)))],
  ));

  void _showError() => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    backgroundColor:SS.pink.withOpacity(.9),
    shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
    margin:const EdgeInsets.all(16), behavior:SnackBarBehavior.floating,
    content:const Text('Shizuku not authorized. Make sure it's running.',
      style:TextStyle(color:Colors.white)),
  ));

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: SS.bg,
    appBar: AppBar(backgroundColor:Colors.transparent,
      title:const Text('Unlock Full Power',style:TextStyle(fontSize:17,fontWeight:FontWeight.w600)),
      leading:IconButton(icon:const Icon(Icons.close_rounded,color:SS.t2),
        onPressed:()=>Navigator.pop(context))),
    body: SafeArea(child: Column(children:[
      // Progress dots
      Padding(padding:const EdgeInsets.symmetric(vertical:12),
        child:Row(mainAxisAlignment:MainAxisAlignment.center,children:List.generate(3,(i){
          final done=i<_step; final active=i==_step;
          return AnimatedContainer(
            duration:const Duration(milliseconds:280),curve:Curves.easeOutCubic,
            width:active?40:done?22:10, height:6,
            margin:const EdgeInsets.symmetric(horizontal:3),
            decoration:BoxDecoration(
              color:done?SS.green:active?SS.cyan:SS.border,
              borderRadius:BorderRadius.circular(3)));
        }))),
      Expanded(child:PageView(
        controller:_pc,physics:const NeverScrollableScrollPhysics(),
        onPageChanged:(i)=>setState(()=>_step=i),
        children:[
          _Page(step:1,icon:Icons.download_rounded,color:SS.cyan,
            title:'Install Shizuku',
            desc:'Download the free Shizuku app from Google Play. It enables rootless system-level permissions.',
            steps:['Search "Shizuku" on Google Play','Install — it\'s free & open-source','No root required'],
            btn:'Open Play Store', onBtn:_next),
          _Page(step:2,icon:Icons.settings_input_antenna_rounded,color:SS.amber,
            title:'Activate Shizuku',
            desc:'Enable Wireless Debugging in Developer Options, then start Shizuku from inside the app.',
            steps:['Settings → About Phone → tap Build Number 7×',
              'Developer Options → Wireless Debugging → On',
              'Open Shizuku → Start via Wireless Debugging'],
            btn:'Next', onBtn:_next),
          _Page(step:3,icon:Icons.verified_user_rounded,color:SS.green,
            title:'Authorize',
            desc:'Grant SoundSpace permission to capture system audio from all apps.',
            steps:['Tap Authorize below (requires Shizuku running)',
              'Or run the ADB command from your computer'],
            adb:_adb,
            btn:_loading?'Checking…':'Authorize Now',
            onBtn:_loading?null:_authorize, loading:_loading),
        ],
      )),
    ])),
  );
}

class _Page extends StatelessWidget {
  final int step; final IconData icon; final Color color;
  final String title, desc, btn; final List<String> steps;
  final String? adb; final VoidCallback? onBtn; final bool loading;
  const _Page({required this.step,required this.icon,required this.color,
    required this.title,required this.desc,required this.btn,
    required this.steps,this.adb,this.onBtn,this.loading=false});

  @override Widget build(BuildContext context) => SingleChildScrollView(
    padding:const EdgeInsets.symmetric(horizontal:28),
    child:Column(children:[
      const SizedBox(height:28),
      Container(width:96,height:96,
        decoration:BoxDecoration(color:color.withOpacity(.1),shape:BoxShape.circle,
          border:Border.all(color:color.withOpacity(.25),width:2)),
        child:Icon(icon,size:48,color:color)),
      const SizedBox(height:26),
      Text('Step $step: $title',textAlign:TextAlign.center,
        style:const TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:SS.t1)),
      const SizedBox(height:12),
      Text(desc,textAlign:TextAlign.center,
        style:const TextStyle(color:SS.t2,fontSize:15,height:1.55)),
      const SizedBox(height:22),
      Container(padding:const EdgeInsets.all(16),
        decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(16),
          border:Border.all(color:SS.border)),
        child:Column(children:steps.asMap().entries.map((e)=>Padding(
          padding:const EdgeInsets.symmetric(vertical:5),
          child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Container(width:20,height:20,decoration:BoxDecoration(color:color.withOpacity(.15),shape:BoxShape.circle),
              child:Center(child:Text('${e.key+1}',style:TextStyle(fontSize:10,color:color,fontWeight:FontWeight.w700)))),
            const SizedBox(width:10),
            Expanded(child:Text(e.value,style:const TextStyle(color:SS.t2,fontSize:13))),
          ]))).toList())),
      if(adb!=null)...[
        const SizedBox(height:14),
        Container(width:double.infinity,padding:const EdgeInsets.all(14),
          decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(14),
            border:Border.all(color:SS.cyan.withOpacity(.2))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('ADB COMMAND',style:TextStyle(color:SS.cyan,fontSize:9,fontWeight:FontWeight.w700,letterSpacing:1.5)),
            const SizedBox(height:6),
            SelectableText(adb!,style:const TextStyle(color:SS.t2,fontSize:10,fontFamily:'monospace',height:1.5)),
            const SizedBox(height:8),
            GestureDetector(
              onTap:(){ Clipboard.setData(ClipboardData(text:adb!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content:Text('Copied'),duration:Duration(seconds:1))); },
              child:const Row(children:[Icon(Icons.copy_rounded,size:12,color:SS.cyan),
                SizedBox(width:4),Text('Copy',style:TextStyle(color:SS.cyan,fontSize:11))])),
          ])),
      ],
      const SizedBox(height:28),
      SizedBox(width:double.infinity,height:54,child:ElevatedButton(
        onPressed:onBtn,
        style:ElevatedButton.styleFrom(backgroundColor:color,foregroundColor:Colors.black,
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),elevation:0),
        child:loading
          ?const SizedBox(width:20,height:20,child:CircularProgressIndicator(color:Colors.black,strokeWidth:2.5))
          :Text(btn,style:const TextStyle(fontWeight:FontWeight.w700,fontSize:16)))),
      const SizedBox(height:32),
    ]),
  );
}
