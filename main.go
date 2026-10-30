package main

import (
	"flag"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"time"

	"github.com/gopxl/beep/v2"
	"github.com/gopxl/beep/v2/effects"
	"github.com/gopxl/beep/v2/flac"
	"github.com/gopxl/beep/v2/mp3"
	"github.com/gopxl/beep/v2/speaker"
	"github.com/gopxl/beep/v2/vorbis"
	"github.com/gopxl/beep/v2/wav"
)

func main() {
	volumeFlag := flag.Int("volume", 100, "Volume 0-100 (100=original), >100 for boost")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [--volume N] <audio-file>\n", filepath.Base(os.Args[0]))
		fmt.Fprintf(os.Stderr, "  --volume N  Volume 0-100 (default 100), >100 boosts\n")
	}
	flag.Parse()

	if flag.NArg() < 1 {
		flag.Usage()
		os.Exit(1)
	}

	filePath := flag.Arg(0)
	f, err := os.Open(filePath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "beet: open %s: %v\n", filePath, err)
		os.Exit(1)
	}
	defer f.Close()

	streamer, format, err := decode(filePath, f)
	if err != nil {
		fmt.Fprintf(os.Stderr, "beet: decode %s: %v\n", filePath, err)
		os.Exit(1)
	}
	defer streamer.Close()

	// Apply volume
	vol := *volumeFlag
	var volStreamer beep.Streamer
	if vol <= 0 {
		// Mute
		volStreamer = &effects.Volume{
			Streamer: streamer,
			Base:     2,
			Volume:   0,
			Silent:   true,
		}
	} else {
		// Map linear 0-100+ to logarithmic volume (Base=2)
		// Volume = log2(vol/100)
		// 100 -> 0 (original), 50 -> -1 (half), 200 -> +1 (double)
		volFloat := float64(vol) / 100.0
		volDb := math.Log2(volFloat)
		volStreamer = &effects.Volume{
			Streamer: streamer,
			Base:     2,
			Volume:   volDb,
			Silent:   false,
		}
	}

	// Initialize speaker with the decoded format's sample rate.
	// Buffer size = sampleRate / 100 (10ms buffer) for minimal latency.
	speaker.Init(format.SampleRate, format.SampleRate.N(time.Second/100))

	done := make(chan struct{})
	speaker.Play(beep.Seq(volStreamer, beep.Callback(func() {
		close(done)
	})))

	<-done
}

// decode selects the appropriate decoder based on file extension.
func decode(name string, f *os.File) (beep.StreamSeekCloser, beep.Format, error) {
	ext := filepath.Ext(name)
	switch ext {
	case ".wav", ".wave":
		return wav.Decode(f)
	case ".flac":
		return flac.Decode(f)
	case ".mp3":
		return mp3.Decode(f)
	case ".ogg", ".oga":
		return vorbis.Decode(f)
	default:
		// Try WAV first (most common for "minimal player"), then others
		if s, fmt, err := wav.Decode(f); err == nil {
			return s, fmt, nil
		}
		f.Seek(0, 0)
		if s, fmt, err := flac.Decode(f); err == nil {
			return s, fmt, nil
		}
		f.Seek(0, 0)
		if s, fmt, err := mp3.Decode(f); err == nil {
			return s, fmt, nil
		}
		f.Seek(0, 0)
		if s, fmt, err := vorbis.Decode(f); err == nil {
			return s, fmt, nil
		}
		return nil, beep.Format{}, fmt.Errorf("unsupported format: %s", ext)
	}
}