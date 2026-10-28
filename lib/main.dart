import 'package:flutter/material.dart';

import 'ui/posture_demo_page.dart';

void main() => runApp(const MovaApp());

class MovaApp extends StatelessWidget {
  const MovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOVA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF3D5AFE),
        useMaterial3: true,
      ),
      home: const PostureDemoPage(),
    );
  }
}
