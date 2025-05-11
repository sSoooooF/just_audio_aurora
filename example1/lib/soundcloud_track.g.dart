// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soundcloud_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SoundCloudTrack _$SoundCloudTrackFromJson(Map<String, dynamic> json) =>
    SoundCloudTrack(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      artwork_url: json['artwork_url'] as String?,
      stream_url: json['stream_url'] as String,
      duration: (json['duration'] as num).toInt(),
      user: SoundCloudUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SoundCloudTrackToJson(SoundCloudTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artwork_url': instance.artwork_url,
      'stream_url': instance.stream_url,
      'duration': instance.duration,
      'user': instance.user,
    };

SoundCloudUser _$SoundCloudUserFromJson(Map<String, dynamic> json) =>
    SoundCloudUser(
      username: json['username'] as String,
    );

Map<String, dynamic> _$SoundCloudUserToJson(SoundCloudUser instance) =>
    <String, dynamic>{
      'username': instance.username,
    };
