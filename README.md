# Items

A small notebook built with Flutter. Write a title and body, browse your notes
newest first, and open a note to read its full text and creation time.

The app has three screens: the items list, item detail, and a form for a new
item. Both title and body are required. Back leaves the form without saving and
discards its draft.
While you type, the draft is stored locally. Reopening the app after it is
terminated restores the form and its text; saving clears the draft.
Notes are stored only on your device; there are no accounts or network services.

## Requirements

- Flutter 3.50 stable with Dart 3.14 or later.
- For Linux: the Flutter Linux desktop toolchain (Clang, CMake, Ninja,
  pkg-config, GTK 3 development libraries, and a graphical desktop).
- Android and iOS projects are included. Building them requires an Android SDK
  or macOS with Xcode, respectively.

Check your toolchain with `flutter doctor`.

## Install and run

```sh
flutter pub get
flutter run -d linux
```

For a connected mobile device, use `flutter devices` to find its ID and run
`flutter run -d DEVICE_ID`.

## Build

```sh
flutter build linux
./build/linux/x64/release/bundle/items
```

Keep the entire bundle directory together when moving the Linux app.

## Tests and code style

```sh
flutter test
flutter analyze
dart format --set-exit-if-changed .
```

Tests cover JSON persistence, invalid stored data, creating and reading notes,
required fields, draft restoration after a simulated restart, clearing drafts,
leaving without saving, and storage error handling. The project
keeps the generated `flutter_lints` configuration.

## Local data

`ItemsRepository` stores one JSON-encoded list under the `items` preference key
using `shared_preferences`. Each entry contains `title`, `body`, and `createdAt`
(an ISO 8601 UTC timestamp). Times are shown in the device's local time zone.

The separate `draft` preference key holds one JSON object with the raw `title`
and `body` text. Blank drafts are removed, unreadable drafts are ignored, and
draft operations do not change the `items` key.

The plugin uses the application's local preferences: a JSON preferences file in
the Linux application support directory, Android SharedPreferences, or iOS
NSUserDefaults. On Linux the default file is
`~/.local/share/dev.klyve.items/shared_preferences.json` (or under
`$XDG_DATA_HOME/dev.klyve.items` when set). The plugin prefixes the underlying key as `flutter.items`.
This storage suits small personal notes; it is not encrypted or a backup.
Uninstalling or clearing application data may remove notes.

## License

MIT. Copyright Klyve.
