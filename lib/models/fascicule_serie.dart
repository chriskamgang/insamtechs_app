class FasciculeSerie {
  final int id;
  final int brancheId;
  final String intitule;
  final String slug;
  final bool isActive;

  FasciculeSerie({
    required this.id,
    required this.brancheId,
    required this.intitule,
    required this.slug,
    required this.isActive,
  });

  factory FasciculeSerie.fromJson(Map<String, dynamic> json) {
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

    return FasciculeSerie(
      id: json['id'] ?? 0,
      brancheId: json['branche_id'] ?? 0,
      intitule: extractString(json['intitule'] ?? json['nom'] ?? json['name']),
      slug: json['slug'] ?? '',
      isActive: json['is_active'] == 1 || json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branche_id': brancheId,
      'intitule': intitule,
      'slug': slug,
      'is_active': isActive,
    };
  }
}
