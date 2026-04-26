import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/audio_provider.dart';
import 'screens/home.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  setSystemUI();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AudioProvider(),
      child: const SoundSpaceApp(),
    ),
  );
}

class SoundSpaceApp extends StatelessWidget {
  const SoundSpaceApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SoundSpace',
    debugShowCheckedModeBanner: false,
    theme: SS.theme(),
    home: const HomeScreen(),
  );
}
