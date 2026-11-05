# CiteCoach React Native

Expo and TypeScript project for the CiteCoach Android and future iOS app.
The current runnable implementation is a UI preview with labeled sample content.
It installs as **CiteCoach Preview** (`com.citecoach.preview`) alongside Flutter.

## Start development

```sh
cd prototypes/react-native
npm install
npm run generate:icon
npm start
```

- `npm run android`: generate and run Android locally (Android SDK required).
- `npm run ios`: generate and run iOS locally (macOS and Xcode required).
- `npm run web`: browser preview.

## Project structure

- `App.tsx`: Expo entry point.
- `src/app/CiteCoachApp.tsx`: current Home, Library, Learn, Ask and Settings UI.
- `src/data/sampleStudy.ts`: explicitly labeled demonstration content.
- `src/domain/models.ts`: shared book, chapter, citation and progress types.
- `src/services/StudyEngine.ts`: interface for the future offline engine; no implementation.
- `theme/tokens.ts`: forest, paper, mint and dark theme tokens.
- `components/CiteMark.tsx`: approved book and quotation logo.
- `assets/citecoach-logo.json`: supplied original logo encoded for bundling.

## Current behavior

Searchable sample library, document picker, sample chapter selection, quiz feedback
and scoring, flashcards, Ask-to-flashcard interaction, source excerpt sheets,
dark appearance, safe areas, scrollable layouts and Android back handling.
Settings opens from the avatar. Navigation uses Home, Library, Learn and Ask.

## Remaining integration

The offline model, real PDF extraction, persistent imported books, background model
download and existing Flutter data are **not connected**. Sample citations are not
real PDF reader links. The StudyEngine interface is only an integration boundary.
No latency target has been verified.

Next implementation: persistent document storage and extraction; page-aware chapter
indexing; offline engine and resumable model downloads; real study generation with
cancellation and elapsed timing; device validation on Android, then iOS.
Flutter source and backups remain separate.

## Validation and builds

```sh
npm run typecheck
npm run export
npx playwright install chromium
npm run test:ui
```

The **Build React Native Preview** GitHub Actions workflow runs these checks,
captures 320 px and 390 px layouts, and produces a standalone Android APK ZIP.
iOS native builds have not been validated.
