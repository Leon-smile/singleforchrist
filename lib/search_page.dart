import 'package:flutter/material.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/artwork.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/songs.dart';

enum _SearchFilter { all, lyrics, singers, playlists, verses }

extension on _SearchFilter {
  String get label => switch (this) {
    _SearchFilter.all => 'All',
    _SearchFilter.lyrics => 'Lyrics',
    _SearchFilter.singers => 'Singers',
    _SearchFilter.playlists => 'Playlists',
    _SearchFilter.verses => 'Verses',
  };
}

/// A "Browse genres & moods" card. [songIds] are the songs it opens.
class _Mood {
  final String tag;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color; // accent for tag + border
  final Color tint; // card background
  final List<String> songIds;

  const _Mood({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.tint,
    required this.songIds,
  });
}

const _moods = <_Mood>[
  _Mood(
    tag: 'ATMOSPHERIC',
    title: 'Late night',
    subtitle: 'Quiet words & calm',
    icon: Icons.circle,
    color: Color(0xFF7BE05A),
    tint: Color(0xFF15231A),
    songIds: ['slow-pulse', 'quiet-hours', 'echoes'],
  ),
  _Mood(
    tag: 'ACOUSTIC',
    title: 'Deep story',
    subtitle: 'Raw folk poetry',
    icon: Icons.music_note_rounded,
    color: Color(0xFFF2A93B),
    tint: Color(0xFF241E14),
    songIds: ['summer-nights', 'wildflower', 'north-wind'],
  ),
  _Mood(
    tag: 'DEVOTIONAL',
    title: 'Daily verses',
    subtitle: 'Psalms & reflection',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF4FD1C5),
    tint: Color(0xFF122222),
    songIds: ['morning-light', 'quiet-hours', 'wildflower'],
  ),
  _Mood(
    tag: 'SLOW PULSE',
    title: 'Ambient beat',
    subtitle: 'Lo-fi rhythm & rhyme',
    icon: Icons.bolt_rounded,
    color: Color(0xFF6C8CFF),
    tint: Color(0xFF151A2A),
    songIds: ['slow-pulse', 'paper-planes', 'echoes'],
  ),
];

/// The Search tab: recent searches, moods, trending lyrics and live results.
class SearchPage extends StatefulWidget {
  final bool desktop;
  const SearchPage({super.key, required this.desktop});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  _SearchFilter _filter = _SearchFilter.all;
  _Mood? _mood;
  bool _exploreAll = false;

  // ---------------------------------------------------------------- actions

  void _openSong(AppState state, Song song) {
    state.addRecent(
      RecentSearch(
        kind: 'song',
        refId: song.id,
        title: song.title,
        subtitle: 'Song · ${song.singer}',
      ),
    );
    state.openSong(song);
  }

  void _openSinger(AppState state, Singer singer) {
    state.addRecent(
      RecentSearch(
        kind: 'singer',
        refId: singer.name,
        title: singer.name,
        subtitle: 'Singer',
      ),
    );
    if (!state.openSinger(singer)) {
      showToast(context, "${singer.name}'s lyrics are coming soon");
    }
  }

  void _openPlaylist(AppState state) {
    state.addRecent(
      const RecentSearch(
        kind: 'playlist',
        refId: AppState.playlistName,
        title: AppState.playlistName,
        subtitle: 'Your playlist',
      ),
    );
    state.go(AppRoute.library);
  }

