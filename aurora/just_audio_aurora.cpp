#include "include/just_audio_aurora/just_audio_aurora.h"

JustAudioAurora::JustAudioAurora(
  flutter::PluginRegistrar* registrar,
  const std::string &id
) : registrar_(registrar), id_(id) {
  player_ = std::make_unique<QMediaPlayer>();

  // получаем messenger из RegistrarRef
  flutter::BinaryMessenger* messenger = registrar->messenger();

  channel_ = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
    messenger, "just_audio_aurora", &flutter::StandardMethodCodec::GetInstance());

  channel_->SetMethodCallHandler(
    [this](
      const flutter::MethodCall<flutter::EncodableValue> &call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result
    ){
      if (call.method_name().compare("play") == 0)
      {
        player_->play();
        result->Success(flutter::EncodableValue(true));
      }
      else if (call.method_name() == "pause") {
        player_->pause();
        result->Success(flutter::EncodableValue(true));
      } else if (call.method_name() == "seek") {
        const auto *args = std::get_if<flutter::EncodableMap>(call.arguments());
        if(args) {
          int64_t position = std::get<int64_t>(args->at(flutter::EncodableValue("position")));
          player_->setPosition(position / 1000);
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
  flutter::PluginRegistrar* registrar
) {
  static auto plugin = std::make_unique<JustAudioAurora> (
    registrar, "default"
  );
}
