import 'package:flutter/material.dart';

class Singer {
  final String name;
  final String highlights; // comma-separated song titles
  final List<Color> colors; // placeholder artwork gradient

  const Singer({
    required this.name,
    required this.highlights,
    required this.colors,
  });
}

class Song {
  final String id;
  final String title;
  final String singer;

  /// One entry per lyric line. Online lyrics keep empty strings between
  /// verses so the reader shows the spacing.
  final List<String> lines;
  final List<Color> colors; // placeholder artwork gradient
  final int minutes;

  /// Time-synced lyrics in LRC format (not available from lyrics.ovh), or null.
  final String? syncedLyrics;

  /// 'sample' for the built-in songs, 'lyrics.ovh' for lyrics found online.
  /// (The default is 'sample'. It used to be 'lyrics.ovh', which made every
  /// built-in song count as an online song.)
  final String source;

  const Song({
    required this.id,
    required this.title,
    required this.singer,
    required this.lines,
    required this.colors,
    required this.minutes,
    this.syncedLyrics,
    this.source = 'sample',
  });

  /// Number of lines with text (blank spacer lines are not counted).
  int get lineCount => lines.where((l) => l.trim().isNotEmpty).length;

  bool get isOnline => source != 'sample';

  /// Lines that have text, without the blank spacer lines. Use this for
  /// short previews on cards.
  List<String> get previewLines =>
      lines.where((l) => l.trim().isNotEmpty).toList();
}
