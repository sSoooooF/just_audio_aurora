import 'package:flutter/material.dart';
import 'package:just_audio_aurora/just_audio_aurora.dart';
import 'package:just_audio_aurora/just_audio_aurora_platform.dart';

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
  final _audioPlayer = AuroraAudioPlayer("example_player");
  bool _isPlaying = false;
  double _volume = 1.0;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadAndPlay() async {
    await _audioPlayer.load(
      LoadRequest(
        audioSource: ProgressiveAudioSourceMessage(
          id: "test_audio",
          uri: "assets/Bones.mp3",  // Путь к аудиофайлу
        ),
      ),
    );
    await _audioPlayer.play(PlayRequest());
    setState(() => _isPlaying = true);
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
      appBar: AppBar(title: const Text('Just Audio Aurora')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              iconSize: 48,
              onPressed: _isPlaying ? _pause : _loadAndPlay,
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
