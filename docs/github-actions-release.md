# Releasing from GitHub Actions

Workflow: `.github/workflows/release.yml` (NEX-1100). It replaces the Azure Pipelines files
(`azure-pipelines/`, which live on the `feature/multi-sport` line and are superseded by this).

- Triggers: `workflow_dispatch` (input `platforms`: both, android, ios) and tags `v*`. Nothing runs on push to main.
- Android (ubuntu): `bundle exec fastlane android build` -> signed AAB -> Play internal track (draft release).
- iOS (macos-latest): `bundle exec fastlane ios build` -> match (certs in Azure Blob, read only) -> gym -> TestFlight.
- GitHub-hosted runners only. Build jobs use environment `production`: add a required reviewer there to gate releases.
- A platform with missing secrets is skipped and the run summary lists the names.

```bash
gh workflow run release.yml -R nextjedi-world/MindfulSports -f platforms=both
```

## Repository secrets (names only)

| Platform | Secrets |
|---|---|
| Android | `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `PLAY_SERVICE_ACCOUNT_JSON`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_ANDROID_KEY` (optional `ANDROID_KEY_PASSWORD`, defaults to the store password) |
| iOS | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8_BASE64`, `APPLE_TEAM_ID`, `MATCH_PASSWORD`, `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_ACCESS_KEY`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `REVENUECAT_IOS_KEY` |

Optional repository variables: `ANDROID_PACKAGE_NAME`, `IOS_BUNDLE_ID`, `IOS_SCHEME` (defaults `com.mindful.sports`, `com.mindful.sports`, `iosApp`).

Keystore and p8 are base64 of the file. The workflow decodes them into `$RUNNER_TEMP` and deletes them afterwards.
