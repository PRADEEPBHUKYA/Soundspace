import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/audio_provider.dart';
import '../models/models.dart';
import '../theme/theme.dart';

class EQPanel extends StatefulWidget {
  const EQPanel({super.key});
  @override State<EQPanel> createState() => _EQPanelState();
}

class _EQPanelState extends State<EQPanel> {
  int? _dragging;
  static const _labels = ['Sub','Low','Mid','High','Air'];
  static const _freqs  = ['60Hz','250Hz','1kHz','4kHz','16kHz'];
  static const _colors = [SS.pink, SS.bassC, SS.amber, SS.green, SS.trebleC];

  @override Widget build(BuildContext context) {
    return Consumer<AudioProvider>(builder: (_, p, __) =>
      SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20,0,20,100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
            const Text('Master EQ',style:TextStyle(fontSize:22,fontWeight:FontWeight.w700,color:SS.t1)),
            TextButton(onPressed:(){ HapticFeedback.lightImpact(); p.resetEQ(); },
              child:const Text('Reset',style:TextStyle(color:SS.cyan,fontSize:14))),
          ]),
          const SizedBox(height:4),
          _Curve(bands: p.eqBands, colors: _colors),
          const SizedBox(height:18),
          SizedBox(height:220, child:Row(
            crossAxisAlignment:CrossAxisAlignment.stretch,
            children: List.generate(5,(i)=>Expanded(child:_Band(
              label:_labels[i], freq:_freqs[i],
              value:p.eqBands[i], color:_colors[i],
              dragging:_dragging==i,
              onStart:()=>setState(()=>_dragging=i),
              onEnd:()=>setState(()=>_dragging=null),
              onChange:(dB){ p.setEQBand(i,dB); HapticFeedback.selectionClick(); },
            ))),
          )),
          const SizedBox(height:22),
          const Text('PRESETS',style:TextStyle(color:SS.t3,fontSize:10,fontWeight:FontWeight.w700,letterSpacing:2)),
          const SizedBox(height:12),
          Wrap(spacing:8, runSpacing:8,
            children: EQPreset.all.map((pr){
              final on = p.activePreset == pr.name;
              return GestureDetector(
                onTap:(){ HapticFeedback.selectionClick(); p.applyPreset(pr); },
                child: AnimatedContainer(
                  duration:const Duration(milliseconds:200),
                  padding:const EdgeInsets.symmetric(horizontal:18,vertical:10),
                  decoration:BoxDecoration(
                    color:on?SS.cyan.withOpacity(.12):SS.raised,
                    borderRadius:BorderRadius.circular(22),
                    border:Border.all(color:on?SS.cyan.withOpacity(.5):SS.border)),
                  child:Text(pr.name,style:TextStyle(
                    color:on?SS.cyan:SS.t2,fontSize:13,
                    fontWeight:on?FontWeight.w700:FontWeight.w400)),
                ),
              );
            }).toList()),
        ]),
      ),
    );
  }
}

class _Curve extends StatelessWidget {
  final List<double> bands; final List<Color> colors;
  const _Curve({required this.bands, required this.colors});
  @override Widget build(BuildContext context) => Container(
    height:90, padding:const EdgeInsets.all(12),
    decoration:BoxDecoration(color:SS.raised,borderRadius:BorderRadius.circular(18),border:Border.all(color:SS.border)),
    child: LineChart(LineChartData(
      minY:-12, maxY:12,
      gridData:FlGridData(show:true, horizontalInterval:6, drawVerticalLine:false,
        getDrawingHorizontalLine:(_)=>FlLine(color:Colors.white.withOpacity(.05),strokeWidth:1)),
      titlesData:FlTitlesData(show:false),
      borderData:FlBorderData(show:false),
      lineBarsData:[LineChartBarData(
        spots:List.generate(5,(i)=>FlSpot(i.toDouble(),bands[i])),
        isCurved:true, curveSmoothness:.35,
        color:SS.cyan.withOpacity(.9), barWidth:2,
        isStrokeCapRound:true,
        belowBarData:BarAreaData(show:true,
          gradient:LinearGradient(colors:[SS.cyan.withOpacity(.18),Colors.transparent],
            begin:Alignment.topCenter,end:Alignment.bottomCenter)),
        dotData:FlDotData(show:true,
          getDotPainter:(s,_,__,i)=>FlDotCirclePainter(
            radius:3.5,color:colors[i],strokeWidth:0)),
      )],
    )),
  );
}

class _Band extends StatelessWidget {
  final String label, freq; final double value; final Color color;
  final bool dragging;
  final VoidCallback onStart, onEnd; final ValueChanged<double> onChange;
  const _Band({required this.label,required this.freq,required this.value,
    required this.color,required this.dragging,
    required this.onStart,required this.onEnd,required this.onChange});

  @override Widget build(BuildContext context) => LayoutBuilder(builder:(_, bc){
    final th = bc.maxHeight - 50;
    return Column(children:[
      Text(value>=0?'+${value.toStringAsFixed(1)}':value.toStringAsFixed(1),
        style:TextStyle(fontSize:9,color:dragging?color:SS.t3,fontWeight:FontWeight.w700)),
      const SizedBox(height:6),
      Expanded(child:Center(child:GestureDetector(
        onPanStart:(_)=>onStart(),
        onPanEnd:(_)=>onEnd(),
        onPanUpdate:(d){
          final cur = th*(1-(value+12)/24);
          final ny = (cur+d.delta.dy).clamp(0.0,th);
          onChange((1-ny/th)*24-12);
        },
        onTapUp:(d){ onChange((1-(d.localPosition.dy/th).clamp(0.0,1.0))*24-12); },
        child:SizedBox(width:26,height:th,
          child:CustomPaint(painter:_TrackP(value:value,color:color,drag:dragging))),
      ))),
      const SizedBox(height:4),
      Text(label,style:const TextStyle(fontSize:11,color:SS.t2,fontWeight:FontWeight.w500)),
      Text(freq,style:const TextStyle(fontSize:8,color:SS.t3)),
    ]);
  });
}

class _TrackP extends CustomPainter {
  final double value; final Color color; final bool drag;
  const _TrackP({required this.value,required this.color,required this.drag});
  @override void paint(Canvas c, Size s) {
    final cx = s.width/2;
    c.drawLine(Offset(cx,0),Offset(cx,s.height),Paint()
      ..color=SS.border..strokeWidth=4..strokeCap=StrokeCap.round..style=PaintingStyle.stroke);
    c.drawLine(Offset(0,s.height*.5),Offset(s.width,s.height*.5),
      Paint()..color=Colors.white.withOpacity(.08)..strokeWidth=1);
    final pct=(value+12)/24; final ty=s.height*(1-pct);
    final ap=Paint()..color=color.withOpacity(drag?1.0:0.75)
      ..strokeWidth=4..strokeCap=StrokeCap.round..style=PaintingStyle.stroke;
    if(pct>=.5){ c.drawLine(Offset(cx,s.height*.5),Offset(cx,ty),ap); }
    else { c.drawLine(Offset(cx,ty),Offset(cx,s.height*.5),ap); }
    final shadowOp = drag ? 0.5 : 0.25;
    c.drawCircle(Offset(cx,ty),drag?9:7,
      Paint()..color=color.withOpacity(shadowOp)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
    c.drawCircle(Offset(cx,ty),drag?9:7,
      Paint()..color=drag?color:Colors.white..style=PaintingStyle.fill);
  }
  @override bool shouldRepaint(_TrackP o) => o.value!=value||o.drag!=drag;
}