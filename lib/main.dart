import 'package:flutter/cupertino.dart';
import 'package:wallpaper/screens/homepage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Wallpaper App',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
      ),
      home: const HomePage(),
    );
  }
}
