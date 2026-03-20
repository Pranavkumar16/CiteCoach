# React Native vs Flutter: Which is Better for CiteCoach?

## TL;DR

**Flutter is the right choice for CiteCoach.** For an offline-first, on-device AI app that requires platform channels for ML inference, battery monitoring, and pixel-perfect UI — Flutter wins decisively.

---

## Head-to-Head Comparison

| Criteria | Flutter | React Native |
|---|---|---|
| **Language** | Dart | JavaScript/TypeScript |
| **Rendering** | Own engine (Skia/Impeller) | Native components via bridge |
| **Performance** | Near-native (AOT compiled) | Good, but JS bridge overhead |
| **Platform Channels** | First-class MethodChannel API | Native Modules (more boilerplate) |
| **UI Consistency** | Pixel-perfect across platforms | Platform-dependent rendering |
| **Hot Reload** | Stateful hot reload | Fast Refresh |
| **Community** | Growing rapidly | Larger, more mature |
| **Learning Curve** | Dart (easy to learn) | JS/TS (widely known) |
| **App Size** | ~15-20 MB base | ~7-10 MB base |
| **State Management** | Riverpod, Bloc, Provider | Redux, Zustand, Context API |

---

## Why Flutter is Better for CiteCoach

### 1. Platform Channel Performance (Critical)

CiteCoach runs **on-device ML inference** (Gemma 2B LLM + TinyBERT embeddings) via platform channels. Flutter's `MethodChannel` and `EventChannel` provide:

- **Low-latency binary messaging** — essential for streaming LLM tokens (1-2 tokens/sec)
- **Direct Dart ↔ Native communication** — no JS bridge serialization overhead
- **Type-safe platform interface** — fewer runtime errors in ML pipeline

React Native's Native Modules work but add:
- JS bridge serialization/deserialization overhead per token
- Potential frame drops during heavy inference + UI updates
- More complex threading model for async ML operations

### 2. Rendering Engine (Important for Citation UX)

CiteCoach's citation-rich chat UI requires:
- Tappable citation badges inline with text
- Smooth scrolling during streaming responses
- PDF viewer integration with citation navigation

**Flutter** renders everything through its own engine, guaranteeing:
- 60fps during LLM streaming + citation rendering
- Consistent behavior across Android/iOS
- No platform-specific rendering bugs

**React Native** relies on native component bridges, which can cause:
- Jank during heavy text rendering + streaming
- Inconsistent text layout between platforms
- More complex PDF viewer integration

### 3. Battery & Resource Management

CiteCoach monitors battery state and adapts ML behavior (low-power mode, device tier adaptation). Flutter provides:

- Efficient resource usage (AOT-compiled, no JS engine overhead)
- Lower baseline battery consumption
- Direct access to platform battery APIs via clean channels

React Native adds the Hermes JS engine overhead (~5-10 MB RAM, continuous CPU usage for GC), which matters when you're already running a 1.5GB LLM model.

### 4. SQLite & Local Storage

CiteCoach uses SQLite extensively (documents, chunks, embeddings, cache). Flutter's `sqflite` package provides:

- Synchronous-feeling async API
- Efficient binary blob storage (embedding vectors)
- Battle-tested with large datasets

React Native alternatives (react-native-sqlite-storage, WatermelonDB) work but have additional bridge overhead for large result sets like embedding vectors.

### 5. Single Codebase Fidelity

CiteCoach's wireframes show a specific Material Design aesthetic. Flutter delivers **exactly** what you design — no platform-specific deviations. React Native renders native components that may look/behave differently on iOS vs Android.

---

## When React Native Would Be Better

React Native has legitimate advantages in other scenarios:

| Scenario | Why React Native Wins |
|---|---|
| **Web developer team** | Leverage existing JS/TS expertise |
| **Native look & feel** | Uses actual platform components |
| **Brownfield apps** | Easier to integrate into existing native apps |
| **Smaller app size** | ~7 MB vs ~15 MB baseline |
| **Web + Mobile** | Share code with React web apps |
| **Large JS ecosystem** | NPM has more packages than pub.dev |

---

## Performance Benchmarks (General)

| Metric | Flutter | React Native |
|---|---|---|
| **Startup time** | ~300-400ms | ~400-600ms |
| **Frame rate (complex UI)** | 58-60 fps | 50-58 fps |
| **Memory (idle)** | ~40 MB | ~50-70 MB |
| **Binary size (base)** | ~15 MB | ~7 MB |
| **JS Bridge overhead** | None | ~1-5ms per call |

*Note: Benchmarks vary by app complexity and device.*

---

## CiteCoach-Specific Decision Matrix

| CiteCoach Requirement | Flutter Score | React Native Score | Winner |
|---|---|---|---|
| On-device LLM inference via platform channels | 9/10 | 6/10 | **Flutter** |
| Streaming token display (real-time UI) | 9/10 | 7/10 | **Flutter** |
| Embedding vector storage & retrieval | 8/10 | 7/10 | **Flutter** |
| Battery monitoring & adaptation | 8/10 | 7/10 | **Flutter** |
| PDF viewer with citation navigation | 8/10 | 6/10 | **Flutter** |
| Voice input/output (STT/TTS) | 8/10 | 8/10 | Tie |
| Offline-first architecture | 8/10 | 8/10 | Tie |
| Cross-platform UI consistency | 9/10 | 6/10 | **Flutter** |
| Developer hiring pool | 6/10 | 9/10 | **React Native** |
| Ecosystem maturity | 7/10 | 9/10 | **React Native** |
| **Total** | **80/100** | **73/100** | **Flutter** |

---

## Conclusion

For **CiteCoach specifically**, Flutter is the superior choice because:

1. **ML inference pipeline** — Platform channels with minimal overhead are critical for on-device LLM/embedding inference
2. **Battery efficiency** — No JS engine overhead when running a 1.5GB model
3. **UI performance** — Guaranteed 60fps during streaming + citation rendering
4. **Consistent UX** — Pixel-perfect citation badges and chat UI across platforms
5. **SQLite performance** — Efficient handling of large embedding vectors

React Native is an excellent framework for many apps, but CiteCoach's unique requirements (on-device AI, battery management, real-time streaming, citation-rich UI) align strongly with Flutter's strengths.
