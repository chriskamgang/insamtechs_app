import 'package:json_annotation/json_annotation.dart';
import 'course.dart';

part 'search_response.g.dart';

@JsonSerializable()
class SearchResponse {
  final bool success;
  final String query;
  @JsonKey(name: 'total_results')
  final int totalResults;
  final SearchResults results;

  SearchResponse({
    required this.success,
    required this.query,
    required this.totalResults,
    required this.results,
  });

  factory SearchResponse.fromJson(Map<String, dynamic> json) => _$SearchResponseFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResponseToJson(this);
}

@JsonSerializable()
class SearchResults {
  final List<dynamic> videotheque;
  final List<Course> formations;
  final List<dynamic> bibliotheque;
  final List<dynamic> fascicules;
  final List<dynamic> videos;

  SearchResults({
    required this.videotheque,
    required this.formations,
    required this.bibliotheque,
    required this.fascicules,
    required this.videos,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) => _$SearchResultsFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResultsToJson(this);
}