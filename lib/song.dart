import 'package:flutter/material.dart';
import 'package:mobileappsfc/song_repository.dart';

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

  /// 'sample' for the built-in songs, 'lyrics.ovh' for lyrics found online,
  /// 'supabase' for songs loaded from the songs table.
  /// (The default is 'sample'. It used to be 'lyrics.ovh', which made every
  /// built-in song count as an online song.)
  final String source;

  /// Original key of the song, e.g. 'F'. Null if unknown.
  final String? originalKey;

  /// Capo fret (0 = no capo).
  final int capo;

  /// Tempo in BPM. Null if unknown.
  final int? tempo;

  /// Full song in ChordPro format (chords + lyrics). Null for songs that
  /// only have plain lyrics.
  final String? chordpro;

  const Song({
    required this.id,
    required this.title,
    required this.singer,
    required this.lines,
    required this.colors,
    required this.minutes,
    this.syncedLyrics,
    this.source = 'sample',
    this.originalKey,
    this.capo = 0,
    this.tempo,
    this.chordpro,
  });

  /// Builds a [Song] from a row of the Supabase `songs` table.
  factory Song.fromRow(SongRow row) {
    final lines = row.lyricLines;
    // Rough reading time: about 1 minute per 10 lines, at least 1.
    final minutes = (lines.length / 10).ceil().clamp(1, 99);
    return Song(
      id: row.id,
      title: row.title,
      singer: row.artist,
      lines: lines,
      colors: _gradientFor(row.ministry),
      minutes: minutes,
      source: 'supabase',
      originalKey: row.originalKey,
      capo: row.capo,
      tempo: row.tempo,
      chordpro: row.chordpro,
    );
  }

  /// Number of lines with text (blank spacer lines are not counted).
  int get lineCount => lines.where((l) => l.trim().isNotEmpty).length;

  bool get isOnline => source != 'sample';

  /// Lines that have text, without the blank spacer lines. Use this for
  /// short previews on cards.
  List<String> get previewLines =>
      lines.where((l) => l.trim().isNotEmpty).toList();
}

/// Placeholder artwork colors per ministry.
List<Color> _gradientFor(String ministry) {
  switch (ministry) {
    case 'Liveloud':
      return const [Color(0xFF1E3A8A), Color(0xFF0F172A)];
    case 'Ablaze':
      return const [Color(0xFFB45309), Color(0xFF451A03)];
    case 'CFC':
      return const [Color(0xFF166534), Color(0xFF052E16)];
    default:
      return const [Color(0xFF475569), Color(0xFF0F172A)];
  }
}
