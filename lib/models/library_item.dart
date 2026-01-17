class LibraryItem {
  final int id;
  final String titre;
  final String description;
  final String type; // 'Livre' ou 'Fascicule'
  final String? auteur;
  final String? lien;
  final String? image;
  final String? categorie;
  final int? annee;
  final String slug;
  final String? langue;
  final String? niveau;
  final int? taille;
  final String? format;
  final String? motsCles;
  final bool? estPayant;
  final String? prix;
  final String? datePublication;
  final int? nbPages;
  final String? editeur;
  final String? isbn;
  final String? resume;
  final int? nbTelechargements;
  final int? nbVues;
  final bool? estDisponible;
  final String? dateCreation;
  final String? dateMiseAJour;

  LibraryItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.type,
    this.auteur,
    this.lien,
    this.image,
    this.categorie,
    this.annee,
    required this.slug,
    this.langue,
    this.niveau,
    this.taille,
    this.format,
    this.motsCles,
    this.estPayant,
    this.prix,
    this.datePublication,
    this.nbPages,
    this.editeur,
    this.isbn,
    this.resume,
    this.nbTelechargements,
    this.nbVues,
    this.estDisponible,
    this.dateCreation,
    this.dateMiseAJour,
  });

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? '',
      auteur: json['auteur'] as String?,
      lien: json['lien'] as String?,
      image: json['image'] as String?,
      categorie: json['categorie'] as String?,
      annee: json['annee'] as int?,
      slug: json['slug'] as String? ?? '',
      langue: json['langue'] as String?,
      niveau: json['niveau'] as String?,
      taille: json['taille'] as int?,
      format: json['format'] as String?,
      motsCles: json['motsCles'] as String?,
      estPayant: json['estPayant'] as bool?,
      prix: json['prix'] as String?,
      datePublication: json['datePublication'] as String?,
      nbPages: json['nbPages'] as int?,
      editeur: json['editeur'] as String?,
      isbn: json['isbn'] as String?,
      resume: json['resume'] as String?,
      nbTelechargements: json['nbTelechargements'] as int?,
      nbVues: json['nbVues'] as int?,
      estDisponible: json['estDisponible'] as bool?,
      dateCreation: json['dateCreation'] as String?,
      dateMiseAJour: json['dateMiseAJour'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titre': titre,
      'description': description,
      'type': type,
      'auteur': auteur,
      'lien': lien,
      'image': image,
      'categorie': categorie,
      'annee': annee,
      'slug': slug,
      'langue': langue,
      'niveau': niveau,
      'taille': taille,
      'format': format,
      'motsCles': motsCles,
      'estPayant': estPayant,
      'prix': prix,
      'datePublication': datePublication,
      'nbPages': nbPages,
      'editeur': editeur,
      'isbn': isbn,
      'resume': resume,
      'nbTelechargements': nbTelechargements,
      'nbVues': nbVues,
      'estDisponible': estDisponible,
      'dateCreation': dateCreation,
      'dateMiseAJour': dateMiseAJour,
    };
  }

  // Getters pour faciliter l'utilisation
  String get title => titre;
  String get author => auteur ?? 'Auteur inconnu';
  String get itemType => type;
  String? get link => lien;

  // Image URL with fallback - construct full URL from backend
  String? get imageUrl {
    if (image != null && image!.isNotEmpty) {
      // If the image path is already a full URL, return as is
      if (image!.startsWith('http://') || image!.startsWith('https://')) {
        return image!;
      }

      // Construct full URL for backend images
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

  String get category => categorie ?? 'Non catégorisé';
  int? get year => annee;
  String get itemDescription => description;
  String get itemSlug => slug;
  String? get language => langue;
  String? get level => niveau;
  int? get size => taille;
  String? get fileFormat => format;
  String? get keywords => motsCles;
  bool get isPaid => estPayant ?? false;
  String? get price => prix;
  String? get publicationDate => datePublication;
  int? get pageCount => nbPages;
  String? get publisher => editeur;
  String? get isbnNumber => isbn;
  String? get summary => resume;
  int get downloadCount => nbTelechargements ?? 0;
  int get viewCount => nbVues ?? 0;
  bool get isAvailable => estDisponible ?? true;
  String? get creationDate => dateCreation;
  String? get updateDate => dateMiseAJour;

  // Méthode pour déterminer l'icône appropriée
  String getIconData() {
    if (type.toLowerCase().contains('fascicule') || type.toLowerCase().contains('exercice')) {
      return 'article';
    } else {
      return 'book';
    }
  }

  // CopyWith method for updating specific fields
  LibraryItem copyWith({
    int? id,
    String? titre,
    String? description,
    String? type,
    String? auteur,
    String? lien,
    String? image,
    String? categorie,
    int? annee,
    String? slug,
    String? langue,
    String? niveau,
    int? taille,
    String? format,
    String? motsCles,
    bool? estPayant,
    String? prix,
    String? datePublication,
    int? nbPages,
    String? editeur,
    String? isbn,
    String? resume,
    int? nbTelechargements,
    int? nbVues,
    bool? estDisponible,
    String? dateCreation,
    String? dateMiseAJour,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      type: type ?? this.type,
      auteur: auteur ?? this.auteur,
      lien: lien ?? this.lien,
      image: image ?? this.image,
      categorie: categorie ?? this.categorie,
      annee: annee ?? this.annee,
      slug: slug ?? this.slug,
      langue: langue ?? this.langue,
      niveau: niveau ?? this.niveau,
      taille: taille ?? this.taille,
      format: format ?? this.format,
      motsCles: motsCles ?? this.motsCles,
      estPayant: estPayant ?? this.estPayant,
      prix: prix ?? this.prix,
      datePublication: datePublication ?? this.datePublication,
      nbPages: nbPages ?? this.nbPages,
      editeur: editeur ?? this.editeur,
      isbn: isbn ?? this.isbn,
      resume: resume ?? this.resume,
      nbTelechargements: nbTelechargements ?? this.nbTelechargements,
      nbVues: nbVues ?? this.nbVues,
      estDisponible: estDisponible ?? this.estDisponible,
      dateCreation: dateCreation ?? this.dateCreation,
      dateMiseAJour: dateMiseAJour ?? this.dateMiseAJour,
    );
  }
}