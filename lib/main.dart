import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/timer_library.dart';
import 'screens/workout_vid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use dart-define to pass Supabase config in builds
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simply Active Fitness',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        '/hiit_timers': (context) => const TimerLibrary(timerType: 'HIIT'),
        '/strength_timers': (context) => const TimerLibrary(timerType: 'Strength'),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/workout_video') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => WorkoutVideoPage(videoPath: args['videoPath']!),
          );
        }
        return null;
      },
    );
  }
}
