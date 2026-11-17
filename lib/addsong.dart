import 'package:flutter/material.dart';
import 'package:mobileappsfc/chartconvert.dart';
import 'package:mobileappsfc/song_repository.dart';
import 'package:mobileappsfc/theme.dart';

/// Add a song (with chords) to the Supabase `songs` table.
class AddSongPage extends StatefulWidget {
  const AddSongPage({super.key});

  @override
  State<AddSongPage> createState() => _AddSongPageState();
}

class _AddSongPageState extends State<AddSongPage> {
  final _title = TextEditingController();
  final _artist = TextEditingController();
  final _chordpro = TextEditingController();

  String _ministry = 'Liveloud';
  String? _keyName; // root note, e.g. 'G' or 'C#'. Null = not set.
  bool _minor = false;
  int _capo = 0;
  int? _tempo; // BPM. Null = not set.
  bool _saving = false;
  final _taps = <DateTime>[];

  static const _ministries = ['Liveloud', 'Ablaze', 'CFC', 'Other'];
  static const _notes = [
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
  static const _flats = {
    'Db': 'C#',
    'Eb': 'D#',
    'Gb': 'F#',
    'Ab': 'G#',
    'Bb': 'A#',
  };

  static const _mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 12.5,
    height: 1.6,
  );

  @override
  void dispose() {
    _title.dispose();
    _artist.dispose();
    _chordpro.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------------ key

  String? get _keyValue =>
      _keyName == null ? null : '$_keyName${_minor ? 'm' : ''}';

  void _setKey(String k) {
    final minor = k.endsWith('m');
    var root = minor ? k.substring(0, k.length - 1) : k;
    root = _flats[root] ?? root;
    if (_notes.contains(root)) {
      _keyName = root;
      _minor = minor;
    }
  }

  void _shiftKey(int steps) {
    if (_keyName == null) {
      setState(() => _keyName = 'C');
      return;
    }
    final i = _notes.indexOf(_keyName!);
    setState(() => _keyName = _notes[((i + steps) % 12 + 12) % 12]);
  }

  // ---------------------------------------------------------------- tempo

  void _tapTempo() {
    final now = DateTime.now();
    if (_taps.isNotEmpty && now.difference(_taps.last).inMilliseconds > 2000) {
      _taps.clear();
    }
    _taps.add(now);
    if (_taps.length > 6) _taps.removeAt(0);
    if (_taps.length >= 2) {
      final span = _taps.last.difference(_taps.first).inMilliseconds;
      final avg = span / (_taps.length - 1);
      setState(() => _tempo = (60000 / avg).round().clamp(30, 300));
    }
  }

  // --------------------------------------------------------------- editor

  void _insert(String text, {int back = 0}) {
    final t = _chordpro.text;
    final sel = _chordpro.selection;
    final start = sel.isValid ? sel.start : t.length;
    final end = sel.isValid ? sel.end : t.length;
    _chordpro.value = TextEditingValue(
      text: t.replaceRange(start, end, text),
      selection: TextSelection.collapsed(offset: start + text.length - back),
    );
  }

  void _transpose(int steps) {
    setState(() {
      _chordpro.text = transposeChordPro(_chordpro.text, steps);
      if (_keyName != null) {
        final i = _notes.indexOf(_keyName!);
        _keyName = _notes[((i + steps) % 12 + 12) % 12];
      }
    });
  }

  void _autoFormat() {
    final out = <String>[];
    for (final l in _chordpro.text.replaceAll('\r\n', '\n').split('\n')) {
      final line = l.trimRight();
      if (line.isEmpty && (out.isEmpty || out.last.isEmpty)) continue;
      out.add(line);
    }
    while (out.isNotEmpty && out.last.isEmpty) {
      out.removeLast();
    }
    setState(() => _chordpro.text = out.join('\n'));
  }

  /// Turns a pasted "chords above lyrics" chart into ChordPro and fills in
  /// the title, artist, key and capo it can find.
  void _convert() {
    final raw = _chordpro.text;
    if (raw.trim().isEmpty) return;
    final meta = parseChartMeta(raw);
    setState(() {
      if (_title.text.trim().isEmpty && meta.title != null) {
        _title.text = meta.title!;
      }
      if (_artist.text.trim().isEmpty && meta.artist != null) {
        _artist.text = meta.artist!;
      }
      if (meta.originalKey != null) _setKey(meta.originalKey!);
      if (meta.capo != null) _capo = meta.capo!.clamp(0, 11);
      _chordpro.text = chartToChordPro(raw);
    });
    _toast('Converted. Check the chord positions.');
  }

  void _cheatSheet() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surfaceHigh,
        title: const Text('ChordPro cheat sheet'),
        content: const Text(
          'Chords go inside the lyric, right before the word:\n'
          '[G]Holy [D]presence\n\n'
          'Section label (not shown as lyrics):\n'
          '{c: Verse 1}\n'
          '{c: Chorus}\n\n'
          'Chord-only line:\n'
          '[E] [A] [C#m] [A]\n\n'
          'Slash chords work too: [A/C#]',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- save

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return _toast('Add a song title');
    if (_artist.text.trim().isEmpty) return _toast('Add an artist');
    if (_chordpro.text.trim().isEmpty) return _toast('Add the chords + lyrics');

    setState(() => _saving = true);
    try {
      await SongRepository.insert(
        title: _title.text.trim(),
        artist: _artist.text.trim(),
        ministry: _ministry,
        originalKey: _keyValue,
        capo: _capo,
        tempo: _tempo,
        chordpro: _chordpro.text,
      );
      if (!mounted) return;
      _toast('Song saved');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save: $e');
    }
  }

  // ---------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  _ministryCard(),
                  const SizedBox(height: 12),
                  _textCard('SONG TITLE', _title, 'e.g. Oh What Praise'),
                  const SizedBox(height: 12),
                  _textCard('ARTIST OR COMPOSER', _artist, 'e.g. Liveloud'),
                  const SizedBox(height: 22),
                  _sectionLabel('MUSICAL TUNING'),
                  const SizedBox(height: 10),
                  _tuningRow(),
                  const SizedBox(height: 22),
                  _editorHeader(),
                  const SizedBox(height: 10),
                  _editor(),
                ],
              ),
            ),
            _bottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.chevron_left_rounded, size: 28),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Add song',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    ),
  );

  Widget _tinyLabel(String text) => Text(
    text,
    style: const TextStyle(
      color: AppColors.muted,
      fontSize: 9.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    ),
  );

  Widget _ministryCard() {
    return _card(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.selectedTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.music_note_rounded,
              color: AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _tinyLabel('MINISTRY / PROJECT'),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _ministry,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.selectedTint,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: AppColors.surfaceHigh,
            onSelected: (v) => setState(() => _ministry = v),
            itemBuilder: (_) => [
              for (final m in _ministries)
                PopupMenuItem(value: m, child: Text(m)),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.muted.withAlpha(90)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Change', style: TextStyle(fontSize: 12)),
                  SizedBox(width: 2),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textCard(String label, TextEditingController c, String hint) {
    return _card(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tinyLabel(label),
          TextField(
            controller: c,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            height: 30,
            child: Icon(icon, size: 16, color: AppColors.muted),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required String unit,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
    VoidCallback? onUnitTap,
    Widget? extra,
  }) {
    return Expanded(
      child: _card(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _tinyLabel(label),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: onUnitTap,
                  child: Text(
                    unit,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _stepBtn(Icons.remove_rounded, onMinus),
                const SizedBox(width: 8),
                _stepBtn(Icons.add_rounded, onPlus),
              ],
            ),
            if (extra != null) ...[const SizedBox(height: 8), extra],
          ],
        ),
      ),
    );
  }

  Widget _tuningRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _statCard(
          label: 'KEY',
          value: _keyName ?? '—',
          unit: _minor ? 'Minor' : 'Major',
          onUnitTap: () => setState(() => _minor = !_minor),
          onMinus: () => _shiftKey(-1),
          onPlus: () => _shiftKey(1),
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'CAPO',
          value: '$_capo',
          unit: 'Fret',
          onMinus: () => setState(() => _capo = (_capo - 1).clamp(0, 11)),
          onPlus: () => setState(() => _capo = (_capo + 1).clamp(0, 11)),
        ),
        const SizedBox(width: 10),
        _statCard(
          label: 'TEMPO',
          value: _tempo == null ? '—' : '$_tempo',
          unit: 'BPM',
          onMinus: () {
            if (_tempo != null) {
              setState(() => _tempo = (_tempo! - 1).clamp(30, 300));
            }
          },
          onPlus: () =>
              setState(() => _tempo = ((_tempo ?? 71) + 1).clamp(30, 300)),
          extra: SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _tapTempo,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withAlpha(140)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                minimumSize: const Size(0, 30),
              ),
              child: const Text('Tap Tempo', style: TextStyle(fontSize: 11)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _editorHeader() {
    return Row(
      children: [
        _sectionLabel('CHORDS + LYRICS'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.selectedTint,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'ChordPro',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Spacer(),
        InkWell(
          onTap: _cheatSheet,
          child: const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              SizedBox(width: 4),
              Text(
                'Cheat Sheet',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toolChip(String label, VoidCallback onTap, {bool accent = false}) {
    return Material(
      color: accent ? AppColors.selectedTint : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent ? AppColors.accent : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _toolChip(
                    '+[Chord]',
                    () => _insert('[]', back: 1),
                    accent: true,
                  ),
                  const SizedBox(width: 8),
                  _toolChip('[Chorus]', () => _insert('{c: Chorus}\n')),
                  const SizedBox(width: 8),
                  _toolChip('[Verse]', () => _insert('{c: Verse}\n')),
                  const SizedBox(width: 8),
                  PopupMenuButton<int>(
                    color: AppColors.surfaceHigh,
                    tooltip: 'Transpose chords',
                    onSelected: _transpose,
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 2, child: Text('Up 2 semitones')),
                      PopupMenuItem(value: 1, child: Text('Up 1 semitone')),
                      PopupMenuItem(value: -1, child: Text('Down 1 semitone')),
                      PopupMenuItem(value: -2, child: Text('Down 2 semitones')),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                      child: Row(
                        children: [
                          Text('Transpose', style: TextStyle(fontSize: 12)),
                          Icon(Icons.arrow_drop_down_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.muted.withAlpha(40)),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListenableBuilder(
                  listenable: _chordpro,
                  builder: (_, _) {
                    final n = '\n'.allMatches(_chordpro.text).length + 1;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (var i = 1; i <= n; i++)
                          Text(
                            i.toString().padLeft(2, '0'),
                            style: _mono.copyWith(
                              color: AppColors.muted.withAlpha(140),
                              fontSize: 10.5,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _chordpro,
                    minLines: 8,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    style: _mono,
                    decoration: const InputDecoration(
                      hintText:
                          'Paste a chart here, or type ChordPro:\n'
                          '{c: Verse 1}\n'
                          '[G]Holy [D]presence',
                      hintStyle: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.6,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.muted.withAlpha(40)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                InkWell(
                  onTap: _convert,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.auto_fix_high_rounded,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Convert pasted chart to ChordPro',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _autoFormat,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    minimumSize: const Size(0, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'Auto-format',
                    style: TextStyle(
                      fontSize: 11,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.check_rounded),
          label: Text(
            _saving ? 'Saving...' : 'Save song',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
