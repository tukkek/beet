# Beet
> CLI audio player

```bash
beet file.wav
beet file.mp3
beet file.flac
beet file.ogg

beet --volume 100 file.mp3  # 100% volume
```

Download precompiled binaries from https://github.com/tukkek/beet/releases/.

Supported systems:
* Linux
* Windows

Supported audio-formats:
* WAV
* FLAC
* MP3
* OGG/Vorbis

# Building
Builds with `build.sh` and tests with `./test/test.sh`. 

Requires:
* Go 1.23+
* `gcc-mingw-w64` to optionally compile to Windows

# Credits
* https://github.com/gopxl/beep
