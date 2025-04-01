#include <QMediaPlayer>
#include <flutter/plugin_registrar.h>

class JustAudioAuroraPlayer {
public:
    JustAudioAuroraPlayer();
    ~JustAudioAuroraPlayer();

    void Play(const std::string& url);
    void Pause();
    void Seek();
    void SetPosition();

private:
    std::unique_ptr<QMediaPlayer> player_;
};
