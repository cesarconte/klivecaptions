# KLiveCaptions 🌐🎙️

> **Subtítulos en vivo (Live Captions) y traducción en tiempo real para KDE Plasma 6.8 sobre Wayland en CachyOS Linux.**

KLiveCaptions proporciona funcionalidad avanzada de subtítulos y traducción en tiempo real:
- **Captura de Audio Nativa (PipeWire + WirePlumber + EasyEffects)**:
  - **Audio del Sistema (`stream.capture.sink=true`)**: Subtitula cualquier sonido que se reproduzca en el PC (videollamadas, conferencias, vídeos de YouTube, podcasts) respetando el sumidero virtual por defecto de PipeWire y la cadena DSP de EasyEffects.
  - **Micrófono**: Subtitula tu propia voz pasando por los filtros de cancelación de ruido.
- **Transcripción Neuronal Local (`whisper.cpp`)**: Inferencia ultrarrápida 100% privada en local.
- **Traducción en Tiempo Real (Ollama Local)**: Traduce cada subtítulo al vuelo (Español, Inglés, Francés, Alemán, Italiano, Portugués) mediante `qwen2.5:7b`.
- **Ventana Nativa KWin Breeze (`Kirigami.ApplicationWindow`)**: Interfaz integrada con las decoraciones y tema del sistema KDE Plasma.

---

## 🚀 Compilación e Instalación

```bash
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
cmake --install build
```

Para ejecutar:
```bash
~/.local/bin/klivecaptions
```
