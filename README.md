# SFC Lyrics

A Flutter app for reading, collecting and sharing worship lyrics, made for **Single for Christ**. Know the words. Share the song.

It runs on phone, tablet and web from one codebase, with a dark UI and a lime-green accent. The layout switches automatically: a bottom navigation bar on phones, and a sidebar with a top bar on wide screens (900px and up).

> **Status: prototype.** The screens and navigation work with sample data. There is no real backend yet, so sign in, sign up and sharing are simulated. See [Roadmap](#roadmap).

## Features

- **Home**: greeting, All / Singers / Lyrics filters, recently read lyrics, a featured lyrics card and a singers row.
- **Search**: recent searches, mood cards, trending lyrics, and live results filtered by Lyrics, Singers, Playlists or Verses.
- **Lyrics reader**: full lyrics for a song, adjustable text size, add to playlist, download, and a "Next up" card.
- **Library**: the "After hours" playlist, with add and remove.
- **Add lyrics**: pick several songs and add them to the playlist in one go.
- **Share playlist**: access setting and a copyable link.
- **Download**: save lyrics as a `.txt` file (one song, a playlist, or everything).
- **Sign in and Create account**: responsive forms with validation and a password strength meter.
- **Responsive**: phone, tablet and web layouts.

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart 3) |
| UI | Material 3, custom dark theme |
| Fonts | `google_fonts` |
| File saving | `file_saver` |
| State | `ChangeNotifier` + `InheritedNotifier` (`AppState` / `AppScope`) |
| Navigation | A route enum (`AppRoute`) switched in `AppShell` |

## Getting started

### Requirements

- Flutter SDK (the version in `pubspec.yaml`, Dart `^3.11`)
- Chrome for web, or an Android / iOS emulator or device

### Run it

```bash
flutter pub get
flutter run -d chrome     # web
flutter run               # connected phone or emulator
```

### Build for web

```bash
flutter build web
```

The output is in `build/web`.

## Project structure

The project uses a flat `lib/` folder. Names are as they are in your project.

```
lib/
  main.dart            App entry point
  shell.dart           Picks phone or desktop layout and shows the current page
  app_state.dart       Routes, playlist, recents, selected song, downloads
  Theme.dart           Colors (AppColors) and the dark theme
  common.dart          Shared widgets: buttons, chips, sidebar, top bar, bottom nav
  artwork.dart         Gradient placeholder artwork
  logo.dart            LogoMark and LogoLockup widgets
  song.dart            Song and Singer models
  songs.dart           Sample songs and singers
  homepage.dart        Home page
  search_page.dart     Search page
  LyricsPage.dart      Lyrics reader
  library.dart         Playlist page
  share_page.dart      Share playlist page
  signinpage.dart      Sign in page
  registerpage.dart    Create account page
  functions/
    add_lyrics.dart    Add lyrics page
assets/
  sfc_icon.png         App icon
  sfc_lockup.png       Icon with name and tagline
```

## Assets

The logo PNGs are listed in `pubspec.yaml`. Indentation matters in YAML, so keep `assets:` lined up under `uses-material-design:`:

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/sfc_icon.png
    - assets/sfc_lockup.png
```

After adding or changing assets, restart the app (hot reload does not pick them up).

## Customizing

- **Colors and look**: edit `AppColors` in `Theme.dart`. The accent color is one line.
- **Songs and singers**: edit `songs.dart`. Each song has a title, singer, lines, artwork colors and read time.
- **Cover art**: replace the gradient placeholders in `artwork.dart` with `Image.network` or `Image.asset`.
- **Logo**: replace the PNGs in `assets/` and keep the same file names, or change `assetPath` in `logo.dart`.
- **Start page**: change the starting `_route` in `app_state.dart`.
- **Layout breakpoint**: `kDesktopBreakpoint` in `common.dart`.

## Roadmap

- [ ] Supabase authentication (email sign up, sign in, sign out, password reset)
- [ ] Store songs, singers and playlists in Supabase instead of sample data
- [ ] Real share links for playlists
- [ ] Saved lyrics and per-user library
- [ ] Mood tags on songs for the Search mood cards
- [ ] Chords, transpose and auto-scroll in the lyrics reader
- [ ] Voice search
- [ ] App icon for Android and iOS (for example with `flutter_launcher_icons`)

## Notes

- Sign in and Create account only validate the form, then open the app. Any valid email and a long enough password get in.
- The sample lyrics are original placeholder text. Only add lyrics you have the right to use and share.

## License

No license has been chosen yet. Add one before sharing the code publicly.
