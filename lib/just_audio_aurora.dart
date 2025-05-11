import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class AudioPlayerAurora extends AudioPlayerPlatform{
  @override
  final String id;
  final MethodChannel _channel;

  AudioPlayerAurora(this.id)
  : _channel = MethodChannel("just_audio_aurora"), super('');

  Future<String> _getAssetFilePath(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final buffer = data.buffer.asUint8List();

    final tempDir = await Directory.systemTemp.createTemp();
    final tempFile = File('${tempDir.path}/${assetPath.split('/').last}');

    await tempFile.writeAsBytes(buffer);

    return tempFile.path;
  }

  Future<void> setUrl(String url) async {
    try {
      if (url.startsWith('assets:///')) {
          url = await _getAssetFilePath(url.replaceFirst('assets:///', 'assets/'));
      }
      await _channel.invokeMethod('setUrl', {
        'url':url
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> notifyTrackEnded() async {
    await _channel.invokeMethod('onTrackEnded');
  }

  Future<void> loadFromUrl(String url) async {
    await _channel.invokeMethod('setUrl', {'url': url});
  }

  Future<void> loadFromUri(String uri) async {
    await _channel.invokeMethod('setUrl', {'url': uri});
  }

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    final audioSourceMessage = request.audioSourceMessage;
    final sourceMap = audioSourceMessage.toMap();
    final uri = sourceMap['uri'];

    if (uri.startsWith('file://')) {
      await loadFromUri(uri);
    } 
    else {
      await loadFromUrl(uri);
    }
    return LoadResponse(duration: Duration.zero);
  }

  @override
  Future<PlayResponse> play(PlayRequest request) async {
    await _channel.invokeMethod('play');
    return PlayResponse();
  }

  @override
  Future<PauseResponse> pause(PauseRequest request) async {
    await _channel.invokeMethod('pause');
    return PauseResponse();
  }


  @override
  Future<SeekResponse> seek(SeekRequest request) async {
    await _channel.invokeMethod('seek', {
      'position': request.position?.inMilliseconds,
      if (request.index != null)'index' : request.index,
    });
    return SeekResponse();
  }

  @override
  Future<SetVolumeResponse> setVolume(SetVolumeRequest request) async {
    await _channel.invokeMethod('setVolume', {
      'volume': request.volume,
    });
    return SetVolumeResponse();
  }

  Future<double> getVolume() async {
    final double volume = await _channel.invokeMethod('getVolume');
    return volume;
  }

  Future<int> getPosition() async {
    final int position = await _channel.invokeMethod('getPosition');
    return position;
  }


  @override
  Future<SetSpeedResponse> setSpeed(SetSpeedRequest request) async {
    await _channel.invokeMethod('setPlaybackRate', {
      'speed': request.speed,
    });
    return SetSpeedResponse();
  }

  Future<double> getSpeed() async {
    final double speed = await _channel.invokeMethod('getPlaybackRate');
    return speed;
  }

  @override
  Future<SetLoopModeResponse> setLoopMode(SetLoopModeRequest request) async {
    await _channel.invokeMethod('setLooping', {'looping': request.loopMode == LoopModeMessage.one});
    return SetLoopModeResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _channel.invokeMethod('dispose');
    return DisposeResponse();
  }

  void nextTrack() {
    _channel.invokeMethod('nextTrack');
  }
}
