# CiteCoach

**Offline Document Intelligence with Evidence-Based Answers**

CiteCoach is a mobile app that lets you ask questions about your documents and get AI-powered answers grounded in specific page citations — all running entirely on your device with no cloud dependency.

## Features

- **Evidence-Based Q&A** — Ask questions about uploaded documents and receive answers with inline page citations you can tap to jump directly to the source
- **Fully Offline** — On-device LLM (Gemma 2B) and embedding model (MiniLM-L6-v2) ensure complete privacy with no API keys or network calls required after setup
- **Multi-Format Support** — PDF, scanned PDF (with OCR), DOCX, DOC, TXT, Markdown, EPUB, and images (JPG, PNG, BMP, WebP, TIFF)
- **Voice Input & Output** — Speech-to-text for asking questions and text-to-speech for listening to answers
- **Built-in PDF Reader** — View documents with page navigation without leaving the app
- **Smart Retrieval** — Hybrid RAG pipeline combining BM25 keyword search with semantic embeddings for accurate context retrieval
- **Response Caching** — Previously asked questions return instant answers from local cache

## How It Works

1. **Upload** a document from your device
2. **Process** — CiteCoach extracts text, chunks it, and generates embeddings on-device
3. **Ask** — Type or speak a question about your document
4. **Get Answers** — Receive AI-generated responses with page-level citations linking back to the source text

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart ^3.5.0) |
| State Management | Riverpod |
| Navigation | go_router |
| Database | SQLite (sqflite) |
| LLM | Gemma 2B Instruct Q4 via platform channels (MediaPipe on Android, MLX/CoreML on iOS) |
| Embeddings | MiniLM-L6-v2 (TFLite) with TF-IDF fallback |
| OCR | Google ML Kit (on-device) |
| PDF | Syncfusion Flutter PDF |
| HTTP | Dio (model download with resume support) |

## Architecture

The project follows **Clean Architecture** organized by feature:

```
lib/
├── core/                # Shared infrastructure (theme, database, constants, widgets)
├── features/
│   ├── setup/           # Onboarding & model download
│   ├── library/         # Document management
│   ├── processing/      # Text extraction & embedding generation
│   ├── reader/          # PDF viewer
│   ├── chat/            # Q&A interface with RAG
│   ├── voice/           # Speech-to-text & text-to-speech
│   └── settings/        # App configuration
└── routing/             # Navigation
```

## Platforms

- **Android** — MediaPipe for LLM inference, Google ML Kit for OCR
- **iOS** — MLX/CoreML for LLM inference, Google ML Kit for OCR

## Getting Started

### Prerequisites

- Flutter SDK (Dart ^3.5.0)
- Android Studio or Xcode

### Setup

```bash
# Clone the repository
git clone https://github.com/pranavkumar16/CiteCoach.git
cd CiteCoach

# Install dependencies
flutter pub get

# Run code generation
dart run build_runner build

# Run the app
flutter run
```

On first launch, CiteCoach will guide you through downloading the on-device AI models (~1.5 GB for the LLM, ~22 MB for embeddings).

## License

See [LICENSE](LICENSE) for details.
