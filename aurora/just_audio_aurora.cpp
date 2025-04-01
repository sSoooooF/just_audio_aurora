#include "just_audio_aurora/just_audio_aurora.h"

class JustAudioAurora::Impl {
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
      if (call.method_name() == "play")
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
          player_->setPosition(position);
        }
        result->Success(EncodableValue(true));
      } else if (call.method_name() == "setVolume") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("volume"));
          if (it != args->end()) {
            int volume = std::get<double>(it->second);
            player_->setVolume(volume);
            result->Success(EncodableValue(true));
          }
        }
      } else if (call.method_name() == "setUrl") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("url"));
          std::string url = std::get<std::string>(it->second);
          QUrl qUrl(QString::fromStdString(url));

          if (qUrl.isValid()) {
            player_->setMedia(qUrl);
            result->Success(EncodableValue(true));
          }
          else {
            result->Error("INVALID_URL");
          }
          return;
        }
      } else {
        result->NotImplemented();
      }
  }

private:
  flutter::PluginRegistrar * registrar_;
  std::unique_ptr<QMediaPlayer> player_;
  std::unique_ptr<MethodChannel> channel_;
};

JustAudioAurora::JustAudioAurora(PluginRegistrar* registrar) : impl_(std::make_unique<Impl>(registrar)) {};

void JustAudioAurora::RegisterWithRegistrar(PluginRegistrar* registrar) {
  auto plugin = std::make_unique<JustAudioAurora>(registrar);
  registrar->AddPlugin(std::move(plugin));
};
