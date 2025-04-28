import 'package:flutter/services.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class AuroraAudioPlayer extends AudioPlayerPlatform {
  @override
  final String id;
  final MethodChannel _channel;

  AuroraAudioPlayer(this.id)
  : _channel = MethodChannel("just_audio_aurora"), super('');

  Future<void> setUrl(String url) async {
    try {
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

  @override
  Future<LoadResponse> load(LoadRequest request) async {
    await _channel.invokeMethod('setUrl');
    return LoadResponse(duration: Duration(seconds: 0));
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

  Future<double> getPosition() async {
    final double position = await _channel.invokeMethod('getPosition');
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
    await _channel.invokeMethod('setLooping', {'looping': request.loopMode});
    return SetLoopModeResponse();
  }

  @override
  Future<DisposeResponse> dispose(DisposeRequest request) async {
    await _channel.invokeMethod('dispose');
    return DisposeResponse();
  }

  // Stream<PlaybackEventMessage> get playbackEventMessageStream {
    // return _eventChannel.receiveBroadcastStream().map((event) {
      // return PlaybackEventMessage.fromMap(event);
    // });
  // }

  // static const EventChannel _eventChannel =
      // EventChannel('just_audio_aurora_events');
}
