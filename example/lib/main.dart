import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio_aurora/just_audio_aurora.dart';
import 'package:just_audio_aurora/just_audio_aurora_platform.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

void main() {
  registerJustAudioAurora();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Just Audio Aurora Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AudioPlayerScreen(),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  const AudioPlayerScreen({super.key});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  late final AuroraAudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 1.0;
  // late final StreamSubscription<PlaybackEventMessage> _playbackEventSub;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AuroraAudioPlayer("just_audio_aurora");
    setSource();

    // _playbackEventSub = _audioPlayer.playbackEventMessageStream.listen(
    //   (event) {
    //     print(event);
    //   }
    // );
  }

  @override
  void dispose() {
    // _playbackEventSub.cancel();
    _audioPlayer.dispose(DisposeRequest());
    super.dispose();
  }

  Future<void> setSource() async {
    _audioPlayer.setUrl("https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3");
  }
  // https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3
  Future<void> _play() async {
    _audioPlayer.setVolume(SetVolumeRequest(volume: 1.0));
    try {
      await _audioPlayer.play(PlayRequest());
      setState(() => _isPlaying = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause(PauseRequest());
    setState(() => _isPlaying = false);
  }

  Future<void> _setVolume(double value) async {
    await _audioPlayer.setVolume(SetVolumeRequest(volume: value));
    setState(() => _volume = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Just Audio Aurora Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 48,
              onPressed: _isPlaying ? _pause : _play,
            ),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              onChanged: _setVolume,
            ),
            Text("Громкость: ${(_volume * 100).round()}%"),
          ],
        ),
      ),
    );
  }
}
