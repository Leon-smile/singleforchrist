import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobileappsfc/song.dart';

class LyricsServiceException implements Exception {
  final String message;

  LyricsServiceException(this.message);

  @override
  String toString() => message;
}

/// Online lyrics from api.lyrics.ovh.
///
/// lyrics.ovh has no "search by lyrics" endpoint, so [search] asks its
/// /suggest endpoint for matching songs (title / artist), then loads the
/// lyrics of the top matches IN PARALLEL (the old loop did them one by one,
/// which was very slow).
class LyricsOvhService {
  static const String _host = 'api.lyrics.ovh';
  static const Duration _timeout = Duration(seconds: 15);

  static const List<List<Color>> _palettes = [
    [Color(0xFFE08A3C), Color(0xFF1F2A1E)],
    [Color(0xFF4F7A68), Color(0xFF16221D)],
    [Color(0xFFB04BFF), Color(0xFF2A1B6B)],
    [Color(0xFF5B8BD6), Color(0xFF1B2342)],
    [Color(0xFFE5654A), Color(0xFF3A1B1B)],
    [Color(0xFFD9A441), Color(0xFF2B2416)],
    [Color(0xFF6E8FA6), Color(0xFF1A242C)],
  ];

  /// Searches songs and returns the ones whose lyrics could be loaded.
  Future<List<Song>> search(String query, {int limit = 8}) async {
    final q = query.trim();
    if (q.length < 2 || limit <= 0) return const [];

    try {
      // STEP 1: matching songs.
      final suggestUri = Uri(
        scheme: 'https',
        host: _host,
        pathSegments: ['suggest', q],
      );
      final res = await http.get(suggestUri).timeout(_timeout);
      debugPrint('Lyrics.ovh search status: ${res.statusCode}');

      if (res.statusCode == 429 || res.statusCode == 503) {
        throw LyricsServiceException(
          'Lyrics service is busy. Please try again later.',
        );
      }
      if (res.statusCode != 200) {
        throw LyricsServiceException('Song search failed (${res.statusCode}).');
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(utf8.decode(res.bodyBytes));
      } catch (_) {
        throw LyricsServiceException('Invalid response from lyrics search.');
      }
      if (decoded is! Map || decoded['data'] is! List) return const [];

      // STEP 2: unique candidates (a few extra, since some have no lyrics).
      final candidates = <_Candidate>[];
      final seen = <String>{};
      for (final item in decoded['data'] as List) {
        if (candidates.length >= limit + 4) break;
        if (item is! Map) continue;

        final title = item['title']?.toString().trim() ?? '';
        final artistData = item['artist'];
        final artist = artistData is Map
            ? artistData['name']?.toString().trim() ?? ''
            : '';
        if (title.isEmpty || artist.isEmpty) continue;

        final key = '$title|$artist'.toLowerCase();
        if (!seen.add(key)) continue;

        candidates.add(
          _Candidate(
            id: item['id']?.toString() ?? key,
            title: title,
            artist: artist,
          ),
        );
      }

      // STEP 3: load all lyrics at the same time.
      LyricsServiceException? busy;
      final loaded = await Future.wait(
        candidates.map((c) async {
          try {
            final lyrics = await getLyrics(artist: c.artist, title: c.title);
            if (lyrics == null || lyrics.trim().isEmpty) return null;
            return _toSong(c, lyrics);
          } on LyricsServiceException catch (e) {
            busy = e;
            return null;
          } catch (e) {
            debugPrint('Failed to load lyrics for ${c.title}: $e');
            return null;
          }
        }),
      );

      final songs = loaded.whereType<Song>().take(limit).toList();
      if (songs.isEmpty && busy != null) throw busy!;

      debugPrint('Lyrics.ovh loaded ${songs.length} songs.');
      return songs;
    } on LyricsServiceException {
      rethrow;
    } catch (e) {
      debugPrint('Lyrics.ovh request failed: $e');
      final why = e.toString().replaceAll(RegExp(r'\s+'), ' ');
      throw LyricsServiceException(
        "Couldn't reach the lyrics service. "
        '${why.length > 140 ? '${why.substring(0, 140)}...' : why}',
      );
    }
  }

  /// Lyrics for one song, or null when there are none.
  Future<String?> getLyrics({
    required String artist,
    required String title,
  }) async {
    // pathSegments encodes each part safely (names like "AC/DC" or "What?").
    final uri = Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['v1', artist, title],
    );

    final response = await http.get(uri).timeout(_timeout);
    debugPrint('Lyrics request: $artist - $title | ${response.statusCode}');

    if (response.statusCode == 404) return null;
    if (response.statusCode == 429 || response.statusCode == 503) {
      throw LyricsServiceException(
        'Lyrics service is temporarily unavailable.',
      );
    }
    if (response.statusCode != 200) return null;

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return null;
      return decoded['lyrics']?.toString();
    } catch (_) {
      return null;
    }
  }

  /// Loads ONE song again from what a playlist saved (id, title, artist).
  /// Null when its lyrics are not available right now.
  Future<Song?> loadSong({
    required String id, // without the "lyrics-ovh-" prefix
    required String title,
    required String artist,
  }) async {
    final lyrics = await getLyrics(artist: artist, title: title);
    if (lyrics == null || lyrics.trim().isEmpty) return null;
    return _toSong(_Candidate(id: id, title: title, artist: artist), lyrics);
  }

  Song? _toSong(_Candidate c, String lyrics) {
    final lines = _tidy(lyrics);
    if (lines.isEmpty) return null;

    final textLines = lines.where((l) => l.trim().isNotEmpty).length;
    return Song(
      id: 'lyrics-ovh-${c.id}',
      title: c.title,
      singer: c.artist,
      lines: lines,
      colors: _palettes[c.id.hashCode.abs() % _palettes.length],
      minutes: (textLines / 16).ceil().clamp(1, 99).toInt(),
      syncedLyrics: null, // lyrics.ovh has no time-synced lyrics
      source: 'lyrics.ovh',
    );
  }

  /// Cleans lyrics and removes unnecessary blank lines.
  List<String> _tidy(String text) {
    final raw = text
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n');

    // lyrics.ovh sometimes starts with a "Paroles de la chanson ..." header.
    if (raw.isNotEmpty &&
        raw.first.trim().startsWith('Paroles de la chanson')) {
      raw.removeAt(0);
    }

    final output = <String>[];
    for (final line in raw) {
      final cleaned = line.trimRight();
      if (cleaned.isEmpty && (output.isEmpty || output.last.isEmpty)) continue;
      output.add(cleaned);
    }
    while (output.isNotEmpty && output.last.isEmpty) {
      output.removeLast();
    }
    return output;
  }
}

class _Candidate {
  final String id;
  final String title;
  final String artist;
  const _Candidate({
    required this.id,
    required this.title,
    required this.artist,
  });
}
