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

## Original review backlog (items 1–6 completed below)
1. Home Ask hero looks like a search field but only navigates to Library. Make it a real input that opens chat on the most recent ready doc with the question prefilled, or restyle as a button.
2. Verify/Compare/Learn are opened with `context.go` inside the ShellRoute: Android back likely exits the app and the nav bar highlights Home. Use push with a back button, or make them tabs.
3. Preselect the most recent ready document in Verify/Learn (two most recent in Compare). `HomeScreen.recentDocuments` already exists.
4. Explain disabled CTAs ("Choose a document to start").
5. `warning` (#D9A441) now nearly matches the amber accent across the app (processing screens etc.). Pick a distinct warning colour.
6. Copy: Verify switch subtitle says "Off: ..." while the switch is on; shorten the 3-line header disclaimers.
7. App icon still uses the old lime/plum colours.
8. Not yet done: TalkBack pass, 200% text-size check, setup/processing/reader/voice screens still pre-glass.

## UX follow-up (2026-11-04)

Continuation branch: `codex/glass-ux-refinement`, based on this glass branch, not main.
The first three follow-up commits were pushed to the original branch before the user
changed the destination instruction. Further work is on the continuation branch only;
no pull request was opened.

### Finished
- Home Ask hero is a real text field. Submit trims/encodes the question, picks the
  most recent ready PDF using `HomeScreen.recentDocuments`, records its open time,
  and pushes Chat with an editable draft. It does not auto-send. If none is ready,
  submit opens Library.
- Verify/Compare/Learn are pushed root routes outside the bottom-nav shell, with
  explicit back buttons. This preserves Home underneath and avoids highlighting
  the Home tab while in a tool. Direct-entry back buttons fall back to Home.
- Verify and Learn preselect the most recent ready document; Compare preselects
  the two most recent. Sorting reuses the Home helper and keeps all ready options.
- Opening a document updates in-memory recency after persistence succeeds, so the
  defaults reflect navigation in this session without requiring an app restart.
- Disabled form buttons explain missing claims/topics/questions or duplicate
  comparison sources; empty document states explain the required PDF import.
- Verify switch subtitle follows its state. Tool intros are short; evidence
  caveats sit beside results instead of in the introductory copy.
- Warning is lavender: Midnight/AMOLED #C6B5FF, Daylight #65509B. Contrast against
  background/surface/elevated surfaces is 7.80–11.45:1 in dark themes and
  5.48–6.62:1 in Daylight. Contrast tests include the composited glass panel and
  solid high-contrast surfaces. Warning status text/icons remain distinct from amber.
- Processing and document-ready screens were inspected: neither uses a warning
  token. Their existing accent/error/success states were not recoloured as warnings.
- Scrolling surfaces retain `blur: false`; no widget-local hex colours added.

### Validation
- Local `git diff --check` passes.
- Flutter is not installed locally. Branch CI uses Flutter 3.38.5 for targeted
  analysis, the full test suite, and 390x844 Home/Verify/Compare/Learn renders in
  Midnight/Daylight/AMOLED (including scrolled views).
- Added regression coverage for Home submit/draft/Library fallback, recent-source
  defaults, live recency, tool Back navigation, switch copy, duplicate comparison
  sources, high contrast and 200% tool text size.
- Targeted analysis on Flutter 3.38.5: **No issues found**.
- Visually inspected all 12 screen/theme combinations at 390x844, plus their
  scrolled captures: readable labels, intact form layouts, no clipped controls.
- First regression run: 136 passed; the Home push test incorrectly inspected the
  browser URL rather than the imperative route. Corrected the test to assert the
  displayed chat document, editable draft and retained back stack.
- Final full-suite result: **passed** on code commit `c63dcdb` in run
  https://github.com/Pranavkumar16/CiteCoach/actions/runs/41798796470.
  The release APK build is still running at the time of this note.

### Still open
- Optional glass migration for setup, processing, reader and voice is not included.
- App icon still needs palette reconciliation.
- Physical OnePlus/TalkBack pass remains open. Widget rendering is not device
  performance verification.
- 200% Home layout beyond the tool forms still needs a dedicated accessibility pass.
