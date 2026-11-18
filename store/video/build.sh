#!/usr/bin/env bash
# Render video promo vertikal & horizontal lengkap dengan audio.
# Butuh: node + playwright (chromium), ffmpeg, python3 + numpy + pillow.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p out export
python3 prep.py                       # screenshot bersih untuk animasi
node render.js v out/video_v.mp4 30 & node render.js h out/video_h.mp4 30 & wait
python3 mix.py v h                    # SFX + musik sesuai out/events_*.json
for o in v h; do
  name=$([ $o = v ] && echo vertical-1080x1920 || echo horizontal-1920x1080)
  ffmpeg -v error -y -i out/video_$o.mp4 -i out/audio_$o.wav \
    -af "loudnorm=I=-14:TP=-1.5:LRA=11" -c:v copy -c:a aac -b:a 192k -ar 48000 \
    -shortest -movflags +faststart export/kalkulator-kpr-promo-$name.mp4
  echo "export/kalkulator-kpr-promo-$name.mp4"
done
