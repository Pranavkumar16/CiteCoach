# CiteCoach

Offline document intelligence app built with Flutter. Import PDFs, ask questions, and get evidence-based answers with page citations — all processed on-device with no data leaving your phone.

## Features

- **100% Offline & Private** — Documents never leave your device. All AI processing runs locally after a one-time model download.
- **Document Q&A with Citations** — Ask questions about imported PDFs and get answers with tappable citation badges that jump to the exact source page.
- **Voice Input & Read Aloud** — Ask questions by voice (speech-to-text) and have answers read back (text-to-speech) using platform-native engines.
- **PDF Reader** — Built-in reader with page navigation, search, and zoom. Citations from chat link directly to highlighted passages.
- **Document Processing** — Automatic text extraction, chunking, and embedding for fast retrieval-augmented Q&A.

## Architecture

```
lib/
  core/           # Theme, constants, shared widgets, services
  features/
    setup/        # Splash, privacy, model download flow
    library/      # Document library with import
    processing/   # PDF text extraction & embedding pipeline
    chat/         # Document Q&A with citation support
    reader/       # PDF viewer with navigation
    voice/        # Speech-to-text & text-to-speech overlay
    settings/     # Offline status, performance, voice settings
  routing/        # GoRouter configuration
```

**State management:** Riverpod  
**Navigation:** GoRouter  
**Database:** SQLite (sqflite)  
**PDF:** Syncfusion Flutter PDF Viewer  
**Voice:** speech_to_text + flutter_tts  
**Font:** Lexend  

## Getting Started

### Prerequisites

- Flutter SDK >= 3.5.0
- Android Studio or Xcode for platform builds

### Setup

```bash
flutter pub get
flutter run
```

### First Launch

1. Splash screen auto-advances to the privacy notice
2. One-time offline engine download (~1.5 GB over Wi-Fi) — can be deferred with "Download Later"
3. Import a PDF from your device
4. Start chatting with citation-backed answers

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `lib/core/constants/` | App strings, dimensions, color palette |
| `lib/core/theme/` | Material 3 dark theme with Lexend font |
| `lib/core/widgets/` | Reusable components (buttons, logo, progress bars) |
| `lib/core/services/` | Storage, database, and platform services |
| `lib/features/*/domain/` | State models and entities |
| `lib/features/*/data/` | Data sources, repositories, AI service |
| `lib/features/*/presentation/` | Screens and widgets |
| `lib/features/*/providers/` | Riverpod state providers |

## License

Proprietary. All rights reserved.
