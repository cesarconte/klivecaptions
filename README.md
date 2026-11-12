# KLiveCaptions 🌐🎙️

> **Subtítulos en vivo (Live Captions) y traducción en tiempo real para KDE Plasma 6.8 sobre Wayland en CachyOS Linux.**

KLiveCaptions proporciona funcionalidad avanzada de subtítulos y traducción en tiempo real:
- **Captura de Audio Nativa (PipeWire + WirePlumber + EasyEffects)**:
  - **Audio del Sistema (`stream.capture.sink=true`)**: Subtitula cualquier sonido que se reproduzca en el PC (videollamadas, conferencias, vídeos de YouTube, podcasts) respetando el sumidero virtual por defecto de PipeWire y la cadena DSP de EasyEffects.
  - **Micrófono**: Subtitula tu propia voz pasando por los filtros de cancelación de ruido.
- **Transcripción Neuronal Local (`whisper.cpp`)**: Inferencia ultrarrápida 100% privada en local.
- **Traducción en Tiempo Real (Ollama Local)**: Traduce cada subtítulo al vuelo (Español, Inglés, Francés, Alemán, Italiano, Portugués) mediante `qwen2.5:7b`.
- **Diseño Golden Gate / Liquid Glass (`CachyOS.UI`)**: Ventana `CachyWindow` con marco translúcido y desenfoque de KWin, cabecera de 44 px con divisor duro de 1 px, radios de 20 px y margen perimetral de 18 px. Las acciones primarias viven en la cabecera, el estado de la captura en una píldora de cristal a la izquierda y la transcripción sobre una `CachyCard`. Toda la paleta sale de `CachyTheme`, sin un solo color literal en el cromo.
- **Auditoría de layout automatizada**: la escena real se monta *offscreen* y se verifican las invariantes del diseño (sin solapamientos, sin recortes, sin desbordes) en todos los estados y en un barrido de anchos de 640 a 1440 px.

---

## 🚀 Compilación e Instalación

```bash
# 1. El sistema de diseño (módulo QML + auditor de layout) debe estar instalado
cd ../cachyos-ui
cmake -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/
cmake --build build -j"$(nproc)"
DESTDIR=$HOME/.local cmake --install build

# 2. La aplicación
cd ../klivecaptions
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local -DBUILD_TESTING=ON
cmake --build build
ctest --test-dir build --output-on-failure
cmake --install build
```

Para ejecutar:
```bash
~/.local/bin/klivecaptions
```
