#include <include/just_audio_aurora/just_audio_aurora_plugin.h>
#include <QtMultimedia/QMediaPlayer>
#include <QtCore/QUrl>

static std::unique_ptr<QMediaPlayer> mediaPlayer;

struct JustAudioAurora::Impl {
  std::unique_ptr<QMediaPlayer> mediaPlayer;
  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> _channel;
};

JustAudioAurora::JustAudioAurora(
  FlutterDesktopPluginRegistrarRef registrar,
  const std::string &id
) : impl(std::make_unique<Impl>()) {
  impl->mediaPlayer = std::make_unique<QMediaPlayer>();

  // получаем messenger из RegistrarRef
  FlutterDesktopMessengerRef messenger = FlutterDesktopPluginRegistrarGetMessenger(registrar);

  impl->_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
    messenger, "just_audio_aurora", &flutter::StandardMethodCodec::GetInstance());

  impl->_channel->SetMethodCallHandler(
    [this](
      const flutter::MethodCall<flutter::EncodableValue> &call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    ){
      if (call.method_name().compare("play") == 0)
      {
        impl->mediaPlayer->play();
        result->Success(flutter::EncodableValue(true));
      }
      else if (call.method_name() == "pause") {
        impl->mediaPlayer->pause();
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "seek") {
        const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());
        if(args) {
          int64_t position = std::get<int64_t>(args->at(flutter::EncodableValue("position")));
          impl->mediaPlayer->setPosition(position / 1000); 
        }
        result->Success(flutter::EncodableValue(true));
      } else {
        result->NotImplemented();
      }
    }
  );
}


JustAudioAurora::~JustAudioAurora() = default;

void JustAudioAurora::RegisterWithRegistrar(
  FlutterDesktopPluginRegistrarRef registrar
) {
  static auto plugin = std::make_unique<JustAudioAurora> (
    registrar, 'default'
  );
}
