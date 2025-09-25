// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResponse _$SearchResponseFromJson(Map<String, dynamic> json) =>
    SearchResponse(
      success: json['success'] as bool,
      query: json['query'] as String,
      totalResults: (json['total_results'] as num).toInt(),
      results: SearchResults.fromJson(json['results'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SearchResponseToJson(SearchResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'query': instance.query,
      'total_results': instance.totalResults,
      'results': instance.results,
    };

SearchResults _$SearchResultsFromJson(Map<String, dynamic> json) =>
    SearchResults(
      videotheque: json['videotheque'] as List<dynamic>,
      formations: (json['formations'] as List<dynamic>)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
      bibliotheque: json['bibliotheque'] as List<dynamic>,
      fascicules: json['fascicules'] as List<dynamic>,
      videos: json['videos'] as List<dynamic>,
    );

Map<String, dynamic> _$SearchResultsToJson(SearchResults instance) =>
    <String, dynamic>{
      'videotheque': instance.videotheque,
      'formations': instance.formations,
      'bibliotheque': instance.bibliotheque,
      'fascicules': instance.fascicules,
      'videos': instance.videos,
    };
