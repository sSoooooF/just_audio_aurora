import 'package:json_annotation/json_annotation.dart';

part 'soundcloud_track.g.dart';

@JsonSerializable()
class SoundCloudTrack {
  final int id;
  final String title;
  final String? artwork_url;
  final String stream_url;
  final int duration;
  final SoundCloudUser user;

  SoundCloudTrack({
    required this.id,
    required this.title,
    this.artwork_url,
    required this.stream_url,
    required this.duration,
    required this.user,
  });

  factory SoundCloudTrack.fromJson(Map<String, dynamic> json) =>
      _$SoundCloudTrackFromJson(json);
  Map<String, dynamic> toJson() => _$SoundCloudTrackToJson(this);

  String get fullStreamUrl => "$stream_url?client_id=YOUR_SOUNDCLOUD_CLIENT_ID";
}

@JsonSerializable()
class SoundCloudUser {
  final String username;

  SoundCloudUser({required this.username});

  factory SoundCloudUser.fromJson(Map<String, dynamic> json) =>
      _$SoundCloudUserFromJson(json);
  Map<String, dynamic> toJson() => _$SoundCloudUserToJson(this);
}
