/// Converts a "chords above lyrics" chart (like the ones copied from chord
/// sites) into ChordPro, where chords sit inside the lyric line: `[C#m]word`.
library;

final _chordTok = RegExp(
  r'^[A-G][#b]?(?:maj|min|m|sus|dim|aug|add)?\d*(?:/[A-G][#b]?)?$',
);
final _header = RegExp(r'^\s*\[([^\]]+)\](.*)$');

bool _isChordLine(String line) {
  final toks = line.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
  if (toks.isEmpty) return false;
  var chords = 0;
  for (final t in toks) {
    if (_chordTok.hasMatch(t)) {
      chords++;
    } else if (t == '-' ||
        t == '|' ||
        t == 'N.C.' ||
        RegExp(r'^x\d+$').hasMatch(t)) {
      continue;
    } else {
      return false;
    }
  }
  return chords > 0;
}

bool _isHeader(String line) => _header.hasMatch(line);

List<(int, String)> _chordsIn(String chordLine) => [
  for (final m in RegExp(r'\S+').allMatches(chordLine))
    if (_chordTok.hasMatch(m.group(0)!)) (m.start, m.group(0)!),
];

/// Puts the chords of [chordLine] into [lyric].
String _merge(String chordLine, String lyric) {
  final chords = _chordsIn(chordLine);
  if (chords.isEmpty) return lyric;

  final inserts = <(int, String)>[]; // (position in lyric, chord)

  // Sites often collapse the spacing, so the columns no longer line up with
  // the words. In that case spread the chords evenly across the words.
  final compressed =
      chords.length >= 2 && chordLine.trimRight().length <= lyric.length * 0.6;

  if (compressed) {
    final words = [for (final m in RegExp(r'\S+').allMatches(lyric)) m.start];
    if (words.isEmpty) return lyric;
    for (var i = 0; i < chords.length; i++) {
      final w = (i * words.length / chords.length).floor();
      inserts.add((words[w], chords[i].$2));
    }
  } else {
    for (final c in chords) {
      inserts.add((c.$1 > lyric.length ? lyric.length : c.$1, c.$2));
    }
  }

  inserts.sort((a, b) => b.$1.compareTo(a.$1)); // insert from the end
  var out = lyric;
  for (final (pos, chord) in inserts) {
    out = '${out.substring(0, pos)}[$chord]${out.substring(pos)}';
  }
  return out;
}

/// Chart text -> ChordPro text.
String chartToChordPro(String raw) {
  var lines = raw.replaceAll('\r\n', '\n').split('\n');

  // Drop the title / link / capo lines above the first [Section].
  final firstHeader = lines.indexWhere(_isHeader);
  if (firstHeader > 0) lines = lines.sublist(firstHeader);

  final out = <String>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i].trimRight();

    if (line.trim().isEmpty) {
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      i++;
      continue;
    }

    final h = _header.firstMatch(line);
    if (h != null && !_isChordLine(line)) {
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      out.add('{comment: ${h.group(1)!.trim()}${h.group(2)!.trimRight()}}');
      i++;
      continue;
    }

    if (_isChordLine(line)) {
      final next = i + 1 < lines.length ? lines[i + 1].trimRight() : '';
      final nextIsLyric =
          next.trim().isNotEmpty && !_isChordLine(next) && !_isHeader(next);
      if (nextIsLyric) {
        out.add(_merge(line, next));
        i += 2;
      } else {
        // Instrumental line (intro, interlude...): chords only.
        final chords = _chordsIn(line).map((c) => '[${c.$2}]').join(' ');
        out.add(chords);
        i++;
      }
      continue;
    }

    out.add(line);
    i++;
  }

  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  return out.join('\n');
}

/// Details found in the text above the first [Section] of a pasted chart.
class ChartMeta {
  final String? title;
  final String? artist;
  final String? originalKey;
  final int? capo;
  const ChartMeta({this.title, this.artist, this.originalKey, this.capo});
}

ChartMeta parseChartMeta(String raw) {
  final lines = raw.replaceAll('\r\n', '\n').split('\n');

  String? title;
  for (final l in lines) {
    final t = l.trim();
    if (t.isEmpty) continue;
    if (!_isHeader(t)) title = t;
    break;
  }

  String? artist;
  for (final l in lines) {
    final m = RegExp(r'^\s*\[([^\]]+)\]\(http').firstMatch(l);
    if (m != null) {
      artist = m.group(1);
      break;
    }
  }

  final capo = RegExp(r'capo\s*(\d+)', caseSensitive: false).firstMatch(raw);
  final key = RegExp(
    r'transpose to\s+([A-G][#b]?m?)\s+for original key',
    caseSensitive: false,
  ).firstMatch(raw);

  return ChartMeta(
    title: title,
    artist: artist,
    originalKey: key?.group(1),
    capo: capo == null ? null : int.tryParse(capo.group(1)!),
  );
}
