#ifndef FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H
#define FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H

#include "./globals.h"

#include <QUrl>
#include <QMediaPlayer>
#include <QAudioOutput>

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

typedef flutter::PluginRegistrar PluginRegistrar;

class PLUGIN_EXPORT JustAudioAurora final : public flutter::Plugin
{
public:
    explicit JustAudioAurora(PluginRegistrar* registrar);

    static void RegisterWithRegistrar(PluginRegistrar* registrar);

private:
    class Impl;
    std::unique_ptr<Impl> impl_;
};

#endif /* FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H */
