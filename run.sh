#!/usr/bin/env bash
# Filtered Flutter run — silences noisy Android camera/graphics system logs
flutter run "$@" 2>&1 | grep -v -E \
  "BufferQueueProducer|SurfaceTexture.*queueBuffer|ImageReader.*queueBuffer|slot.*is dropped|queueBuffer: fps=|queueBuffer: slot"
