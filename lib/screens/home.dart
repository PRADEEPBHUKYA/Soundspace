import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'room_tab.dart';
import '../widgets/eq.dart';
import 'settings_tab.dart';
import 'setup_wizard.dart';
import '../theme/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _idx = 0;
  late final _pc = PageController();
  late final _hdrAnim = AnimationController(vsync:this, duration:const Duration(milliseconds:220));

  static const _nav = [
    (icon: Icons.spatial_audio_rounded,   label: 'Room'),
    (icon: Icons.tune_rounded,            label: 'EQ'),
    (icon: Icons.settings_rounded,        label: 'Settings'),
  ];
  static const _titles = ['SoundSpace','Master EQ','Settings'];
  static const _subs   = ['Spatial Audio Engine','Frequency Shaper','Configuration'];

  void _go(int i) {
    if (i == _idx) return;
    HapticFeedback.selectionClick();
    setState(() => _idx = i);
    _pc.animateToPage(i, duration:const Duration(milliseconds:320), curve:Curves.easeOutCubic);
  }

  void _openSetup() => Navigator.push(context, MaterialPageRoute(builder:(_)=>const SetupWizard()));

  @override void dispose() { _pc.dispose(); _hdrAnim.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Stack(children: [
        // Radial accent glow per tab
        AnimatedContainer(
          duration:const Duration(milliseconds:500), curve:Curves.easeInOut,
          decoration:BoxDecoration(gradient:RadialGradient(
            center:const Alignment(-.7,-.9), radius:1.1,
            colors:[[SS.cyan,SS.amber,SS.pink][_idx].withOpacity(.05), SS.bg])),
        ),
        SafeArea(bottom:false, child:Column(children:[
          _Header(idx:_idx, title:_titles[_idx], sub:_subs[_idx]),
          Expanded(child:PageView(
            controller:_pc,
            physics:const NeverScrollableScrollPhysics(),
            children:[
              RoomTab(onSetup:_openSetup),
              const EQPanel(),
              SettingsTab(onSetup:_openSetup),
            ],
          )),
        ])),
      ]),
      bottomNavigationBar: _BottomNav(idx:_idx, onTap:_go),
    );
  }
}

class _Header extends StatelessWidget {
  final int idx; final String title, sub;
  const _Header({required this.idx,required this.title,required this.sub});
  @override Widget build(BuildContext context) => Padding(
    padding:const EdgeInsets.fromLTRB(22,16,16,10),
    child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
      AnimatedSwitcher(
        duration:const Duration(milliseconds:220),
        child:Column(key:ValueKey(idx),crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(title,style:const TextStyle(fontSize:24,fontWeight:FontWeight.w700,color:SS.t1,letterSpacing:.2)),
          Text(sub,style:const TextStyle(fontSize:11,color:SS.t3)),
        ])),
      const Spacer(),
      Container(width:40,height:40,
        decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(12),
          border:Border.all(color:SS.border)),
        child:const Icon(Icons.spatial_audio_off_rounded,color:SS.cyan,size:21)),
    ]),
  );
}

class _BottomNav extends StatelessWidget {
  final int idx; final ValueChanged<int> onTap;
  const _BottomNav({required this.idx,required this.onTap});

  static const _items = [
    (icon:Icons.spatial_audio_rounded,   label:'Room'),
    (icon:Icons.tune_rounded,            label:'EQ'),
    (icon:Icons.settings_rounded,        label:'Settings'),
  ];

  @override Widget build(BuildContext context) => SafeArea(
    child:Container(
      margin:const EdgeInsets.fromLTRB(18,0,18,10),
      padding:const EdgeInsets.symmetric(vertical:6,horizontal:6),
      decoration:BoxDecoration(
        color:SS.raised.withOpacity(.95),
        borderRadius:BorderRadius.circular(30),
        border:Border.all(color:SS.border),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(.45),blurRadius:22,offset:const Offset(0,6))]),
      child:Row(mainAxisAlignment:MainAxisAlignment.spaceEvenly,
        children:List.generate(_items.length,(i){
          final it=_items[i]; final sel=idx==i;
          return GestureDetector(onTap:()=>onTap(i),
            child:AnimatedContainer(
              duration:const Duration(milliseconds:260),curve:Curves.easeOutCubic,
              padding:const EdgeInsets.symmetric(horizontal:22,vertical:10),
              decoration:BoxDecoration(
                color:sel?SS.cyan.withOpacity(.13):Colors.transparent,
                borderRadius:BorderRadius.circular(22)),
              child:Column(mainAxisSize:MainAxisSize.min,children:[
                Icon(it.icon,size:24,color:sel?SS.cyan:SS.t3),
                if(sel)...[const SizedBox(height:4),
                  Container(width:4,height:4,decoration:const BoxDecoration(color:SS.cyan,shape:BoxShape.circle))],
              ]),
            ));
        })),
    ));
}
