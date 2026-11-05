import 'dart:convert';

import 'package:http/http.dart' as http;

/// One Bible verse (or short passage) shown on the home page.
class Verse {
  final String reference; // e.g. "Psalm 27:1"
  final String text;
  final String translation; // e.g. "KJV"
  final bool offline; // true when it came from the built-in backup list

  const Verse({
    required this.reference,
    required this.text,
    required this.translation,
    this.offline = false,
  });
}

class VerseException implements Exception {
  final String message;
  const VerseException(this.message);

  @override
  String toString() => message;
}

/// "Verse for today": one verse per calendar day (device local time).
///
/// * The verse is picked from [_references] by the date, so everyone sees the
///   same verse on the same day and it changes by itself every day.
/// * The text comes from https://bible-api.com (free, no API key).
/// * KJV is public domain. Newer translations such as NIV or ESV are
///   copyrighted and need a licence, so they are not used here.
/// * If the request fails, a small built-in KJV list is shown instead so the
///   card is never empty.
class VerseService {
  static const _base = 'https://bible-api.com';

  /// Change to 'web' (World English Bible, also public domain) for
  /// more modern wording.
  static const translationId = 'kjv';
  static const translationLabel = 'KJV';

  /// Each entry is a reference only; the text is fetched from the API.
  static const _references = <String>[
    'psalms 27:1',
    'john 3:16',
    'proverbs 3:5-6',
    'philippians 4:13',
    'psalms 23:1-3',
    'isaiah 41:10',
    'jeremiah 29:11',
    'romans 8:28',
    'joshua 1:9',
    'matthew 11:28',
    'psalms 46:1',
    'romans 12:2',
    'galatians 5:22-23',
    '1 corinthians 13:4-7',
    'hebrews 11:1',
    'psalms 119:105',
    'matthew 6:33',
    'philippians 4:6-7',
    'isaiah 40:31',
    'psalms 121:1-2',
    '2 timothy 1:7',
    'john 14:6',
    'romans 5:8',
    'ephesians 2:8-9',
    'proverbs 18:10',
    'lamentations 3:22-23',
    'psalms 34:8',
    'matthew 5:16',
    'colossians 3:23',
    '1 john 4:19',
    'john 15:5',
    'psalms 37:4',
    'micah 6:8',
    '2 corinthians 5:7',
    'james 1:5',
    'isaiah 26:3',
    'psalms 91:1-2',
    'romans 15:13',
    'deuteronomy 31:6',
    '1 peter 5:7',
    'matthew 28:19-20',
    'psalms 139:14',
    'proverbs 16:3',
    '1 thessalonians 5:16-18',
    'hebrews 13:8',
    'psalms 100:4-5',
    'john 8:12',
    'revelation 21:4',
    '2 corinthians 12:9',
    'ephesians 6:10-11',
    'psalms 62:1-2',
    'isaiah 43:2',
    'john 16:33',
    'psalms 51:10',
    '1 corinthians 10:13',
    'matthew 7:7',
    'philippians 1:6',
    'colossians 3:12-14',
    'psalms 19:14',
    'proverbs 27:17',
    'galatians 6:9',
    'psalms 118:24',
    'romans 10:9',
    '1 john 1:9',
  ];

  /// Backup verses (King James Version, public domain) used when offline.
  static const _backup = <Verse>[
    Verse(
      reference: 'Psalm 27:1',
      text:
          'The LORD is my light and my salvation; whom shall I fear? '
          'the LORD is the strength of my life; of whom shall I be afraid?',
      translation: 'KJV',
      offline: true,
    ),
    Verse(
      reference: 'Psalm 23:1',
      text: 'The LORD is my shepherd; I shall not want.',
      translation: 'KJV',
      offline: true,
    ),
    Verse(
      reference: 'Philippians 4:13',
      text: 'I can do all things through Christ which strengtheneth me.',
      translation: 'KJV',
      offline: true,
    ),
    Verse(
      reference: 'Proverbs 3:5-6',
      text:
          'Trust in the LORD with all thine heart; and lean not unto '
          'thine own understanding. In all thy ways acknowledge him, '
          'and he shall direct thy paths.',
      translation: 'KJV',
      offline: true,
    ),
    Verse(
      reference: 'John 3:16',
      text:
          'For God so loved the world, that he gave his only begotten '
          'Son, that whosoever believeth in him should not perish, '
          'but have everlasting life.',
      translation: 'KJV',
      offline: true,
    ),
  ];

  // Remembers today's verse so the app does not ask the API again.
  static final Map<String, Verse> _cache = {};

  static String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  /// Whole days since 1970 for the local calendar date (same all day long).
  static int _dayNumber(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day).millisecondsSinceEpoch ~/ 86400000;

  /// The reference chosen for [day].
  static String referenceFor(DateTime day) =>
      _references[_dayNumber(day) % _references.length];

  /// Today's verse. Never throws: falls back to the built-in list.
  /// Use [fetchOrThrow] when you want to know that the network failed.
  Future<Verse> verseFor(DateTime day) async {
    final key = _dayKey(day);
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final verse = await _fetch(referenceFor(day));
      _cache[key] = verse;
      return verse;
    } catch (_) {
      return _backup[_dayNumber(day) % _backup.length];
    }
  }

  Future<Verse> fetchOrThrow(DateTime day) async {
    final verse = await _fetch(referenceFor(day));
    _cache[_dayKey(day)] = verse;
    return verse;
  }

  Future<Verse> _fetch(String reference) async {
    final uri = Uri.parse(
      '$_base/${reference.replaceAll(' ', '+')}?translation=$translationId',
    );

    final http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const VerseException("Couldn't reach the Bible service.");
    }
    if (res.statusCode != 200) {
      throw VerseException(
        'The Bible service returned an error (${res.statusCode}).',
      );
    }

    final Object? data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      throw const VerseException('Unexpected reply from the Bible service.');
    }
    if (data is! Map) {
      throw const VerseException('Unexpected reply from the Bible service.');
    }

    var text = (data['text'] ?? '').toString();
    if (text.trim().isEmpty && data['verses'] is List) {
      text = (data['verses'] as List)
          .whereType<Map>()
          .map((v) => (v['text'] ?? '').toString())
          .join(' ');
    }
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) {
      throw const VerseException('The verse came back empty.');
    }

    final ref = (data['reference'] ?? reference).toString().trim();
    return Verse(
      reference: ref.replaceFirst(RegExp(r'^Psalms\b'), 'Psalm'),
      text: text,
      translation: translationLabel,
    );
  }
}
