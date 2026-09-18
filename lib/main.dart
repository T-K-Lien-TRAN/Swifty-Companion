import 'package:flutter/material.dart';
import 'screens/search_screen.dart';

void main() => runApp(const MainApp());

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SwiftyCompanion',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF191B1B),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF16E883),
            brightness: Brightness.dark,
          ),
        ),
        home: const StudentSearchPage(),
      );
}
