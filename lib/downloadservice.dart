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

/// Saves the lyrics as a .txt file (browser download on web, file save on
/// mobile/desktop). Returns a message you can show to the user.
Future<String> saveLyrics({
  required String fileName,
  required String heading,
  required List<Song> songs,
}) async {
  if (songs.isEmpty) return 'Nothing to download yet';
  try {
    final text = buildLyricsText(heading, songs);
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(utf8.encode(text)),
      ext: 'txt',
      mimeType: MimeType.text,
    );
    return 'Downloaded $fileName.txt';
  } catch (_) {
    return "Couldn't download the lyrics. Please try again.";
  }
}
