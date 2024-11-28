import 'package:decidemate_pro/screens/add.dart';
import 'package:decidemate_pro/screens/details.dart';
import 'package:decidemate_pro/screens/edit.dart';
import 'package:decidemate_pro/screens/home.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class Routes {
  static const String home = '/';
  static const String details = '/details';
  static const String edit = '/edit';
  static const String add = '/add';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'DecideMate Pro',
      theme: CupertinoThemeData(
        brightness: WidgetsBinding.instance.window.platformBrightness,
        primaryColor: const Color(0xFF000000),
      ),
    
      initialRoute: Routes.home,
      routes: {
        Routes.home: (context) => const HomeScreen(),
        Routes.details: (context) => const DetailsScreen(),
        Routes.edit: (context) => const EditScreen(),
        Routes.add: (context) => const AddScreen(),
      },
    );
  }
}


