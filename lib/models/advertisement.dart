import 'dart:convert';

class Advertisement {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String appName;
  final String downloadUrl;
  final List<String> features;
  final int order;
  final bool isActive;

  Advertisement({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.appName,
    required this.downloadUrl,
    this.features = const [],
    this.order = 0,
    this.isActive = true,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    // Parse features - handle both JSON string and List
    List<String> parseFeatures(dynamic featuresData) {
      if (featuresData == null) return <String>[];

      // If it's already a List, convert it
      if (featuresData is List) {
        return featuresData.map((e) => e.toString()).toList();
      }

      // If it's a String, try to decode it as JSON
      if (featuresData is String) {
        try {
          final decoded = jsonDecode(featuresData);
          if (decoded is List) {
            return decoded.map((e) => e.toString()).toList();
          }
        } catch (e) {
          // If JSON decode fails, return empty list
          return <String>[];
        }
      }

      return <String>[];
    }

    return Advertisement(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      appName: json['app_name'] ?? '',
      downloadUrl: json['download_url'] ?? '',
      features: parseFeatures(json['features']),
      order: json['order'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'app_name': appName,
      'download_url': downloadUrl,
      'features': features,
      'order': order,
      'is_active': isActive,
    };
  }
}
