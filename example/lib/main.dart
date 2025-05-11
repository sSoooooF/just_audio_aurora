import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_aurora/just_audio_aurora.dart';
import 'package:just_audio_aurora/just_audio_aurora_platform.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'package:file_selector_aurora/file_selector_aurora.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
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
  late final AudioPlayerAurora _audioPlayer;
  bool _isPlaying = false;
  double _volume = 1.0;
  double _playbackRate = 1.0;
  String _audioUrl = "";
  TextEditingController _urlController = TextEditingController();
  List<String> _playlist = [
    'assets:///Bones.mp3',
  ];
  int _currentTrackIndex = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late Timer _positionTimer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayerAurora("just_audio_aurora");
    _initPlayer();
    _startPositionTimer();
  }

  Future<void> _initPlayer() async {
    await _playTrackAtIndex(_currentTrackIndex);
  }

  void _startPositionTimer() {
    _positionTimer = Timer.periodic(Duration(milliseconds: 500), (timer) async {
      final positionMs = await _audioPlayer.getPosition();
      if (positionMs != null) {
        setState(() {
          _position = Duration(milliseconds: positionMs);
        });
      }
    });
  }

  @override
  void dispose() {
    _positionTimer.cancel();
    _audioPlayer.dispose(DisposeRequest());
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    await _audioPlayer.setVolume(SetVolumeRequest(volume: _volume));
    await _audioPlayer.setSpeed(SetSpeedRequest(speed: _playbackRate));
    try {
      await _audioPlayer.play(PlayRequest());
      setState(() => _isPlaying = true);
    } catch (e) {
      _showError("Ошибка воспроизведения: $e");
    }
  }

  Future<void> _pause() async {
    await _audioPlayer.pause(PauseRequest());
    setState(() => _isPlaying = false);
  }

  

  Future<void> _playTrackAtIndex(int index) async {
    if (index >= 0 && index < _playlist.length) {
      try {
        String trackUrl = _playlist[index];

        

        await _audioPlayer.setUrl(trackUrl);
        setState(() {
          _currentTrackIndex = index;
          _isPlaying = false;
          _position = Duration.zero;
        });

        await _play();
      } catch (e) {
        _showError("Ошибка загрузки трека: $e");
      }
    }
  }


  Future<void> _nextTrack() async {
    if (_currentTrackIndex + 1 < _playlist.length) {
      await _playTrackAtIndex(_currentTrackIndex + 1);
    } else {
      _showMessage("Конец плейлиста!");
    }
  }

  Future<void> _previousTrack() async {
    if (_currentTrackIndex - 1 >= 0) {
      await _playTrackAtIndex(_currentTrackIndex - 1);
    } else {
      _showMessage("Это первый трек!");
    }
  }

  Future<void> _addTrackFromUrl() async {
    if (_audioUrl.isNotEmpty && !_playlist.contains(_audioUrl)) {
      setState(() {
        _playlist.add(_audioUrl);
      });
      _showMessage("Трек добавлен в плейлист");
    }
  }

  Future<void> _addTrackFromFile() async {
    const XTypeGroup typeGroup = XTypeGroup(
      extensions: <String>['mp3', 'wav', 'm4a', 'ogg'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
    if (file != null) {
      final String fileUrl = 'file://${file.path}';
      if (!_playlist.contains(fileUrl)) {
        setState(() {
          _playlist.add(fileUrl);
        });
        _showMessage("Файл добавлен в плейлист");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aurora Audio Player')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Отображение текущего трека
              Text(
                "Сейчас играет:",
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _playlist[_currentTrackIndex].split('/').last,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              
              // Прогресс-бар
              LinearProgressIndicator(
                value: _duration.inSeconds > 0 
                  ? _position.inSeconds / _duration.inSeconds 
                  : 0,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_formatDuration(_position)),
                  Text(_formatDuration(_duration)),
                ],
              ),
              const SizedBox(height: 20),
              
              // Кнопки управления
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous),
                    iconSize: 36,
                    onPressed: _previousTrack,
                  ),
                  IconButton(
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    iconSize: 48,
                    onPressed: _isPlaying ? _pause : _play,
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next),
                    iconSize: 36,
                    onPressed: _nextTrack,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Громкость
              Row(
                children: [
                  const Icon(Icons.volume_down),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0,
                      max: 1,
                      onChanged: (value) {
                        setState(() => _volume = value);
                        _audioPlayer.setVolume(SetVolumeRequest(volume: value));
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up),
                ],
              ),
              Text("Громкость: ${(_volume * 100).round()}%"),
              const SizedBox(height: 20),
              
              // Скорость
              Row(
                children: [
                  const Icon(Icons.speed),
                  Expanded(
                    child: Slider(
                      value: _playbackRate,
                      min: 0.5,
                      max: 2.0,
                      divisions: 3,
                      label: "${_playbackRate.toStringAsFixed(1)}x",
                      onChanged: (value) {
                        setState(() => _playbackRate = value);
                        _audioPlayer.setSpeed(SetSpeedRequest(speed: value));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Добавление треков
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: "URL аудио",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                onChanged: (text) => _audioUrl = text,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_link),
                      label: const Text("Добавить URL"),
                      onPressed: _addTrackFromUrl,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Добавить файл"),
                      onPressed: _addTrackFromFile,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Плейлист
              Text(
                "Плейлист (${_playlist.length} треков)",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              ..._playlist.asMap().entries.map((entry) {
                final index = entry.key;
                final track = entry.value;
                return ListTile(
                  leading: Text("${index + 1}"),
                  title: Text(track.split('/').last),
                  trailing: _currentTrackIndex == index 
                    ? const Icon(Icons.music_note, color: Colors.blue)
                    : null,
                  onTap: () => _playTrackAtIndex(index),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
