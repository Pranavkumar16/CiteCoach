# CiteCoach React Native UI Preview

A separate Expo / React Native preview for evaluating the new visual design.
It installs as **CiteCoach Preview** (com.citecoach.preview), alongside the Flutter app.

## Included
- Home and searchable Library with optional PDF import.
- Sample quiz with answer feedback, source excerpt, results, and retake.
- Sample flashcards, chapter-selection interface, three accent palettes and dark appearance.
- Safe areas, scrollable screens, keyboard handling, and Android back navigation.
- Android and iOS source configuration.

## Scope
The offline model, PDF extraction, and existing Flutter data are **not connected** in this UI preview.
All sample study content is labeled. No simulated response latency or AI-generated claims are shown.
The Flutter backups and app remain separate.

## Run
npm install
npm start

## Validate
npm run typecheck
npm run export
npx playwright install chromium
npm run test:ui

The Build React Native Preview GitHub Actions workflow creates an installable Android release APK ZIP
and saves rendered screenshots after validation. The APK bundles JavaScript and does not need Metro.
