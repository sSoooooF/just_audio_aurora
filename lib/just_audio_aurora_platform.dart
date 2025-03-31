import 'package:just_audio_aurora/just_audio_aurora.dart';
import 'package:just_audio_platform_interface/just_audio_platform_interface.dart';

class JustAudioAuroraPlatform extends JustAudioPlatform{
  @override
  Future<AudioPlayerPlatform> init(InitRequest request) async {
    return AuroraAudioPlayer(request.id);
  }
}

void registerJustAudioAurora() {
  JustAudioPlatform.instance = JustAudioAuroraPlatform();
}
