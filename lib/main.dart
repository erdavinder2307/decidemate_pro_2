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
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    final isDarkMode = brightness == Brightness.dark;

    return Theme(
      data: ThemeData(
        brightness: brightness,
        primaryColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
        colorScheme: ColorScheme.fromSwatch(
          brightness: brightness,
          primarySwatch: isDarkMode ? Colors.grey : Colors.blue,
        ).copyWith(
          secondary: isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF6200EE),
        ),
        scaffoldBackgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        textTheme: isDarkMode ? Typography.whiteCupertino : Typography.blackCupertino,
      ),
      child: Builder(
        builder: (context) {
          if (Theme.of(context).platform == TargetPlatform.iOS) {
            return CupertinoApp(
              debugShowCheckedModeBanner: false,
              title: 'DecideMate Pro',
              theme: CupertinoThemeData(
                brightness: brightness,
                primaryColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
                primaryContrastingColor: isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF6200EE),
                barBackgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
                scaffoldBackgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
              ),
              initialRoute: Routes.home,
              routes: {
                Routes.home: (context) => const HomeScreen(),
                Routes.details: (context) => const DetailsScreen(),
                Routes.edit: (context) => const EditScreen(),
                Routes.add: (context) => const AddScreen(),
              },
            );
          } else {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'DecideMate Pro',
              theme: ThemeData(
                brightness: brightness,
                primaryColor: isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFFFFFFF),
                colorScheme: ColorScheme.fromSwatch(
                  brightness: brightness,
                  primarySwatch: isDarkMode ? Colors.grey : Colors.blue,
                ).copyWith(
                  secondary: isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF6200EE),
                ),
                scaffoldBackgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
                textTheme: isDarkMode ? Typography.whiteMountainView : Typography.blackMountainView,
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
        },
      ),
    );
  }
}


