import 'package:flutter/material.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';

/// "Your library": the After hours playlist.
class LibraryPage extends StatelessWidget {
  final bool desktop;
  const LibraryPage({super.key, required this.desktop});

  List<Song> _visible(AppState state) {
    final q = state.search.text.trim().toLowerCase();
    if (q.isEmpty) return state.playlist;
    return state.playlist
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              s.singer.toLowerCase().contains(q) ||
              s.lines.any((l) => l.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return desktop ? _desktop(context, state) : _mobile(context, state);
  }

  // ---------------------------------------------------------------- mobile

  Widget _mobile(BuildContext context, AppState state) {
    final songs = _visible(state);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const MobileTopBar(title: 'Your playlist'),
        const SizedBox(height: 16),
        const PlaylistHero(height: 190, titleSize: 40),
        const SizedBox(height: 16),
        Row(
          children: [
            PrimaryButton(
              icon: Icons.add_rounded,
              label: 'Add lyrics',
              onTap: () => state.go(AppRoute.addLyrics),
            ),
            const SizedBox(width: 8),
            OutlineAction(
              icon: Icons.share_outlined,
              label: 'Share',
              onTap: () => state.go(AppRoute.share),
            ),
            const SizedBox(width: 8),
            OutlineAction(
              icon: Icons.download_outlined,
              tooltip: 'Download playlist',
              onTap: () => runAction(context, state.downloadPlaylist),
            ),
            const Spacer(),
            const Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: AppColors.muted,
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Row(
          children: [
            Expanded(
              child: Text(
                'Lyrics to sing',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              'Custom order',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (songs.isEmpty)
          const _EmptyNote()
        else
          for (final song in songs)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _PlaylistSongCard(song: song, desktop: false),
            ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Your collection, your order. Make every word yours.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- desktop

  Widget _desktop(BuildContext context, AppState state) {
    final songs = _visible(state);
    final n = state.playlist.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Breadcrumb(
            crumbs: [
              Crumb('Your library', () => state.go(AppRoute.library)),
              const Crumb(AppState.playlistName),
            ],
          ),
          const SizedBox(height: 14),
          const PlaylistHero(height: 230, titleSize: 56),
          const SizedBox(height: 16),
          Row(
            children: [
              PrimaryButton(
                icon: Icons.add_rounded,
                label: 'Add lyrics',
                onTap: () => state.go(AppRoute.addLyrics),
              ),
              const SizedBox(width: 12),
              OutlineAction(
                icon: Icons.share_outlined,
                label: 'Share playlist',
                onTap: () => state.go(AppRoute.share),
              ),
              const SizedBox(width: 12),
              OutlineAction(
                icon: Icons.download_outlined,
                label: 'Download',
                onTap: () => runAction(context, state.downloadPlaylist),
              ),
              const Spacer(),
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(width: 6),
              const Text(
                'Only you · Share to invite others',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lyrics to sing',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              const Text(
                'Custom order',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.sort_rounded, size: 16, color: AppColors.muted),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            n == 0
                ? 'Nothing here yet. Add your first lyrics.'
                : '${countWord(n)} ${n == 1 ? 'favorite' : 'favorites'}. '
                      'One place to find your words.',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          if (songs.isEmpty)
            const _EmptyNote()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: songs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 200,
              ),
              itemBuilder: (_, i) =>
                  _PlaylistSongCard(song: songs[i], desktop: true),
            ),
          const SizedBox(height: 16),
          Material(
            color: AppColors.selectedTint,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => state.go(AppRoute.addLyrics),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 22,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Make room for your next favorite line.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add lyrics from the singers you love, then share '
                            'the words with someone new.',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Find more lyrics →',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'No lyrics to show',
          style: TextStyle(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _PlaylistSongCard extends StatelessWidget {
  final Song song;
  final bool desktop;
  const _PlaylistSongCard({required this.song, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    final menu = PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      color: AppColors.surfaceHigh,
      tooltip: 'More',
      icon: const Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: AppColors.muted,
      ),
      onSelected: (value) {
        if (value == 'download') {
          runAction(context, () => state.downloadSong(song));
        } else {
          state.removeFromPlaylist(song);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'download', child: Text('Download lyrics')),
        PopupMenuItem(value: 'remove', child: Text('Remove from playlist')),
      ],
    );

    final lines = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in song.lines)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              line,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: desktop ? 13 : 12, height: 1.3),
            ),
          ),
      ],
    );

    final singer = Text(
      song.singer.toUpperCase(),
      style: const TextStyle(
        color: AppColors.accent,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    );

    final card = Container(
      padding: EdgeInsets.all(desktop ? 20 : 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: desktop
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          singer,
                          const SizedBox(height: 4),
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 32, height: 32, child: menu),
                  ],
                ),
                const SizedBox(height: 8),
                lines,
                const Spacer(),
                Row(
                  children: [
                    Text(
                      '${song.lines.length} lines',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => state.openSong(song),
                      child: const Text(
                        'Read lyrics ↗',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.singer,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 32, height: 32, child: menu),
                  ],
                ),
                const SizedBox(height: 8),
                lines,
              ],
            ),
    );

    // Tapping anywhere on the card opens the lyrics.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => state.openSong(song),
      child: card,
    );
  }
}
