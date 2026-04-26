import 'package:flutter/material.dart';
import '../widgets/pad.dart';
import '../widgets/sources.dart';
import '../widgets/controls.dart';
import '../widgets/play_btn.dart';
import '../widgets/banner.dart';

class RoomTab extends StatelessWidget {
  final VoidCallback onSetup;
  const RoomTab({super.key, required this.onSetup});

  @override Widget build(BuildContext context) => SingleChildScrollView(
    physics: const BouncingScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(18, 0, 18, 110),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CaptureBanner(onTap: onSetup),
      const SizedBox(height: 14),
      const XYPad(),
      const SizedBox(height: 10),
      const SourceRow(),
      const SizedBox(height: 18),
      const RoomControls(),
      const SizedBox(height: 24),
      const Center(child: PlayButton()),
    ]),
  );
}
