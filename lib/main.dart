import 'package:decidemate_pro/screens/add.dart';
import 'package:decidemate_pro/screens/dashboard.dart';
import 'package:decidemate_pro/screens/details.dart';
import 'package:decidemate_pro/screens/edit.dart';
import 'package:decidemate_pro/screens/history.dart';
import 'package:decidemate_pro/screens/home.dart';
import 'package:decidemate_pro/screens/insights.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        Provider<FirebaseService>(
          create: (_) => FirebaseService(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class Routes {
  static const String home = '/';
  static const String details = '/details';
  static const String edit = '/edit';
  static const String add = '/add';
  static const String dashboard = '/dashboard';
  static const String insights = '/insights';
  static const String history = '/history';
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError || _hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('An error occurred. Please try again.'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return _buildApp();
        }
      },
    );
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize Firebase or other services here
    } catch (e) {
      setState(() {
        _hasError = true;
      });
    }
  }

  Widget _buildApp() {
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
              initialRoute: Routes.dashboard,
              routes: {
                Routes.home: (context) => const HomeScreen(),
                Routes.details: (context) => const DetailsScreen(),
                Routes.edit: (context) => const EditScreen(),
                Routes.add: (context) => const AddScreen(),
                Routes.dashboard: (context) => const DashboardScreen(),
                Routes.insights: (context) => const InsightsScreen(),
                Routes.history: (context) => const HistoryScreen(),
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
              initialRoute: Routes.dashboard,
              routes: {
                Routes.home: (context) => const HomeScreen(),
                Routes.details: (context) => const DetailsScreen(),
                Routes.edit: (context) => const EditScreen(),
                Routes.add: (context) => const AddScreen(),
                Routes.dashboard: (context) => const DashboardScreen(),
                Routes.insights: (context) => const InsightsScreen(),
                Routes.history: (context) => const HistoryScreen(),
              },
            );
          }
        },
      ),
    );
  }
}


