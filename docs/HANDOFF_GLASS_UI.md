# CiteCoach handoff: glass screens + warm amber palette

Base: `main` at `edc7231` (Merge PR #20, feature/glass-chat-ui).
Branch: `claude/serene-feynman-2vgwfq`.

## What is done
1. Glass on Home, Verify, Compare, Learn, Settings.
   - New shared widgets in `lib/core/widgets/glass_surface.dart`: GlassPageHeader, GlassIconBadge, GlassSectionLabel.
   - Home: Ask hero, "Recent" carousel (by lastOpenedAt, else importedAt), tool grid.
   - Scrolling panels use `GlassSurface(blur: false)` per the existing perf rule.
2. Warm amber palette in `lib/core/theme/app_theme_data.dart` + `app_colors.dart`.
   - Midnight/AMOLED accent #F5B544 -> #EF6F4E, citation #EF6F4E.
   - Daylight accent #8F5410, textTertiary #72645A, success #5E7016 (all >= 4.5:1).
   - Home "Processing" pill uses textSecondary so it does not read as accent.
- Verified: `flutter analyze` no errors (Flutter 3.38.5), `flutter test` 114/114 pass.

## Open work (priority order, from the UX review)
1. Home Ask hero looks like a search field but only navigates to Library. Make it a real input that opens chat on the most recent ready doc with the question prefilled, or restyle as a button.
2. Verify/Compare/Learn are opened with `context.go` inside the ShellRoute: Android back likely exits the app and the nav bar highlights Home. Use push with a back button, or make them tabs.
3. Preselect the most recent ready document in Verify/Learn (two most recent in Compare). `HomeScreen.recentDocuments` already exists.
4. Explain disabled CTAs ("Choose a document to start").
5. `warning` (#D9A441) now nearly matches the amber accent across the app (processing screens etc.). Pick a distinct warning colour.
6. Copy: Verify switch subtitle says "Off: ..." while the switch is on; shorten the 3-line header disclaimers.
7. App icon still uses the old lime/plum colours.
8. Not yet done: TalkBack pass, 200% text-size check, setup/processing/reader/voice screens still pre-glass.
