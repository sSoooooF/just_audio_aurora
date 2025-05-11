import 'dart:convert';
import 'package:dio/dio.dart';
import 'soundcloud_track.dart';

class SoundCloudApi {
  static const String _baseUrl = "https://api-v2.soundcloud.com";
  static const String clientId = "354f852cc7ba9c95b38ef4e21abd520b";

  final Dio _dio = Dio();

  Future<List<SoundCloudTrack>> searchTracks(String query) async {
    try {
      final response = await _dio.get(
        "$_baseUrl/search/tracks",
        queryParameters: {
          'q': query,
          'client_id': clientId,
          'limit': 20,
        },
      );

      return (response.data['collection'] as List)
          .map((json) => SoundCloudTrack.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception("Failed to search tracks: $e");
    }
  }

  Future<List<SoundCloudTrack>> getPopularTracks() async {
    try {
      final response = await _dio.get(
        "$_baseUrl/charts",
        queryParameters: {
          'kind': 'top',
          'genre': 'soundcloud:genres:all-music',
          'client_id': clientId,
          'limit': 20,
        },
      );

      return (response.data['collection'] as List)
          .map((item) => SoundCloudTrack.fromJson(item['track']))
          .toList();
    } catch (e) {
      throw Exception("Failed to load popular tracks: $e");
    }
  }
}
