# Release Playbook

Tags are the permanent release record. Release branches are maintenance lines
for supported versions, not the historical archive.

## Branch model

- Keep `main` as the source for future feature releases.
- Create branches like `release/2.0` from `main` when `2.0` is ready for
  stabilization or hotfix support.
- Use `release/2.0` only for `2.0.x` stabilization and hotfix work.
- Tag every shipped build, including the App Store build number, for example
  `v2.0.0+100123`.
- When a hotfix ships from a release branch, merge or cherry-pick the relevant
  fix back to `main` when it still applies.

## Build numbers

Build numbers are global across all versions and branches. They identify App
Store artifacts, not a marketing-version sequence.

- Do not commit build-number bumps.
- Keep `CURRENT_PROJECT_VERSION` in Git as a floor for the next release build.
- Let Fastlane query App Store Connect/TestFlight and build with the next global
  build number at release time.
- It is fine for `release/2.0` to ship a build number higher than a later
  marketing version if that is the next global App Store build number.

To inspect the next build number without changing project files:

```sh
bundle exec fastlane increment_build
```

## Shipping a build

Run the release lane only when you intend to build and upload a real App Store
build:

```sh
bundle exec fastlane ios release
```

The release lane:

- requires a clean Git working tree
- queries App Store Connect/TestFlight for the latest uploaded build number
- builds with `CURRENT_PROJECT_VERSION=<next global build number>`
- uploads the build to App Store Connect
- does not commit build-number changes
- does not create or push Git tags

Record the build number printed by the release lane, for example:

```text
Using release build number 100123
```

If the build succeeded but upload failed, retry the existing IPA upload:

```sh
bundle exec fastlane ios upload
```

The upload lane does not build, bump, commit, or tag anything.

## Tagging a shipped build

After App Store Connect has the uploaded build, tag the shipped commit:

```sh
bundle exec fastlane ios tag_release version:2.0.0 build_number:100123
```

The tag lane:

- requires a clean Git working tree
- tags the current commit as `v<version>+<build_number>`
- accepts `version:2.0` and normalizes it to `2.0.0`
- requires `build_number:` to be passed explicitly
- refuses to overwrite an existing local or remote tag
- pushes only that tag to `origin`

Use the build number printed by `ios release`, not the checked-in
`CURRENT_PROJECT_VERSION` floor.

## Preparing `release/2.0`

Before branching from `main`:

```sh
cd Vault
make format
make lint
cd ..
bundle exec ruby -c fastlane/Fastfile
bundle exec fastlane lanes
```

Then create the maintenance branch:

```sh
git checkout main
git pull --ff-only
git checkout -b release/2.0
git push -u origin release/2.0
```
