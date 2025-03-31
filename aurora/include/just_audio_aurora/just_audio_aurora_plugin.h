#ifndef FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H
#define FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H

#include <just_audio_aurora/globals.h>

#include <flutter/plugin_registrar.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <string>
#include <memory>

// Flutter encodable
typedef flutter::EncodableValue EncodableValue;
typedef flutter::EncodableMap EncodableMap;
typedef flutter::EncodableList EncodableList;
// Flutter methods
typedef flutter::MethodChannel<EncodableValue> MethodChannel;
typedef flutter::MethodCall<EncodableValue> MethodCall;
typedef flutter::MethodResult<EncodableValue> MethodResult;

class PLUGIN_EXPORT JustAudioAurora final : public flutter::Plugin
{
public:

    JustAudioAurora(FlutterDesktopPluginRegistrarRef registrar, const std::string &id);
    ~JustAudioAurora();

    static void RegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar);

private:
    struct Impl;
    std::unique_ptr<Impl> impl;
};

#endif /* FLUTTER_PLUGIN_JUST_AUDIO_AURORA_PLUGIN_H */
