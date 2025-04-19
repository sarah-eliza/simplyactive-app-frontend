import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/timer_library.dart'; // Make sure this path is correct
import 'screens/workout_vid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from the .env file.
  await dotenv.load(fileName: ".env");
    
  // Initialize Supabase using values from the .env file.
  // This call ensures that Supabase.instance is ready for use in the app.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
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
      // Set the initial route to HomeScreen
      initialRoute: '/home',
      routes: {
        '/home': (context) => const HomeScreen(),
        // Named routes for TimerLibrary screens with fixed parameters
        '/hiit_timers': (context) => const TimerLibrary(timerType: 'HIIT'),
        '/strength_timers': (context) => const TimerLibrary(timerType: 'Strength')
      },
      onGenerateRoute: (settings) {
        // Handle dynamic route to WorkoutVideoPage
        if (settings.name == '/workout_video') {
          final args = settings.arguments as Map<String, String>;
          return MaterialPageRoute(
            builder: (context) => WorkoutVideoPage(videoPath: args['videoPath']!),
          );
        }
        return null; // Default behavior for unknown routes
      },
    );
  }
}
