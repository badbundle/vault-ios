# Release Policy

This project uses tags as the permanent release record. Release branches are
maintenance lines for supported versions, not the historical archive.

## Branches and tags

- Tag every shipped build, including the App Store build number, for example
  `v2.0.0+100123`.
- Use branches like `release/2.0` for `2.0.x` stabilization and hotfix work.
- Keep `main` as the source for future feature releases.
- When a hotfix ships from a release branch, merge or cherry-pick the relevant
  fix back to `main` when it still applies.

## Build numbers

Build numbers are global across all versions and branches. They identify App
Store artifacts, not a marketing-version sequence.

- Do not commit build-number bumps.
- Keep `CURRENT_PROJECT_VERSION` in Git as a floor for the next release build.
- Let Fastlane query App Store Connect/TestFlight and build with the next global
  build number at release time.
- Do not run `bundle exec fastlane ios release` unless you intend to upload a
  real App Store build.

To inspect the next build number without changing project files:

```sh
bundle exec fastlane increment_build
```
