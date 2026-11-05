# CiteCoach Android 0.3.0

This application uses imported PDFs and an actual on-device language model.
No sample answers are used by the active app entry point.

1. Open Settings and download Qwen2.5 0.5B Q4_K_M (approximately 400 MB).
2. Import a text-based PDF. A persistent copy and its extracted page text are saved locally.
3. Select the PDF, enter a topic or question, and choose an optional PDF page range.
4. Generate an answer, flashcards or a quiz. Study sets are saved locally.

Android DownloadManager owns the model transfer and supports background operation.
The download may pause for network or system constraints. Reopening the app queries
the existing job instead of starting a new transfer. Cancel explicitly removes it.
Document content is never sent to a server. Network access is used to obtain the model.

The model is small and answers can be wrong; retrieved passages are shown separately
for verification. Page links open extracted source text, not a visual PDF viewer.
Scanned PDFs, OCR, EPUB, automatic chapter detection and iOS native document support
are not included. Select chapters with the PDF page range. Keep the app foregrounded
while generating; generation is stopped on background to avoid stale jobs.
Cold-start and response latency require real-device measurements; 10 seconds is not guaranteed.

The package remains com.citecoach.preview to update prior React Native installs
without affecting the separate Flutter app. The display name is now CiteCoach.

## Development

Node 22 and JDK 17. Run npm install, npm run generate:icon, npm run android.
TypeScript: npm run typecheck. Core retrieval tests: npm run test:core.
Browser shell checks: npm run export and npm run test:ui.
Native PDF extraction and inference require the Android APK; browser checks cannot verify them.