  void _openRecent(AppState state, RecentSearch r) {
    switch (r.kind) {
      case 'song':
        state.openSong(songById(r.refId));
      case 'singer':
        final matches = allSingers.where((s) => s.name == r.refId);
        if (matches.isEmpty || !state.openSinger(matches.first)) {
          showToast(context, 'Not available yet');
        }
      case 'playlist':
        state.go(AppRoute.library);
      default:
        state.search.text = r.refId;
        state.search.selection = TextSelection.collapsed(
          offset: r.refId.length,
        );
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final q = state.search.text.trim().toLowerCase();

    final children = <Widget>[
      _header(state),
      const SizedBox(height: 16),
      SearchField(
        controller: state.search,
        radius: 12,
        hint: 'Search lyrics, singers, or lines',
        onSubmitted: state.addRecentQuery,
        suffix: IconButton(
          tooltip: 'Voice search',
          onPressed: () => showToast(context, 'Voice search is coming soon'),
          icon: const Icon(
            Icons.mic_none_rounded,
            size: 20,
            color: AppColors.muted,
          ),
        ),
      ),
      const SizedBox(height: 14),
      _filterChips(),
      const SizedBox(height: 22),
      if (_mood != null)
        ..._moodResults(state, _mood!)
      else if (q.isNotEmpty)
        ..._results(state, q)
      else ...[
        ..._recentSection(state),
        ..._moodSection(),
        ..._trendingSection(state),
      ],
    ];

    final list = ListView(
      padding: EdgeInsets.fromLTRB(20, widget.desktop ? 4 : 12, 20, 28),
      children: children,
    );

    if (!widget.desktop) return list;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: list,
      ),
    );
  }

  Widget _header(AppState state) {
    if (widget.desktop) {
      return const Text(
        'Search',
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
      );
    }
    return const Row(
      children: [
        Expanded(
          child: Text(
            'Search',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
        AvatarBadge(),
      ],
    );
  }

  Widget _filterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in _SearchFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: PillChip(
                label: f.label,
                selected: _filter == f,
                onTap: () => setState(() => _filter = f),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------- default sections

  List<Widget> _recentSection(AppState state) {
    if (state.recents.isEmpty) return const [];
    return [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Recent searches',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: state.clearRecents,
            child: const Text(
              'Clear all',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      for (final r in state.recents)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RecentRow(
            item: r,
            subtitle: r.kind == 'playlist'
                ? 'Your playlist · ${state.playlist.length} lyrics'
                : r.subtitle,
            onTap: () => _openRecent(state, r),
            onRemove: () => state.removeRecent(r),
          ),
        ),
      const SizedBox(height: 18),
    ];
  }

  List<Widget> _moodSection() {
    return [
      const Text(
        'Browse genres & moods',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _moods.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          mainAxisExtent: 96,
        ),
        itemBuilder: (_, i) => _MoodCard(
          mood: _moods[i],
          onTap: () => setState(() => _mood = _moods[i]),
        ),
      ),
      const SizedBox(height: 22),
    ];
  }

  List<Widget> _trendingSection(AppState state) {
    final songs = _exploreAll ? allSongs : allSongs.skip(4).take(2).toList();
    return [
      Row(
        children: [
          const Expanded(
            child: Text(
              'Trending lyrics to sing',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          InkWell(
            onTap: () => setState(() => _exploreAll = !_exploreAll),
            child: Text(
              _exploreAll ? 'Show less' : 'Explore all',
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
      for (final s in songs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TrendingCard(song: s, onTap: () => _openSong(state, s)),
        ),
    ];
  }

  // ---------------------------------------------------------------- results

  List<Widget> _moodResults(AppState state, _Mood mood) {
    final songs = [for (final id in mood.songIds) songById(id)];
    return [
      Row(
        children: [
          InkWell(
            onTap: () => setState(() => _mood = null),
            child: const Row(
              children: [
                Icon(Icons.arrow_back_rounded, size: 16),
                SizedBox(width: 6),
                Text('Back', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        mood.tag,
        style: TextStyle(
          color: mood.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        mood.title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 2),
      Text(
        mood.subtitle,
        style: const TextStyle(color: AppColors.muted, fontSize: 12),
      ),
      const SizedBox(height: 16),
      for (final s in songs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _TrendingCard(song: s, onTap: () => _openSong(state, s)),
        ),
    ];
  }

  List<Widget> _results(AppState state, String q) {
    bool lineMatch(Song s) => s.lines.any((l) => l.toLowerCase().contains(q));
    bool songMatch(Song s) =>
        s.title.toLowerCase().contains(q) ||
        s.singer.toLowerCase().contains(q) ||
        lineMatch(s);

    final f = _filter;
    final showLyrics = f == _SearchFilter.all || f == _SearchFilter.lyrics;
    final showSingers = f == _SearchFilter.all || f == _SearchFilter.singers;
    final showPlaylists =
        f == _SearchFilter.all || f == _SearchFilter.playlists;
    final showVerses = f == _SearchFilter.verses;

    final songs = showLyrics ? allSongs.where(songMatch).toList() : <Song>[];
    final singers = showSingers
        ? allSingers
              .where(
                (s) =>
                    s.name.toLowerCase().contains(q) ||
                    s.highlights.toLowerCase().contains(q),
              )
              .toList()
        : <Singer>[];
    final playlistHit =
        showPlaylists && AppState.playlistName.toLowerCase().contains(q);
    final verses = showVerses
        ? [
            for (final s in allSongs)
              for (final l in s.lines)
                if (l.toLowerCase().contains(q)) (s, l),
          ]
        : <(Song, String)>[];

    final empty =
        songs.isEmpty && singers.isEmpty && !playlistHit && verses.isEmpty;
    if (empty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No matches. Try another word or singer.',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ),
        ),
      ];
    }

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    );

    return [
      if (songs.isNotEmpty) ...[
        heading('Lyrics'),
        for (final s in songs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultRow(
              title: s.title,
              subtitle: 'Song · ${s.singer}',
              colors: s.colors,
              onTap: () => _openSong(state, s),
            ),
          ),
      ],
      if (singers.isNotEmpty) ...[
        heading('Singers'),
        for (final s in singers)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _ResultRow(
              title: s.name,
              subtitle: s.highlights,
              colors: s.colors,
              onTap: () => _openSinger(state, s),
            ),
          ),
      ],
      if (playlistHit) ...[
        heading('Playlists'),
        _ResultRow(
          title: AppState.playlistName,
          subtitle: 'Your playlist · ${state.playlist.length} lyrics',
          colors: playlistColors,
          onTap: () => _openPlaylist(state),
        ),
      ],
      if (verses.isNotEmpty) ...[
        heading('Verses'),
        for (final (song, line) in verses)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _VerseRow(
              song: song,
              line: line,
              onTap: () => _openSong(state, song),
            ),
          ),
      ],
    ];
  }
}

// ======================================================================
// Widgets
// ======================================================================

class _RecentRow extends StatelessWidget {
  final RecentSearch item;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentRow({
    required this.item,
    required this.subtitle,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: onRemove,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final _Mood mood;
  final VoidCallback onTap;
  const _MoodCard({required this.mood, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mood.tint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: mood.color.withAlpha(90)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mood.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mood.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Icon(
                    mood.icon,
                    size: mood.icon == Icons.circle ? 8 : 14,
                    color: mood.color,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                mood.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                mood.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  const _TrendingCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    song.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      song.singer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  Text(
                    '${song.minutes} min',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              for (final line in song.lines.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '"$line"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      height: 1.35,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ready to sing · ${song.lines.length} lines',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const Text(
                    'View',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _ResultRow({
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Artwork(colors: colors, radius: 6, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerseRow extends StatelessWidget {
  final Song song;
  final String line;
  final VoidCallback onTap;

  const _VerseRow({
    required this.song,
    required this.line,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '"$line"',
                style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${song.singer.toUpperCase()} · ${song.title.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
