import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:mobileappsfc/song.dart';

/// Plain-text export: heading, then each song with its singer and lines.
String buildLyricsText(String heading, List<Song> songs) {
  final b = StringBuffer();
  b.writeln(heading);
  b.writeln('=' * heading.length);
  b.writeln();
  for (final s in songs) {
    b.writeln(s.title);
    b.writeln('by ${s.singer}');
    b.writeln();
    for (final line in s.lines) {
      b.writeln(line);
    }
    b.writeln();
  }
  return b.toString();
}

/// LRC export (time-synced lyrics) with title and artist tags on top.
String buildLrcText(Song song) {
  final b = StringBuffer();
  b.writeln('[ti:${song.title}]');
  b.writeln('[ar:${song.singer}]');
  b.writeln(song.syncedLyrics ?? '');
  return b.toString();
}

/// Characters that are not allowed in file names on common systems.
String safeFileName(String name) {
  final cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '').trim();
  return cleaned.isEmpty ? 'lyrics' : cleaned;
}

Future<String> _save(String fileName, String ext, String text) async {
  final name = safeFileName(fileName);
  try {
    await FileSaver.instance.saveFile(
      name: name,
      bytes: Uint8List.fromList(utf8.encode(text)),
      ext: ext,
      mimeType: MimeType.text,
    );
    return 'Downloaded $name.$ext';
  } catch (_) {
    return "Couldn't download the lyrics. Please try again.";
  }
}

/// Saves the lyrics as a .txt file (browser download on web, file save on
/// mobile/desktop). Returns a message you can show to the user.
Future<String> saveLyrics({
  required String fileName,
  required String heading,
  required List<Song> songs,
}) async {
  if (songs.isEmpty) return 'Nothing to download yet';
  return _save(fileName, 'txt', buildLyricsText(heading, songs));
}

/// Saves the time-synced version (.lrc) of one song, if it has one.
Future<String> saveLrc(Song song) async {
  final synced = song.syncedLyrics;
  if (synced == null || synced.trim().isEmpty) {
    return 'No synced lyrics for this song';
  }
  return _save(song.title, 'lrc', buildLrcText(song));
}
