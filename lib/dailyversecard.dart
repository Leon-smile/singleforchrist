import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/service/verseservice.dart';
import 'package:share_plus/share_plus.dart';

const _months = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Reads a verse out loud with the phone's text-to-speech engine, picking the
/// best English voice it can find (network / neural / enhanced voices first).
class _VerseSpeaker {
  final FlutterTts _tts = FlutterTts();
  Future<void>? _setup;

  void Function(bool speaking)? onChanged;
  void Function()? onError;

  Future<void> _init() => _setup ??= _configure();

  Future<void> _configure() async {
    _tts.setStartHandler(() => onChanged?.call(true));
    _tts.setCompletionHandler(() => onChanged?.call(false));
    _tts.setCancelHandler(() => onChanged?.call(false));
    _tts.setErrorHandler((_) {
      onChanged?.call(false);
      onError?.call();
    });

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.42); // calm, clear reading pace
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _pickBestVoice();
    } catch (_) {
      // Fall back to the engine's default voice.
    }
  }

  Future<void> _pickBestVoice() async {
    final voices = await _tts.getVoices;
    if (voices is! List) return;

    Map? best;
    var bestScore = -1;
    for (final v in voices) {
      if (v is! Map) continue;
      final name = '${v['name']}'.toLowerCase();
      final locale = '${v['locale']}'.toLowerCase().replaceAll('_', '-');
      if (!locale.startsWith('en')) continue;

      var score = 0;
      if (locale == 'en-us') {
        score += 3;
      } else if (locale == 'en-gb' || locale == 'en-au') {
        score += 2;
      } else {
        score += 1;
      }
      // Higher quality voices usually say so in their name.
      if (name.contains('network')) score += 10; // Android online voices
      if (name.contains('neural') || name.contains('natural')) score += 9;
      if (name.contains('premium') || name.contains('enhanced')) score += 8;
      if (name.contains('compact') || name.contains('espeak')) score -= 5;

      if (score > bestScore) {
        bestScore = score;
        best = v;
      }
    }

    if (best != null) {
      await _tts.setVoice({
        'name': '${best['name']}',
        'locale': '${best['locale']}',
      });
    }
  }

  Future<void> speak(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    if (_setup == null) return;
    await _tts.stop();
    onChanged?.call(false);
  }

  Future<void> dispose() async {
    onChanged = null;
    onError = null;
    if (_setup != null) await _tts.stop();
  }
}

/// "Colossians 3:23" -> "Colossians chapter 3, verse 23" so it is read well.
String _spokenReference(String ref) {
  final m = RegExp(
    r'^(.*?)\s+(\d+):(\d+)(?:\s*[-–]\s*(\d+))?$',
  ).firstMatch(ref);
  if (m == null) return ref;
  final book = m.group(1)!;
  final chapter = m.group(2)!;
  final from = m.group(3)!;
  final to = m.group(4);
  return to == null
      ? '$book chapter $chapter, verse $from'
      : '$book chapter $chapter, verses $from to $to';
}

String _spokenVerse(Verse v) {
  final body = v.text
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim()
      .replaceAll(RegExp(r'[;,:\s]+$'), '');
  return '$body. ${_spokenReference(v.reference)}.';
}

/// "Verse for today" card on the home page.
///
/// Shows one Bible verse per day. It switches to the next verse at local
/// midnight while the app is open, and checks again when the app comes back
/// to the foreground.
class DailyVerseCard extends StatefulWidget {
  const DailyVerseCard({super.key});

  @override
  State<DailyVerseCard> createState() => _DailyVerseCardState();
}

class _DailyVerseCardState extends State<DailyVerseCard>
    with WidgetsBindingObserver {
  final _service = VerseService();
  final _speaker = _VerseSpeaker();

  late DateTime _day;
  late Future<Verse> _future;
  Timer? _midnight;
  bool _saved = false;
  bool _speaking = false;

  @override
  void initState() {
    super.initState();
    _speaker.onChanged = (speaking) {
      if (mounted) setState(() => _speaking = speaking);
    };
    _speaker.onError = () {
      if (mounted) {
        showToast(
          context,
          'Could not read aloud. Check text-to-speech settings.',
        );
      }
    };
    WidgetsBinding.instance.addObserver(this);
    _load();
    _scheduleMidnight();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    _speaker.dispose();
    super.dispose();
  }

  void _load() {
    _speaker.stop(); // a new day means a new verse
    _day = DateTime.now();
    _saved = false;
    _future = _service.verseFor(_day);
  }

  /// Fires just after the next local midnight, then loads the new verse.
  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(_load);
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The phone may have slept past midnight.
    if (state == AppLifecycleState.resumed &&
        mounted &&
        !_sameDay(_day, DateTime.now())) {
      setState(_load);
      _scheduleMidnight();
    }
  }

  // ---------------------------------------------------------------- actions

  Future<void> _toggleListen(Verse v) async {
    if (_speaking) {
      await _speaker.stop();
    } else {
      await _speaker.speak(_spokenVerse(v));
    }
  }

  Future<void> _share(Verse v) async {
    final text =
        '"${v.text}"\n- ${v.reference} (${v.translation})\n\nShared from SFC Lyrics';
    try {
      final result = await SharePlus.instance.share(ShareParams(text: text));
      if (result.status == ShareResultStatus.unavailable) {
        throw StateError('share sheet unavailable');
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) showToast(context, 'Verse copied');
    }
  }

  void _reflect(Verse v) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'REFLECT ON ${v.reference.toUpperCase()}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 14),
            const _Prompt('What does this verse say about who God is?'),
            const _Prompt('Is there something here to thank Him for today?'),
            const _Prompt('What is one thing you can do because of it?'),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(70)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16261A), AppColors.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'VERSE FOR TODAY',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Text(
                '${_months[_day.month - 1]} ${_day.day}',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<Verse>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const _Loading();
              }
              final v = snap.data;
              if (v == null) return const _Loading();
              return _VerseBody(
                verse: v,
                saved: _saved,
                speaking: _speaking,
                onListen: () => _toggleListen(v),
                onReflect: () => _reflect(v),
                onSave: () {
                  setState(() => _saved = !_saved);
                  showToast(
                    context,
                    _saved ? 'Verse saved' : 'Removed from saved',
                  );
                },
                onShare: () => _share(v),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _VerseBody extends StatelessWidget {
  final Verse verse;
  final bool saved;
  final bool speaking;
  final VoidCallback onListen;
  final VoidCallback onReflect;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const _VerseBody({
    required this.verse,
    required this.saved,
    required this.speaking,
    required this.onListen,
    required this.onReflect,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"${verse.text}"',
          style: const TextStyle(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              verse.reference,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              verse.translation,
              style: const TextStyle(color: AppColors.muted, fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _TextAction(
              icon: speaking ? Icons.stop_rounded : Icons.play_arrow_rounded,
              label: speaking ? 'Stop' : 'Listen',
              onTap: onListen,
            ),
            const SizedBox(width: 6),
            _TextAction(
              icon: Icons.notes_rounded,
              label: 'Reflect',
              onTap: onReflect,
            ),
            const Spacer(),
            IconButton(
              tooltip: saved ? 'Remove from saved' : 'Save verse',
              onPressed: onSave,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                size: 20,
                color: saved ? AppColors.accent : AppColors.muted,
              ),
            ),
            IconButton(
              tooltip: 'Share verse',
              onPressed: onShare,
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.share_outlined,
                size: 19,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TextAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  final String text;
  const _Prompt(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 10),
            child: Icon(Icons.circle, size: 6, color: AppColors.accent),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
