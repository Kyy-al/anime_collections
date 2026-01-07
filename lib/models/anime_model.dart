// models/anime_model.dart
class AnimeModel {
  final int id;
  final String title;
  final String description;
  final String genre;
  final double rating;
  final String imageUrl;
  final String trailerUrl;
  final String releaseDate;
  final String? createdAt;
  bool isFavorite;

  AnimeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.rating,
    required this.imageUrl,
    required this.trailerUrl,
    required this.releaseDate,
    this.createdAt,
    this.isFavorite = false,
  });

  // From JSON
  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      genre: json['genre'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'] ?? '',
      trailerUrl: json['trailer_url'] ?? '',
      releaseDate: json['release_date'] ?? '',
      createdAt: json['created_at'],
      isFavorite: json['is_favorite'] == 1,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'rating': rating,
      'image_url': imageUrl,
      'trailer_url': trailerUrl,
      'release_date': releaseDate,
      'created_at': createdAt,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // To Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'genre': genre,
      'rating': rating,
      'image_url': imageUrl,
      'trailer_url': trailerUrl,
      'release_date': releaseDate,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'is_favorite': isFavorite ? 1 : 0,
    };
  }

  // Copy with
  AnimeModel copyWith({
    int? id,
    String? title,
    String? description,
    String? genre,
    double? rating,
    String? imageUrl,
    String? trailerUrl,
    String? releaseDate,
    String? createdAt,
    bool? isFavorite,
  }) {
    return AnimeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      genre: genre ?? this.genre,
      rating: rating ?? this.rating,
      imageUrl: imageUrl ?? this.imageUrl,
      trailerUrl: trailerUrl ?? this.trailerUrl,
      releaseDate: releaseDate ?? this.releaseDate,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

