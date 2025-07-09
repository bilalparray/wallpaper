// lib/api/apiservice.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wallpaper/models/wallpaper.dart';

class ApiService {
  static const String baseURL = 'https://pixabay.com';
  static const String apiKey = '51240446-437eb9a613ac4638916437497';

  Future<List<Wallpaper>> getImages({String query = 'yellow+flowers'}) async {
    final uri = Uri.parse('$baseURL/api/?key=$apiKey&q=$query');
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load images (status ${response.statusCode})');
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final List<dynamic> hits = data['hits'];

    return hits
        .map<Wallpaper>(
            (item) => Wallpaper.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
