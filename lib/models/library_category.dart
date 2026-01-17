class LibraryCategory {
  final int id;
  final String nom;
  final String? image;
  final String slug;
  final int itemCount;

  LibraryCategory({
    required this.id,
    required this.nom,
    this.image,
    required this.slug,
    required this.itemCount,
  });

  factory LibraryCategory.fromJson(Map<String, dynamic> json) {
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

    // Count formations
    int count = 0;
    if (json['formations'] != null && json['formations'] is List) {
      count = (json['formations'] as List).length;
    }

    return LibraryCategory(
      id: json['id'] ?? 0,
      nom: extractString(json['intitule'] ?? json['nom'] ?? json['name']),
      image: extractString(json['img'] ?? json['image']),
      slug: json['slug'] ?? '',
      itemCount: count,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'image': image,
      'slug': slug,
      'itemCount': itemCount,
    };
  }

  // Image URL with fallback - construct full URL from backend
  String? get imageUrl {
    if (image != null && image!.isNotEmpty) {
      // If the image path is already a full URL, return as is
      if (image!.startsWith('http://') || image!.startsWith('https://')) {
        return image!;
      }

      // Use production backend URL
      const baseUrl = 'https://admin.insamtechs.com';

      // Clean the path by removing any leading slash or 'storage/' prefix
      String cleanPath = image!;
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
