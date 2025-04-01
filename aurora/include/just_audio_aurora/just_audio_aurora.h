#ifndef FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H
#define FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H

#include "./globals.h"

#include <QtMultimedia/QMediaPlayer>
#include <QtCore/QUrl>


#include <flutter/plugin_registrar.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <string>
#include <memory>

typedef flutter::EncodableValue EncodableValue;
typedef flutter::EncodableMap EncodableMap;
typedef flutter::EncodableList EncodableList;

typedef flutter::MethodChannel<EncodableValue> MethodChannel;
typedef flutter::MethodCall<EncodableValue> MethodCall;
typedef flutter::MethodResult<EncodableValue> MethodResult;

class JustAudioAurora : public flutter::Plugin
{
public:

    explicit JustAudioAurora(flutter::PluginRegistrar* registrar, const std::string& id);
    virtual ~JustAudioAurora();

    JustAudioAurora(const JustAudioAurora&) = delete;
    JustAudioAurora& operator=(const JustAudioAurora&) = delete;

    static void RegisterWithRegistrar(flutter::PluginRegistrar* registrar);

private:
    flutter::PluginRegistrar * registrar_;
    std::string id_;
    std::unique_ptr<QMediaPlayer> player_;
    std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
};

#endif /* FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H */
