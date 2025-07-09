// lib/models/wallpaper.dart

class Wallpaper {
  final String id;
  final String url;
  final String photographer;

  Wallpaper({
    required this.id,
    required this.url,
    required this.photographer,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'].toString(), // int → String
      url: json['webformatURL'] as String, // correct Pixabay key
      photographer: json['user'] as String, // correct Pixabay key
    );
  }
}
