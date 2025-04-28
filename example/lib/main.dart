import 'dart:async';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_aurora/just_audio_aurora.dart';
import 'package:just_audio_aurora/just_audio_aurora_platform.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:file_selector_aurora/file_selector_aurora.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  // Set FileSelectorAuroraKeyContainer.navigatorKey
  FileSelectorAuroraKeyContainer.navigatorKey = navigatorKey;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
  double _playbackRate = 1.0;
  String _audioUrl = "";
  TextEditingController _urlController = TextEditingController();
  List<String> _playlist = [];
  int _currentTrackIndex = -1;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AuroraAudioPlayer("just_audio_aurora");
    setSource();
  }

  @override
  void dispose() {
    _audioPlayer.dispose(DisposeRequest());
    super.dispose();
  }

  Future<void> setSource() async {
    if (_audioUrl.isNotEmpty) {
      try {
        await _audioPlayer.setUrl(_audioUrl);
        setState(() {});
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: $e")),
        );
      }
    }
  }

  Future<void> _play() async {
    await _audioPlayer.setVolume(SetVolumeRequest(volume: _volume));
    await _audioPlayer.setSpeed(SetSpeedRequest(speed: _playbackRate));
    try {
      await _audioPlayer.play(PlayRequest());
      setState(() => _isPlaying = true);
    } catch (e)      {
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

  Future<void> _setSpeed(double value) async {
    await _audioPlayer.setSpeed(SetSpeedRequest(speed: value));
    setState(() => _playbackRate = value);
  }

  Future<void> _getPosition() async {
    final position = await _audioPlayer.getPosition();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Текущая позиция: $position сек")),
    );
  }

  Future<void> _addTrackFromUrl() async {
    if (_audioUrl.isNotEmpty) {
      setState(() {
        _playlist.add(_audioUrl);
        if (_currentTrackIndex == -1) {
          _currentTrackIndex = 0; // Если это первый трек
        }
      });
    }
  }
  
  Future<void> _addTrackFromFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      extensions: <String>['mp3', 'wav', 'm4a'],
    );
  
    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null) {
      final String fileUrl = 'file://${file.path}';
      setState(() {
        _playlist.add(fileUrl);
        if (_currentTrackIndex == -1) {
          _currentTrackIndex = 0; // Если это первый трек
        }
      });
    }
  }


  Future<void> _playTrackAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      try {
        _currentTrackIndex = index;
        await _audioPlayer.setUrl(_playlist[_currentTrackIndex]);
        await _audioPlayer.play(PlayRequest());
        setState(() {
          _isPlaying = true;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка воспроизведения: $e")),
        );
      }
    }
  }

  Future<void> _nextTrack() async {
    if (_currentTrackIndex + 1 < _playlist.length) {
      await _playTrackAtIndex(_currentTrackIndex + 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Конец плейлиста!")),
      );
    }
  }

  Future<void> _previousTrack() async {
    if (_currentTrackIndex - 1 >= 0) {
      await _playTrackAtIndex(_currentTrackIndex - 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Это первый трек!")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Just Audio Aurora Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center,children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                iconSize: 48,
                onPressed: _previousTrack,
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 48,
                onPressed: _isPlaying ? _pause : _play,
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                iconSize: 48,
                onPressed: _nextTrack,
              ),
            ],
            ),
            Slider(
              value: _volume,
              min: 0,
              max: 1,
              onChanged: _setVolume,
            ),
            Text("Громкость: ${(_volume * 100).round()}%"),
            
            Slider(
              value: _playbackRate,
              min: 0.5,
              max: 2.0,
              onChanged: _setSpeed,
            ),
            Text("Скорость: ${_playbackRate.toStringAsFixed(1)}x"),
            
            ElevatedButton(
              onPressed: _getPosition,
              child: const Text("Получить позицию"),
            ),
            
            const SizedBox(height: 20),
            Text("Плейлист:"),
            for (var track in _playlist) Text(track),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _addTrackFromUrl,
                  child: const Text("Добавить по URL"),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addTrackFromFile,
                  child: const Text("Добавить файл"),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: "Введите URL аудио"),
                onChanged: (text) {
                  setState(() {
                    _audioUrl = text;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
