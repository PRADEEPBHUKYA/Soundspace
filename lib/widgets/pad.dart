import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/audio_provider.dart';
import '../theme/theme.dart';

class XYPad extends StatefulWidget {
  const XYPad({super.key});
  @override State<XYPad> createState() => _XYPadState();
}

class _XYPadState extends State<XYPad> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.02,
      child: Container(
        decoration: BoxDecoration(
          color: SS.card,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: SS.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (ctx, bc) {
          return Consumer<AudioProvider>(builder: (_, p, __) {
            return GestureDetector(
              onPanStart: (d) => _drag(d.globalPosition, ctx, p, bc),
              onPanUpdate: (d) => _drag(d.globalPosition, ctx, p, bc),
              child: Stack(children: [
                // Grid
                CustomPaint(size: Size.infinite, painter: _GridPainter()),
                // Compass
                ..._compass(),
                // Center listener
                Positioned(
                  left: bc.maxWidth/2 - 13, top: bc.maxHeight/2 - 13,
                  child: Container(
                    width: 26, height: 26,
                    decoration: BoxDecoration(
                      color: SS.raised, shape: BoxShape.circle,
                      border: Border.all(color: SS.border)),
                    child: const Icon(Icons.hearing_rounded, size: 13, color: SS.t3),
                  ),
                ),
                // Connection lines
                ...List.generate(p.sources.length, (i) => Positioned.fill(
                  child: CustomPaint(painter: _LinePainter(
                    Offset(.5,.5), p.sources[i].pos,
                    p.sources[i].color.withOpacity(.1))),
                )),
                // Pucks
                ...List.generate(p.sources.length, (i) => _Puck(
                  source: p.sources[i],
                  selected: p.selectedIndex == i,
                  constraints: bc,
                  pulse: _pulse,
                  onTap: () { HapticFeedback.selectionClick(); p.selectSource(i); },
                )),
              ]),
            );
          });
        }),
      ),
    );
  }

  void _drag(Offset g, BuildContext ctx, AudioProvider p, BoxConstraints bc) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final l = box.globalToLocal(g);
    p.moveSource(Offset(l.dx / bc.maxWidth, l.dy / bc.maxHeight));
    HapticFeedback.selectionClick();
  }

  List<Widget> _compass() => [
    const Positioned(left:10, top:0, bottom:0, child: _CLabel('L')),
    const Positioned(right:10, top:0, bottom:0, child: _CLabel('R')),
    const Positioned(top:6, left:0, right:0, child: _CLabel('FAR')),
    const Positioned(bottom:6, left:0, right:0, child: _CLabel('NEAR')),
  ];
}

class _Puck extends StatelessWidget {
  final dynamic source;
  final bool selected;
  final BoxConstraints constraints;
  final Animation<double> pulse;
  final VoidCallback onTap;
  const _Puck({required this.source, required this.selected,
    required this.constraints, required this.pulse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = source.pos.dx * constraints.maxWidth;
    final t = source.pos.dy * constraints.maxHeight;
    return Positioned(left: l-28, top: t-28,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: pulse,
          builder: (_, child) => Stack(alignment: Alignment.center, children: [
            if (selected) Container(
              width: 56 + pulse.value * 12,
              height: 56 + pulse.value * 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: source.color.withOpacity(.07 - pulse.value*.04)),
            ),
            child!,
          ]),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: source.color.withOpacity(selected ? .18 : .07),
              border: Border.all(
                color: source.color.withOpacity(selected ? .9 : .35),
                width: selected ? 2.5 : 1.5),
              boxShadow: selected ? [BoxShadow(
                color: source.color.withOpacity(.4),
                blurRadius: 16, spreadRadius: 2)] : [],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(source.icon, size: 18,
                color: selected ? Colors.white : source.color.withOpacity(.7)),
              const SizedBox(height: 2),
              Text(source.name, style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w600,
                color: selected ? source.color : source.color.withOpacity(.6))),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override void paint(Canvas c, Size s) {
    final gp = Paint()..color = Colors.white.withOpacity(.03)..strokeWidth=1;
    for (int i=1;i<4;i++) {
      c.drawLine(Offset(s.width*i/4,0),Offset(s.width*i/4,s.height),gp);
      c.drawLine(Offset(0,s.height*i/4),Offset(s.width,s.height*i/4),gp);
    }
    final wp = Paint()..color=Colors.white.withOpacity(.06)..strokeWidth=1.2..style=PaintingStyle.stroke;
    const n=.1;
    final path = Path()
      ..moveTo(0,0)..lineTo(s.width*n,s.height*n)..lineTo(s.width*(1-n),s.height*n)..lineTo(s.width,0)
      ..moveTo(0,s.height)..lineTo(s.width*n,s.height*(1-n))..lineTo(s.width*(1-n),s.height*(1-n))..lineTo(s.width,s.height)
      ..moveTo(s.width*n,s.height*n)..lineTo(s.width*n,s.height*(1-n))
      ..moveTo(s.width*(1-n),s.height*n)..lineTo(s.width*(1-n),s.height*(1-n));
    c.drawPath(path,wp);
    final rp=Paint()..color=Colors.white.withOpacity(.04)..strokeWidth=1..style=PaintingStyle.stroke;
    final cx=s.width/2; final cy=s.height/2;
    for(final r in[.15,.3,.45]) c.drawCircle(Offset(cx,cy),s.width*r,rp);
  }
  @override bool shouldRepaint(_) => false;
}

class _LinePainter extends CustomPainter {
  final Offset a,b; final Color color;
  const _LinePainter(this.a,this.b,this.color);
  @override void paint(Canvas c,Size s) {
    c.drawLine(Offset(a.dx*s.width,a.dy*s.height),
               Offset(b.dx*s.width,b.dy*s.height),
               Paint()..color=color..strokeWidth=1.5);
  }
  @override bool shouldRepaint(_LinePainter o) => o.a!=a||o.b!=b;
}

class _CLabel extends StatelessWidget {
  final String t; const _CLabel(this.t);
  @override Widget build(BuildContext context) => Center(child: Text(t,style:const TextStyle(
    fontSize:9,color:Color(0x2EFFFFFF),letterSpacing:1.2,fontWeight:FontWeight.w700)));
}
