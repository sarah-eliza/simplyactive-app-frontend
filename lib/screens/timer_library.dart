import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'workout_vid.dart'; // Video player screen

class TimerLibrary extends StatefulWidget {
  final String timerType; // "HIIT" or "Strength"

  const TimerLibrary({super.key, required this.timerType});

  @override
  State<TimerLibrary> createState() => _TimerLibraryState();
}

class _TimerLibraryState extends State<TimerLibrary> {
  late final Stream<List<Map<String, dynamic>>> _timerStream;

  // Get API base URL from environment
  static const String _apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  @override
  void initState() {
    super.initState();
    _timerStream = Supabase.instance.client
        .from('timer_video_metadata')
        .stream(primaryKey: ['id']);
  }

  Future<void> _playVideo(BuildContext context, String fileName) async {
    try {
      final uri = Uri.parse('$_apiBaseUrl/video-url?file_url=${Uri.encodeComponent(fileName)}');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final videoUrl = jsonDecode(response.body)['url'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutVideoPage(videoPath: videoUrl),
          ),
        );
      } else {
        throw Exception('Failed to load signed URL');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading video: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.timerType} Timers'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _timerStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final videos = snapshot.data;
          if (videos == null || videos.isEmpty) {
            return const Center(child: Text('No videos available'));
          }

          final filteredVideos = videos.where((video) {
            final fileName = (video['file_name'] as String?) ?? '';
            return fileName.toLowerCase().contains(widget.timerType.toLowerCase());
          }).toList();

          if (filteredVideos.isEmpty) {
            return const Center(child: Text('No videos available'));
          }

          return ListView.builder(
            itemCount: filteredVideos.length,
            itemBuilder: (context, index) {
              final video = filteredVideos[index];
              final fileName = video['file_name'] ?? '';

              return ListTile(
                title: Text(fileName),
                subtitle: Text('Length ${video['video_length'] ?? 'Unknown'} mins'),
                trailing: const Icon(Icons.play_circle_fill),
                onTap: () => _playVideo(context, fileName),
              );
            },
          );
        },
      ),
    );
  }
}
