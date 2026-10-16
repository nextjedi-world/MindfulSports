# MindfulSports (Mindful Tennis)

Session journal for racket-sport players: log a session, rate technique aspects, record set
scores, see trends. Kotlin Multiplatform + Compose Multiplatform (Android + iOS) on a Supabase
backend.

| | |
|---|---|
| Product id | `mindful-sports` (`NEXTJEDI_PRODUCT`) |
| Stack | `kmp` (NextJedi platform). `ci.yml` and `claude-review.yml` inline the platform's `ci-kmp.yml` (jvm job) and `claude-review.yml`, because this repo is public and `nextjedi-world/platform` is private, so GitHub cannot resolve its reusable workflows from here. Switch back to `uses: nextjedi-world/platform/.github/workflows/ci-kmp.yml@main` once platform is public. |
| Package | `com.ashutosh.mindfultennis` (Android `applicationId`, do not rename) |
| Repo | github.com/nextjedi-world/MindfulSports (**public**); `upstream` = Ashutosh-909/MindfulTennis (never push there) |
| Linear | team `NEX`, project **Mindful Sports**; platform adoption NEX-1071 |

## Commands (the repo contract)
On Windows run Gradle as `sh ./gradlew ...` (or `make ...` from Git Bash); macOS/Linux `./gradlew`.

| Command | Does |
|---|---|
| `make setup` | lefthook git hooks, `.env` and `local.properties` from the examples, warms Gradle |
| `make dev` | `:composeApp:installDebug` and launches the app on a device/emulator |
| `make verify` | ktlint, detekt, commonMain typecheck, unit tests, Android lint, debug APK. **CI and the Stop hook run this; it must stay green.** |
| `make e2e` | `:composeApp:connectedDebugAndroidTest` (skips when no device) |
| `make format` | `ktlintFormat` |
| `make lint` / `make test` / `make build` | the parts of `verify` on their own |
| `make baseline` | re-record lint baselines (only after fixing old findings) |
| `make ios-framework` | (macOS) `:shared:linkDebugFrameworkIosSimulatorArm64` |

Raw Gradle equivalents: `./gradlew :composeApp:assembleDebug`, `./gradlew :composeApp:installDebug`,
`./gradlew :shared:testDebugUnitTest` (`:shared:allTests` on macOS also runs the iOS tests),
`./gradlew ktlintCheck detekt :composeApp:lintDebug`.

iOS: open `iosApp/iosApp.xcodeproj` in Xcode on the Mac (headless builds go through the MacBook
runner, see `D:\Projects\dev-infra\claude.md`). The public repo never uses self-hosted CI runners,
so iOS is not built in CI.

## Lint baselines
ktlint (`config/ktlint/baseline-<module>.xml`), detekt (`config/detekt/baseline.xml`) and Android
lint (`composeApp/lint-baseline.xml`, if present) baseline the findings that existed when the
platform was adopted. New code must be clean. Fix old findings in small, behaviour-free commits,
then `make baseline`. Never add new entries to a baseline to get green.

## Layout
- `shared/`: all product code (KMP). `commonMain` holds UI, ViewModels, domain, data;
  `androidMain` / `iosMain` hold platform `actual`s (Room driver, DataStore path, WorkManager sync).
  - `domain/model`, `domain/usecase`: pure logic (Aspect, Session, ScoreCalculator via `util/`).
  - `data/local` (Room KMP + DataStore), `data/remote` (Supabase DTOs, data sources),
    `data/repository` (interface + impl pairs), `data/sync` (offline-first sync to Supabase).
  - `ui/<screen>`: `XxxScreen`, `XxxViewModel`, `XxxUiState`; `navigation/` routes; `di/` Koin modules.
- `composeApp/`: thin Android app shell (`MainActivity`, Application, Koin start). Reads
  `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `local.properties` into `BuildConfig` (empty is fine
  for builds without a backend).
- `iosApp/`: SwiftUI shell around the `shared` framework; secrets in
  `iosApp/Configuration/Secrets.xcconfig` (git-ignored, template next to it).
- `app/`: legacy single-platform Android app. **Not in `settings.gradle.kts`**; do not build or
  edit it, it is kept for reference only.
- `supabase_*.sql`: schema, migrations and sample data for the Supabase project.
- Design docs: `plan.md` (original screen specs, data model, milestones), `agent.md` (original
  Android-only agent guide; its Hilt/Android-only stack table is out of date, the KMP code wins),
  `docs/multi-sport-architecture.md`, `docs/payment-integration-plan.md`.

## Architecture rules
- MVVM + unidirectional data flow. Screen state is a `StateFlow<XxxUiState>` in the ViewModel,
  collected with `collectAsStateWithLifecycle()`.
- Offline first: writes go to Room, then the sync layer pushes to Supabase. UI reads Room only.
- DI is Koin (`shared/.../di`). Logging is Kermit (`co.touchlab.kermit.Logger`); never log tokens,
  emails or other personal data.
- Put logic in `commonMain` and test it in `commonTest` / `androidUnitTest`. Platform code only
  behind `expect`/`actual` or interfaces.
- Repositories return `Result`/sealed results; never swallow exceptions silently.
- No `GlobalScope`; no network on `Main`; no XML layouts; DataStore, not SharedPreferences.

## Secrets and config
- Never commit `local.properties`, `keystore.properties`, `*.jks`, `Secrets.xcconfig` or `.env`.
  Names only in `local.properties.example`, `keystore.properties.example`, `.env.example`.
- Real values come from the owner (Arunabh) or Key Vault `kv-nextjedi-dev`; CI builds need none.

## Working rules
- Branch from the Linear issue (`gitBranchName`); conventional commits; PR body has `Fixes NEX-123`.
- `make verify` green before saying you are done. Never weaken a lint rule or delete a test.
- New dependencies go in `gradle/libs.versions.toml`, latest stable, and need a reason in the PR.
- Do not claim iOS works unless it was built on the Mac.
- Do not touch the `upstream` remote, release signing, or store metadata without being asked.

## Claude Code specifics
- Plugins `nextjedi-core` and `nextjedi-kmp` are enabled in `.claude/settings.json`
  (marketplace `nextjedi-world/platform`, private: needs `gh auth setup-git` with read access). They
  carry the shared skills, the KMP reviewer and the Stop hook that runs `make verify`.
- Project agent: `.claude/agents/mindful tennis.agent.md`.
