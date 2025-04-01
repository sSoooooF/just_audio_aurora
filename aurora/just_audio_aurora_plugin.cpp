#include "just_audio_aurora/just_audio_aurora_plugin.h"

#include "just_audio_aurora/just_audio_aurora_plugin.h"

class JustAudioAuroraPlugin::Impl {
public:
  Impl(PluginRegistrar* registrar) : registrar_(registrar),
  player_(std::make_unique<QMediaPlayer>()) {
    channel_ = std::make_unique<MethodChannel>(
      registrar->messenger(),
      "just_audio_aurora",
      &flutter::StandardMethodCodec::GetInstance()
    );

    channel_->SetMethodCallHandler(
      [this] (const auto& call, auto result) {
        HandleMethodCall(call, std::move(result));
      }
    );
  }

  void HandleMethodCall(
    const MethodCall& call,
    std::unique_ptr<MethodResult> result
  ) {
      if (call.method_name().compare("play") == 0)
      {
        player_->play();
        result->Success(EncodableValue(true));
      }
      else if (call.method_name() == "pause") {
        player_->pause();
        result->Success(EncodableValue(true));
      } else if (call.method_name() == "seek") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if(args) {
          int64_t position = std::get<int64_t>(args->at(EncodableValue("position")));
          player_->setPosition(position / 1000);
        }
        result->Success(EncodableValue(true));
      } else {
        result->NotImplemented();
      }
  }

private:
  flutter::PluginRegistrar * registrar_;
  std::unique_ptr<QMediaPlayer> player_;
  std::unique_ptr<MethodChannel> channel_;
}

JustAudioAuroraPlugin::JustAudioAuroraPlugin(PluginRegistrar* registrar) : impl_(std::make_unique<Impl>(registrar)) {};

void JustAudioAuroraPlugin::RegisterWithRegistrar(PluginRegistrar* registrar) {
  auto plugin = std::make_unique<JustAudioAuroraPlugin>(registrar);
  registrar->AddPlugin(std::move(plugin));
}
