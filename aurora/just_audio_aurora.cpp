#include "just_audio_aurora/just_audio_aurora.h"
#include <gst/gst.h>
#include <iostream>

// TODO: разобраться с EventChannel

class JustAudioAurora::Impl {
public:
  Impl(PluginRegistrar* registrar) : registrar_(registrar) {
    gst_init(NULL, NULL);
    CreatePipeline();
;
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

    is_playing_ = false;
    is_initialized_ = false;
    volume_ = 1.0;
    playback_rate_ = 1.0;
    is_looping_ = false;
  }

  ~Impl() {
    Dispose();
  }

  std::vector<std::string> playlist;
  size_t currentTrackInd = 0;

  // обработка методов из Dart-части
  void HandleMethodCall(
    const MethodCall& call,
    std::unique_ptr<MethodResult> result
  ) {
    try {
      // запуск воспроизведения аудиофайла
      if (call.method_name() == "play") {
        Play();
        result->Success(EncodableValue(true));
      }
      // остановка воспроизведения аудиофайла
      else if (call.method_name() == "pause") {
        Pause();
        result->Success(EncodableValue(true));
      }
      else if (call.method_name() == "seek") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if(args) {
          int64_t position = std::get<int64_t>(args->at(EncodableValue("position")));
          Seek(position);
        }
        result->Success(EncodableValue(true));
      }
      // изменение громкости воспроизведения
      else if (call.method_name() == "setVolume") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("volume"));
          if (it != args->end() && std::holds_alternative<double>(it->second)) {
            SetVolume(std::get<double>(it->second));
          }
        }
        result->Success(EncodableValue(true));
      }
      // установка url аудиофайла
      else if (call.method_name() == "setUrl") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("url"));
          if (it != args->end() && std::holds_alternative<std::string>(it->second)) {
            std::string url = std::get<std::string>(it->second);
            SetSourceUrl(url);
          }
        }
        result->Success(EncodableValue(true));
      }
      else if (call.method_name() == "setPlaylist"){
        const auto* args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("urls"));
          if (it != args->end() && std::holds_alternative<EncodableList>(it->second))
          {
            playlist.clear();
            for (const auto& url : std::get<EncodableList>(it->second)){
              playlist.push_back(std::get<std::string>(url));
            }
            currentTrackInd = 0;
            SetSourceUrl(playlist[currentTrackInd]);
          }
        }
        result->Success(EncodableValue(true));
      }
      else if (call.method_name() == "next") {
        NextTrack();
        result->Success(EncodableValue(true));
      }
      // изменение скорости воспроизведения
      else if (call.method_name() == "setPlaybackRate") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("speed"));
          if (it != args->end() && std::holds_alternative<double>(it->second)) {
            SetPlaybackRate(std::get<double>(it->second));
          }
        }
        result->Success(EncodableValue(true));
      }
      // геттер для получения текущей скорости воспроизведения
      else if (call.method_name() == "getPlaybackRate") {
        result->Success(EncodableValue(playback_rate_));
      }
      // геттер для получения статуса повтора воспроизведения
      else if (call.method_name() == "isLooping") {
        result->Success(EncodableValue(is_looping_ ? "all" : "none"));
      }
      //  
      else if (call.method_name() == "setLooping") {
        const auto *args = std::get_if<EncodableMap>(call.arguments());
        if (args) {
          auto it = args->find(EncodableValue("looping"));
          if (it != args->end() && std::holds_alternative<bool>(it->second)) {
            SetLooping(std::get<bool>(it->second));
          }
        }
        result->Success(EncodableValue(true));
      }
      else if (call.method_name() == "getVolume") {
        result->Success(EncodableValue(volume_));
      }
      else if (call.method_name() == "getPosition") {
        result->Success(EncodableValue(GetPosition()));
      }
      else if (call.method_name() == "dispose") {
        Dispose();
        result->Success(EncodableValue(true));
      }
      else {
        result->NotImplemented();
      }
    } catch (const std::exception& e) {
      result->Error("HANDLE_ERROR", e.what());
    }
  }

