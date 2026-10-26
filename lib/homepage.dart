import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/artwork.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/songs.dart';

enum HomeFilter { all, singers, lyrics }

extension on HomeFilter {
  String get label => switch (this) {
    HomeFilter.all => 'All',
    HomeFilter.singers => 'Singers',
    HomeFilter.lyrics => 'Lyrics',
  };
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Home content only; the shell supplies the sidebar / top bar / bottom nav.
class HomePage extends StatefulWidget {
  final bool desktop;
  const HomePage({super.key, required this.desktop});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  HomeFilter _filter = HomeFilter.all;

  bool get _showLyrics => _filter != HomeFilter.singers;
  bool get _showSingers => _filter != HomeFilter.lyrics;

  List<Song> _songs(AppState state) {
    final q = state.search.text.trim().toLowerCase();
    return allSongs
        .where(
          (s) =>
              q.isEmpty ||
              s.title.toLowerCase().contains(q) ||
              s.singer.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Singer> _singers(AppState state) {
    final q = state.search.text.trim().toLowerCase();
    return allSingers
        .where((s) => q.isEmpty || s.name.toLowerCase().contains(q))
        .toList();
  }

  void _openSong(Song song) => AppScope.of(context).openSong(song);

  void _openSinger(Singer singer) {
    if (!AppScope.of(context).openSinger(singer)) {
      showToast(context, "${singer.name}'s lyrics are coming soon");
    }
  }

  Widget _chips() {
    return Row(
      children: [
        for (final f in HomeFilter.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PillChip(
              label: f.label,
              selected: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return widget.desktop ? _desktop(state) : _mobile(state);
  }

  // ---------------------------------------------------------------- mobile

  Widget _mobile(AppState state) {
    final songs = _songs(state);
    final singers = _singers(state);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        Row(
          children: [
            const AvatarBadge(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _greeting(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: () => showToast(context, 'Notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            IconButton(
              onPressed: () => showToast(context, 'History'),
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _chips(),
        const SizedBox(height: 24),
        if (_showLyrics && songs.isNotEmpty) ...[
          const Text(
            'Recently read',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: songs.length > 4 ? 4 : songs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              mainAxisExtent: 150,
            ),
            itemBuilder: (_, i) =>
                _SnippetCard(song: songs[i], onTap: () => _openSong(songs[i])),
          ),
          const SizedBox(height: 16),
          _FeaturedCard(
            label: 'FEATURED LYRICS',
            song: songs.first,
            height: 240,
            titleSize: 32,
            showButton: true,
            onTap: () => _openSong(songs.first),
          ),
        ],
        if (_showSingers && singers.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text(
            'Singers for ${AppState.userName}',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 225,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: singers.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => SizedBox(
                width: 140,
                child: _SingerCard(
                  singer: singers[i],
                  showTag: i.isEven,
                  onTap: () => _openSinger(singers[i]),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --------------------------------------------------------------- desktop

  Widget _desktop(AppState state) {
    final songs = _songs(state);
    final singers = _singers(state);
    final quick = songs.take(6).toList();
    final shownSingers = singers.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_greeting()}, ${AppState.userName}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _chips(),
          const SizedBox(height: 20),
          if (_showLyrics && songs.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quick.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                mainAxisExtent: 56,
              ),
              itemBuilder: (_, i) =>
                  _QuickTile(song: quick[i], onTap: () => _openSong(quick[i])),
            ),
            const SizedBox(height: 24),
            _FeaturedCard(
              label: 'LYRICS OF THE NIGHT',
              song: songs.first,
              height: 240,
              titleSize: 48,
              showButton: false,
              onTap: () => _openSong(songs.first),
            ),
          ],
          if (_showSingers && shownSingers.isNotEmpty) ...[
            const SizedBox(height: 32),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Singers for ${AppState.userName}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () => showToast(context, 'Show all singers'),
                  child: const Text(
                    'Show all',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Text(
              'A little familiar. A little unexpected. Entirely you.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < shownSingers.length; i++) ...[
                  Expanded(
                    child: _SingerCard(
                      singer: shownSingers[i],
                      showTag: i.isEven,
                      onTap: () => _openSinger(shownSingers[i]),
                    ),
                  ),
                  if (i != shownSingers.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
            const SizedBox(height: 24),
            _DiscoverBanner(
              singer: allSingers[2],
              onTap: () => showToast(context, 'Find your next favorite'),
            ),
          ],
        ],
      ),
    );
  }
}

// ======================================================================
// Home widgets
// ======================================================================

/// Small lyric-snippet card for the "Recently read" grid.
class _SnippetCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  const _SnippetCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      song.singer.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
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
              Expanded(
                child: Text(
                  '"${song.lines.join('\n')}"',
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Big artwork card with lyrics overlay ("Featured" / "Lyrics of the night").
class _FeaturedCard extends StatelessWidget {
  final String label;
  final Song song;
  final double height;
  final double titleSize;
  final bool showButton;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.label,
    required this.song,
    required this.height,
    required this.titleSize,
    required this.showButton,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Artwork(colors: song.colors, radius: 16),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.scrim],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.title,
                      style: GoogleFonts.inter(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      song.lines.join('\n'),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                    if (showButton) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${song.singer.toUpperCase()} · ${song.lines.length} lines',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const CircleAvatar(
                            radius: 18,
                            backgroundColor: AppColors.accent,
                            child: Icon(
                              Icons.menu_book_rounded,
                              size: 18,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact tile: artwork thumbnail + "Singer · Title".
class _QuickTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  const _QuickTile({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Artwork(colors: song.colors, radius: 0, size: 56),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${song.singer} · ${song.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _SingerCard extends StatelessWidget {
  final Singer singer;
  final bool showTag;
  final VoidCallback onTap;

  const _SingerCard({
    required this.singer,
    required this.showTag,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Artwork(
              colors: singer.colors,
              radius: 6,
              child: showTag
                  ? Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          color: Colors.black,
                          child: Text(
                            singer.name.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            singer.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            singer.highlights,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscoverBanner extends StatelessWidget {
  final Singer singer;
  final VoidCallback onTap;
  const _DiscoverBanner({required this.singer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Artwork(colors: singer.colors, radius: 4, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'A LITTLE OUTSIDE YOUR USUAL',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      singer.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Fresh discoveries for your next slow Sunday.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Text(
                'Find your next favorite',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded, size: 16),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
