import 'package:supabase_flutter/supabase_flutter.dart';

/// One row of the `songs` table in Supabase.
class SongRow {
  final String id;
  final String title;
  final String artist;
  final String ministry;
  final String? originalKey;
  final int capo;
  final int? tempo;

  /// Full song in ChordPro format.
  final String chordpro;

  SongRow({
    required this.id,
    required this.title,
    required this.artist,
    required this.ministry,
    required this.originalKey,
    required this.capo,
    required this.tempo,
    required this.chordpro,
  });

  factory SongRow.fromMap(Map<String, dynamic> m) => SongRow(
    id: m['id'] as String,
    title: m['title'] as String,
    artist: m['artist'] as String,
    ministry: (m['ministry'] ?? 'Other') as String,
    originalKey: m['original_key'] as String?,
    capo: (m['capo'] ?? 0) as int,
    tempo: m['tempo'] as int?,
    chordpro: m['chordpro'] as String,
  );

  /// Lyrics only: chords and {directives} removed.
  List<String> get lyricLines => chordpro
      .split('\n')
      .where((l) => !l.trim().startsWith('{'))
      .map((l) => l.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();

  /// ChordPro text shifted by [steps] semitones (negative = down).
  String transposed(int steps) => transposeChordPro(chordpro, steps);
}

class SongRepository {
  static SupabaseClient get _db => Supabase.instance.client;

  /// All songs, optionally filtered by ministry
  /// ('Liveloud', 'Ablaze', 'CFC', 'Other').
  static Future<List<SongRow>> fetchAll({String? ministry}) async {
    var query = _db.from('songs').select();
    if (ministry != null) query = query.eq('ministry', ministry);
    final data = await query.order('title');
    return (data as List)
        .map((e) => SongRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds a new song to the `songs` table.
  static Future<void> insert({
    required String title,
    required String artist,
    required String ministry,
    String? originalKey,
    int capo = 0,
    int? tempo,
    required String chordpro,
  }) async {
    await _db.from('songs').insert({
      'title': title,
      'artist': artist,
      'ministry': ministry,
      'original_key': originalKey,
      'capo': capo,
      'tempo': tempo,
      'chordpro': chordpro,
    });
  }

  static Future<SongRow?> fetchById(String id) async {
    final data = await _db.from('songs').select().eq('id', id).maybeSingle();
    return data == null ? null : SongRow.fromMap(data);
  }

  /// Simple search over title and artist.
  static Future<List<SongRow>> search(String text) async {
    final q = text.trim();
    if (q.isEmpty) return fetchAll();
    final data = await _db
        .from('songs')
        .select()
        .or('title.ilike.%$q%,artist.ilike.%$q%')
        .order('title');
    return (data as List)
        .map((e) => SongRow.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}

// ----------------------------------------------------------- transposing

const _sharp = [
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

const _flatToSharp = {
  'Db': 'C#',
  'Eb': 'D#',
  'Gb': 'F#',
  'Ab': 'G#',
  'Bb': 'A#',
};

String _shiftNote(String note, int steps) {
  final n = _flatToSharp[note] ?? note;
  final i = _sharp.indexOf(n);
  if (i < 0) return note;
  return _sharp[((i + steps) % 12 + 12) % 12];
}

/// Transposes one chord, e.g. `C#m7/G#` by +2 -> `D#m7/A#`.
String transposeChord(String chord, int steps) {
  final m = RegExp(
    r'^([A-G][#b]?)([^/]*)(?:/([A-G][#b]?))?$',
  ).firstMatch(chord);
  if (m == null) return chord;
  final root = _shiftNote(m.group(1)!, steps);
  final bass = m.group(3) == null ? '' : '/${_shiftNote(m.group(3)!, steps)}';
  return '$root${m.group(2)}$bass';
}

/// Transposes every `[chord]` in a ChordPro string.
String transposeChordPro(String src, int steps) => src.replaceAllMapped(
  RegExp(r'\[([^\]]+)\]'),
  (m) => '[${transposeChord(m.group(1)!, steps)}]',
);