private:
  bool CreatePipeline() {
    gst_.playbin = gst_element_factory_make("playbin", "playbin");
    if (!gst_.playbin) {
      std::cerr << "Failed to create playbin" << std::endl;
      return false;
    }

    gst_.panorama = gst_element_factory_make("audiopanorama", "audiopanorama");
    if (gst_.panorama) {
      gst_.audiobin = gst_bin_new(nullptr);
      gst_.audiosink = gst_element_factory_make("autoaudiosink", "autoaudiosink");

      if (!gst_.panorama || !gst_.audiosink) {
        std::cerr << "Failed to create panorama or audiosink elements" << std::endl;
        return false;
      }

      gst_bin_add_many(GST_BIN(gst_.audiobin), gst_.panorama, gst_.audiosink, nullptr);
      gst_element_link(gst_.panorama, gst_.audiosink);

      GstPad* sinkpad = gst_element_get_static_pad(gst_.panorama, "sink");
      gst_.panoramasinkpad = gst_ghost_pad_new("sink", sinkpad);
      gst_element_add_pad(gst_.audiobin, gst_.panoramasinkpad);
      gst_object_unref(GST_OBJECT(sinkpad));

      g_object_set(G_OBJECT(gst_.playbin), "audio-sink", gst_.audiobin, nullptr);
      g_object_set(G_OBJECT(gst_.panorama), "method", 0, nullptr);
    }

    g_signal_connect(gst_.playbin, "source-setup", G_CALLBACK(SourceSetup), &gst_.source);

    gst_.bus = gst_pipeline_get_bus(GST_PIPELINE(gst_.playbin));
    gst_bus_set_sync_handler(gst_.bus, HandleGstMessage, this, nullptr);

    return true;
  }

  static void SourceSetup(GstElement*, GstElement* source, GstElement**) {
    if (g_object_class_find_property(G_OBJECT_GET_CLASS(source), "ssl-strict") != 0) {
      g_object_set(G_OBJECT(source), "ssl-strict", FALSE, nullptr);
    }
  }

  void NextTrack() {
    if (!playlist.empty() && currentTrackInd + 1 < playlist.size()) {
      currentTrackInd++;
      SetSourceUrl(playlist[currentTrackInd]);
      Play();
    } else {
      Stop();
    }
  }
  
  void Play() {
    if (!is_initialized_) return;
    
    Seek(0);
    Resume();
  }

  void Resume() {
    if (!is_playing_) {
      is_playing_ = true;
    }

    if (!is_initialized_) return;

    if (gst_element_set_state(gst_.playbin, GST_STATE_PLAYING) == GST_STATE_CHANGE_FAILURE) {
      std::cerr << "Failed to set pipeline to PLAYING state" << std::endl;
    }
  }

  void Pause() {
    if (is_playing_) {
      is_playing_ = false;
    }
    
    if (!is_initialized_) return;

    if (gst_element_set_state(gst_.playbin, GST_STATE_PAUSED) == GST_STATE_CHANGE_FAILURE) {
      std::cerr << "Failed to set pipeline to PAUSED state" << std::endl;
    }
  }

  void Stop() {
    Pause();
    if (!is_initialized_) return;
    Seek(0);
  }

  void Seek(int64_t position) {
    if (!is_initialized_) return;

    auto nanosecond = position * GST_MSECOND;
    if (!gst_element_seek(gst_.playbin, playback_rate_, GST_FORMAT_TIME,
                         (GstSeekFlags)(GST_SEEK_FLAG_FLUSH | GST_SEEK_FLAG_KEY_UNIT),
                         GST_SEEK_TYPE_SET, nanosecond,
                         GST_SEEK_TYPE_SET, GST_CLOCK_TIME_NONE)) {
      std::cerr << "Failed to seek to position: " << position << std::endl;
    }
  }

  void SetSourceUrl(const std::string& url) {
    if (url_ != url) {
        std::string actual_url;
        if (url.find("://") == std::string::npos) {
            gchar* file_uri = gst_filename_to_uri(url.c_str(), nullptr);
            if (!file_uri) {
                std::cerr << "Failed to convert file path to URI: " << url << std::endl;
                return;
            }
            actual_url = file_uri;
            g_free(file_uri);
        } else {
            actual_url = url;
        }

        url_ = actual_url;

        if (!gst_.playbin && !CreatePipeline()) {
            std::cerr << "Failed to create pipeline for new URL" << std::endl;
            return;
        }

        gst_bus_set_flushing(gst_.bus, TRUE);
        gst_element_set_state(gst_.playbin, GST_STATE_NULL);
        is_playing_ = false;

        if (!url_.empty()) {
            g_object_set(GST_OBJECT(gst_.playbin), "uri", url_.c_str(), nullptr);
            if (gst_element_set_state(gst_.playbin, GST_STATE_READY) == GST_STATE_CHANGE_FAILURE) {
                std::cerr << "Failed to set pipeline to READY state" << std::endl;
            }
        }
        is_initialized_ = true;
    }
  }

  

  int64_t GetPosition() {
    if (!is_initialized_) return -1;

    gint64 position = 0;
    if(!gst_element_query_position(gst_.playbin, GST_FORMAT_TIME, &position)) {
      return -1;
    }

    return position / GST_MSECOND;
  }

  double GetVolume() {
    return volume_;
  }

  void SetVolume(double volume) {
    if (volume > 1) volume = 1;
    else if (volume < 0) volume = 0;
    
    volume_ = volume;
    g_object_set(gst_.playbin, "volume", volume, nullptr);
  }

  double GetPlaybackRate() {
    return playback_rate_;
  }

  int64_t GetRawPosition() {
    if (!is_initialized_) return -1;

    gint64 position = 0;
    if (!gst_element_query_position(gst_.playbin, GST_FORMAT_TIME, &position)) {
      return -1;
    }

    return position / GST_MSECOND;
  }

  void SetPlaybackRate(double playback_rate) {
    if (playback_rate <= 0) {
      std::cerr << "Invalid playback rate: " << playback_rate << std::endl;
      return;
    }

    if (!is_initialized_) return;

    int64_t position = GetRawPosition();
    if (!gst_element_seek(gst_.playbin, playback_rate, GST_FORMAT_TIME,
                         GST_SEEK_FLAG_FLUSH,
                         GST_SEEK_TYPE_SET, position * GST_MSECOND,
                         GST_SEEK_TYPE_SET, GST_CLOCK_TIME_NONE)) {
      std::cerr << "Failed to set playback rate to " << playback_rate << std::endl;
      return;
    }

    playback_rate_ = playback_rate;
  }

  void SetLooping(bool is_looping) {
    is_looping_ = is_looping;
  }

  int64_t GetDuration() {
    if (!is_initialized_) return -1;
    
    gint64 duration;
    if (!gst_element_query_duration(gst_.playbin, GST_FORMAT_TIME, &duration)) {
      std::cerr << "Failed to get duration" << std::endl;
      return -1;
    }
    return duration / GST_MSECOND;
  }

  int64_t GetCurrentPosition() {
    if (!is_initialized_) return -1;
    
    gint64 position = 0;
    if (!gst_element_query_position(gst_.playbin, GST_FORMAT_TIME, &position)) {
      return -1;
    }

    if (is_completed_) {
      is_completed_ = false;
      if (is_looping_) {
        Play();
      } else {
        Stop();
      }
      position = 0;
    }

    return position / GST_MSECOND;
  }

  void Release() {
    is_playing_ = false;
    is_initialized_ = false;
    url_.clear();

    if (gst_.playbin) {
      GstState state;
      gst_element_get_state(gst_.playbin, &state, nullptr, GST_CLOCK_TIME_NONE);
      if (state > GST_STATE_NULL) {
        gst_bus_set_flushing(gst_.bus, TRUE);
        gst_element_set_state(gst_.playbin, GST_STATE_NULL);
      }
    }
  }

  void Dispose() {
    if (!gst_.playbin) return;
    
    Release();

    if (gst_.bus) {
      gst_bus_set_flushing(gst_.bus, TRUE);
      gst_object_unref(GST_OBJECT(gst_.bus));
      gst_.bus = nullptr;
    }

    if (gst_.source) {
      gst_object_unref(GST_OBJECT(gst_.source));
      gst_.source = nullptr;
    }

    if (gst_.panorama) {
      gst_element_set_state(gst_.audiobin, GST_STATE_NULL);
      gst_element_remove_pad(gst_.audiobin, gst_.panoramasinkpad);
      gst_bin_remove(GST_BIN(gst_.audiobin), gst_.audiosink);
      gst_bin_remove(GST_BIN(gst_.audiobin), gst_.panorama);
      gst_.panorama = nullptr;
    }

    gst_object_unref(GST_OBJECT(gst_.playbin));
    gst_.playbin = nullptr;
  }

  static GstBusSyncReply HandleGstMessage(GstBus*, GstMessage* message, gpointer user_data) {
    auto* self = reinterpret_cast<Impl*>(user_data);
    switch (GST_MESSAGE_TYPE(message)) {
      case GST_MESSAGE_STATE_CHANGED:
        if (GST_MESSAGE_SRC(message) == GST_OBJECT(self->gst_.playbin)) {
          GstState old_state, new_state;
          gst_message_parse_state_changed(message, &old_state, &new_state, nullptr);
          if (new_state == GST_STATE_READY) {
            if (gst_element_set_state(self->gst_.playbin, GST_STATE_PAUSED) == GST_STATE_CHANGE_FAILURE) {
              std::cerr << "Failed to set pipeline to PAUSED state" << std::endl;
            }
          }
        }
        break;
      case GST_MESSAGE_EOS:
        self->is_completed_ = true;
        if (self->is_looping_) {
          self->Play();
        }
        else if(!self->playlist.empty() && self->currentTrackInd + 1 < self->playlist.size()){
          self->currentTrackInd++;
          self->SetSourceUrl(self->playlist[self->currentTrackInd]);
          self->Play();
        }
        else {
          self->Stop();
        }
        break;
      case GST_MESSAGE_WARNING: {
        gchar* debug;
        GError* error;
        gst_message_parse_warning(message, &error, &debug);
        std::cerr << "WARNING: " << error->message << " (" << debug << ")" << std::endl;
        g_free(debug);
        g_error_free(error);
        break;
      }
      case GST_MESSAGE_ERROR: {
        gchar* debug;
        GError* error;
        gst_message_parse_error(message, &error, &debug);
        std::cerr << "ERROR: " << error->message << " (" << debug << ")" << std::endl;
        g_free(debug);
        g_error_free(error);
        break;
      }
      default:
        break;
    }

    gst_message_unref(message);
    return GST_BUS_DROP;
  }

  struct {
    GstElement* playbin = nullptr;
    GstElement* source = nullptr;
    GstElement* panorama = nullptr;
    GstElement* audiobin = nullptr;
    GstElement* audiosink = nullptr;
    GstPad* panoramasinkpad = nullptr;
    GstBus* bus = nullptr;
  } gst_;

  flutter::PluginRegistrar* registrar_;
  std::unique_ptr<MethodChannel> channel_;
  
  std::string url_;
  double volume_;
  double playback_rate_;
  bool is_playing_;
  bool is_initialized_;
  bool is_looping_;
  bool is_completed_ = false;
};

JustAudioAurora::JustAudioAurora(PluginRegistrar* registrar) : impl_(std::make_unique<Impl>(registrar)) {}

void JustAudioAurora::RegisterWithRegistrar(PluginRegistrar* registrar) {
  auto plugin = std::make_unique<JustAudioAurora>(registrar);
  registrar->AddPlugin(std::move(plugin));
}
