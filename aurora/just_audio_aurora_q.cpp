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
      }
      else if (call.method_name() == "setVolume") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("volume"));
          if (it != args->end()) {
            if (std::holds_alternative<double>(it->second)) {
              int volume = static_cast<int>(std::get<double>(it->second) * 100);
              player_->setVolume(volume);
              result->Success(EncodableValue(true));
            } else {
              result->Error("INVALID_VOLUME", "Volume must be a double");
            }
          }
        }
      }
      else if (call.method_name() == "setUrl") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("url"));

          if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
            std::string url = std::get<std::string>(it->second);
            QUrl qUrl(QString::fromStdString(url));

            if (qUrl.isValid()) {
              player_->setMedia(QMediaContent(qUrl));
              result->Success(EncodableValue(true));
            }
            else {
              result->Error("INVALID_URL", "Url is not valid");
            }
          }
          else {
            result->Error("INVALID_ARGUMENT", "URL must be a string");
          }
          return;
        }
      } else if (call.method_name() == "dispose") {
        player_->stop();
        player_.reset();
        result->Success(EncodableValue(true));
      }
      else {
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
