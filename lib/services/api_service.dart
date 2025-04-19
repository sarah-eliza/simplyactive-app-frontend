// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // backend URL (for local testing, you might use localhost or 127.0.0.1).
  // In production, use the deployed FastAPI app's URL.
  static const String baseUrl = 'https://simplyactive-app-backend.onrender.com';  

  /// Sends a POST request to the FastAPI generate-video endpoint.
  /// 
  /// [workout] should be a list of lists (or arrays) where each inner list
  /// represents an exercise tuple: [Section, Exercise Name, Modification, [R,G,B], Duration].
  /// [videoName] is optional.
  /// 
  /// Returns a Map containing the response data.
  Future<Map<String, dynamic>> generateVideo({
    required List<dynamic> workout,
    String? videoName,
  }) async {
    final Uri url = Uri.parse('$baseUrl/generate-video');

    // Construct the JSON body.
    final Map<String, dynamic> data = {
      'workout': workout,
      'video_name': videoName,
    };

    // Make the POST request.
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      // Return the parsed JSON response.
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate video: ${response.body}');
    }
  }
}
