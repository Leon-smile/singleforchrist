<img width="720" height="1486" alt="download" src="https://github.com/user-attachments/assets/29a3b4a8-99ae-4834-859c-ca7b37e5fcf4" /><img width="720" height="1473" alt="download" src="https://github.com/user-attachments/assets/b388afd9-6c16-4b75-933c-2072a86d4807" /># SFC Lyrics

A Flutter app for reading, collecting and sharing worship lyrics, made for **Single for Christ**. Know the words. Share the song.

It runs on phone, tablet and web from one codebase, with a dark UI and a lime-green accent. The layout switches automatically: a bottom navigation bar on phones, and a sidebar with a top bar on wide screens (900px and up).

> **Status: work in progress.** Accounts use Supabase (name only, or Google). Songs and playlists still use sample data. See [Roadmap](#roadmap).

## Screenshots

<p align="center">
<img width="719" height="1486" alt="f0b58fc0-f497-4455-8e40-f31a19f10237" src="https://github.com/user-attachments/assets/4bbda7cd-4960-4d4e-b70b-47ffa30545c2" />
<img width="720" height="1473" alt="download" src="https://github.com/user-attachments/assets/829ff565-2b1c-4fac-b4b0-0624a27e9d1c" />
<img width="720" height="1486" alt="download" src="https://github.com/user-attachments/assets/47fb6ce9-89a0-484a-9553-c1dbf6b7a46e" />

</p>

## Features

- **Verse for today**: a Bible verse (KJV) that changes every day, with Reflect, Save and Share.
- **Online lyrics**: search and download lyrics from LRCLIB.
- **Home**: greeting, All / Singers / Lyrics filters, recently read lyrics, a featured lyrics card and a singers row.
- **Search**: recent searches, mood cards, trending lyrics, and live results filtered by Lyrics, Singers, Playlists or Verses.
- **Lyrics reader**: full lyrics for a song, adjustable text size, add to playlist, download, and a "Next up" card.
- **Library**: the "After hours" playlist, with add and remove.
- **Add lyrics**: pick several songs and add them to the playlist in one go.
- **Share playlist**: access setting and a copyable link.
- **Download**: save lyrics as a `.txt` file (one song, a playlist, or everything).
- **Sign in and Create account**: just type a name (names are unique), or continue with Google.
- **Responsive**: phone, tablet and web layouts.

## Tech stack

| Area | Choice |
| --- | --- |
| Framework | Flutter (Dart 3) |
| UI | Material 3, custom dark theme |
| Fonts | `google_fonts` |
| File saving | `file_saver` |
| Backend | Supabase (`supabase_flutter`), `google_sign_in` |
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

- [x] Supabase authentication (name-only and Google)
- [ ] Store songs, singers and playlists in Supabase instead of sample data
- [ ] Real share links for playlists
- [ ] Saved lyrics and per-user library
- [ ] Mood tags on songs for the Search mood cards
- [ ] Chords, transpose and auto-scroll in the lyrics reader
- [ ] Voice search
- [ ] App icon for Android and iOS (for example with `flutter_launcher_icons`)

## Notes

- Name-only accounts are anonymous Supabase users with a unique name in the `profiles` table. Enable *Anonymous sign-ins* in Supabase.
- Google sign in on Android needs an Android OAuth client in Google Cloud (package name and SHA-1).
- Never commit your Supabase keys if you use a service key. The anon key is meant to be public, but keep Row Level Security on.
- The sample lyrics are original placeholder text. Only add lyrics you have the right to use and share.

## License

No license has been chosen yet. Add one before sharing the code publicly.
