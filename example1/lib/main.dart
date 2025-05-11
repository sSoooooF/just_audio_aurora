import 'package:flutter/material.dart';
import 'package:just_audio_aurora/just_audio_aurora.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';
import 'soundcloud_track.dart';
import 'soundcloud_api.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundCloud Aurora',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SoundCloudPlayer(),
    );
  }
}

class SoundCloudPlayer extends StatefulWidget {
  const SoundCloudPlayer({super.key});

  @override
  _SoundCloudPlayerState createState() => _SoundCloudPlayerState();
}

class _SoundCloudPlayerState extends State<SoundCloudPlayer> {
  final SoundCloudApi _api = SoundCloudApi();
  final AudioPlayerAurora _player = AudioPlayerAurora("soundcloud_player");
  final TextEditingController _searchController = TextEditingController();

  List<SoundCloudTrack> _tracks = [];
  SoundCloudTrack? _currentTrack;
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 1.0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  late Timer _positionTimer;

  @override
  void initState() {
    super.initState();
    _loadPopularTracks();
    _positionTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      _updatePosition();
    });
  }

  @override
  void dispose() {
    _positionTimer.cancel();
    _player.dispose(DisposeRequest());
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPopularTracks() async {
    setState(() {
      _isLoading = true;
      _tracks = [];
    });

    try {
      final tracks = await _api.getPopularTracks();
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Failed to load tracks: $e");
    }
  }

  Future<void> _searchTracks(String query) async {
    if (query.isEmpty) {
      _loadPopularTracks();
      return;
    }

    setState(() {
      _isLoading = true;
      _tracks = [];
    });

    try {
      final tracks = await _api.searchTracks(query);
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError("Search failed: $e");
    }
  }

  Future<void> _playTrack(SoundCloudTrack track) async {
    try {
      setState(() {
        _currentTrack = track;
        _isPlaying = false;
        _position = Duration.zero;
      });

      await _player.setUrl(track.fullStreamUrl);
      await _player.play(PlayRequest());
      
      setState(() {
        _isPlaying = true;
        _duration = Duration(milliseconds: track.duration);
      });
    } catch (e) {
      _showError("Failed to play track: $e");
    }
  }

  Future<void> _togglePlayPause() async {
    if (_currentTrack == null) return;

    if (_isPlaying) {
      await _player.pause(PauseRequest());
      setState(() => _isPlaying = false);
    } else {
      await _player.play(PlayRequest());
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _updatePosition() async {
    if (!_isPlaying) return;

    final positionMs = await _player.getPosition();
    if (positionMs != null) {
      setState(() {
        _position = Duration(milliseconds: positionMs);
      });
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _player.seek(SeekRequest(
      position: position,
    ));
    setState(() => _position = position);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SoundCloud Aurora'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPopularTracks,
          ),
        ],
      ),
      body: Column(
        children: [
          // Поиск
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search SoundCloud',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _loadPopularTracks();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onSubmitted: _searchTracks,
            ),
          ),

          // Плеер
          if (_currentTrack != null) _buildPlayer(),

          // Список треков
          Expanded(
            child: _isLoading
                ? _buildShimmerLoader()
                : ListView.builder(
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      return ListTile(
                        leading: track.artwork_url != null
                            ? CachedNetworkImage(
                                imageUrl: track.artwork_url!,
                                placeholder: (context, url) => const SizedBox(
                                  width: 50,
                                  height: 50,
                                  child: Icon(Icons.music_note),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : const SizedBox(
                                width: 50,
                                height: 50,
                                child: Icon(Icons.music_note),
                              ),
                        title: Text(track.title),
                        subtitle: Text(track.user.username),
                        onTap: () => _playTrack(track),
                        trailing: _currentTrack?.id == track.id
                            ? const Icon(Icons.equalizer, color: Colors.orange)
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Обложка и информация
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _currentTrack!.artwork_url != null
                    ? CachedNetworkImage(
                        imageUrl: _currentTrack!.artwork_url!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.music_note, size: 40),
                      ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentTrack!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _currentTrack!.user.username,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Прогресс-бар
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Slider(
                  value: _position.inSeconds.toDouble(),
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  onChanged: (value) {
                    _seekTo(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position)),
                      Text(_formatDuration(_duration)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Управление
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  iconSize: 32,
                  onPressed: () {}, // TODO: реализовать предыдущий трек
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 48,
                  ),
                  onPressed: _togglePlayPause,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  iconSize: 32,
                  onPressed: () {}, // TODO: реализовать следующий трек
                ),
              ],
            ),
          ),

          // Громкость
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    onChanged: (value) async {
                      await _player.setVolume(SetVolumeRequest(volume: value));
                      setState(() => _volume = value);
                    },
                  ),
                ),
                const Icon(Icons.volume_up),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              color: Colors.white,
            ),
            title: Container(
              height: 16,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 14,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
