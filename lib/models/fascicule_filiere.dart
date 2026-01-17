class FasciculeFiliere {
  final int id;
  final String intitule;
  final String? img;
  final String slug;
  final int fasciculesCount;

  FasciculeFiliere({
    required this.id,
    required this.intitule,
    this.img,
    required this.slug,
    required this.fasciculesCount,
  });

  factory FasciculeFiliere.fromJson(Map<String, dynamic> json) {
    // Extract title from multilingual field
    String extractString(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map) {
        return value['fr']?.toString() ??
               value['en']?.toString() ??
               value.values.first?.toString() ?? '';
      }
      return value.toString();
    }

    return FasciculeFiliere(
      id: json['id'] ?? 0,
      intitule: extractString(json['intitule'] ?? json['nom'] ?? json['name']),
      img: extractString(json['img'] ?? json['image']),
      slug: json['slug'] ?? '',
      fasciculesCount: json['fascicules_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'intitule': intitule,
      'img': img,
      'slug': slug,
      'fasciculesCount': fasciculesCount,
    };
  }

  // Image URL with fallback - construct full URL from backend
  String? get imageUrl {
    if (img != null && img!.isNotEmpty) {
      // If the image path is already a full URL, return as is
      if (img!.startsWith('http://') || img!.startsWith('https://')) {
        return img!;
      }

      // Use production backend URL
      const baseUrl = 'https://admin.insamtechs.com';

      // Clean the path by removing any leading slash or 'storage/' prefix
      String cleanPath = img!;
      if (cleanPath.startsWith('/')) {
        cleanPath = cleanPath.substring(1);
      }
      if (!cleanPath.startsWith('storage/')) {
        cleanPath = 'storage/$cleanPath';
      }

      return '$baseUrl/$cleanPath';
    }
    return null;
  }
}
