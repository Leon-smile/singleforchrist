import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/artwork.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';

import '../theme.dart';

/// Lyrics reader for one song.
class LyricsPage extends StatelessWidget {
  final bool desktop;
  const LyricsPage({super.key, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final song = state.currentSong;
    return desktop
        ? _desktop(context, state, song)
        : _mobile(context, state, song);
  }

  // ---------------------------------------------------------------- mobile

  Widget _mobile(BuildContext context, AppState state, Song song) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const MobileTopBar(title: 'Lyrics'),
        const SizedBox(height: 16),
        _SongHero(song: song, height: 180, titleSize: 36),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(child: _AddButton(song: song)),
            const SizedBox(width: 8),
            OutlineAction(
              icon: Icons.download_outlined,
              tooltip: 'Download lyrics',
              onTap: () => runAction(context, () => state.downloadSong(song)),
            ),
            const Spacer(),
            const _FontControls(),
          ],
        ),
        const SizedBox(height: 24),
        _LyricsBody(song: song, fontSize: state.lyricsFontSize),
        const SizedBox(height: 28),
        _NextUp(song: state.nextSongAfter(song)),
      ],
    );
  }

  // --------------------------------------------------------------- desktop

  Widget _desktop(BuildContext context, AppState state, Song song) {
    final from = switch (state.navSection) {
      AppRoute.home => 'Home',
      AppRoute.search => 'Search',
      _ => 'Your library',
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Breadcrumb(crumbs: [Crumb(from, state.back), Crumb(song.title)]),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.singer.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song.title,
                      style: GoogleFonts.inter(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.5,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _LyricsBody(song: song, fontSize: state.lyricsFontSize + 4),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: Artwork(colors: song.colors, radius: 10),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${song.minutes} min read · ${song.lines.length} lines',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AddButton(song: song, expand: true),
                    const SizedBox(height: 10),
                    OutlineAction(
                      icon: Icons.download_outlined,
                      label: 'Download lyrics',
                      onTap: () =>
                          runAction(context, () => state.downloadSong(song)),
                    ),
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Text(
                          'Text size',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                        Spacer(),
                        _FontControls(),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _NextUp(song: state.nextSongAfter(song)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SongHero extends StatelessWidget {
  final Song song;
  final double height;
  final double titleSize;

  const _SongHero({
    required this.song,
    required this.height,
    required this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Artwork(colors: song.colors, radius: 14),
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
                  Text(
                    song.singer.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
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
                  const SizedBox(height: 6),
                  Text(
                    '${song.minutes} min read · ${song.lines.length} lines',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricsBody extends StatelessWidget {
  final Song song;
  final double fontSize;
  const _LyricsBody({required this.song, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in song.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              line,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
      ],
    );
  }
}

class _AddButton extends StatelessWidget {
  final Song song;
  final bool expand;
  const _AddButton({required this.song, this.expand = false});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final added = state.isInPlaylist(song);
    return PrimaryButton(
      expand: expand,
      icon: added ? Icons.check_rounded : Icons.add_rounded,
      label: added
          ? 'In ${AppState.playlistName}'
          : 'Add to ${AppState.playlistName}',
      onTap: added
          ? null
          : () {
              state.addToPlaylist(song);
              showToast(context, 'Added to ${AppState.playlistName}');
            },
    );
  }
}

class _FontControls extends StatelessWidget {
  const _FontControls();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RoundIcon(
          icon: Icons.text_decrease_rounded,
          onTap: () => state.changeFontSize(-2),
        ),
        const SizedBox(width: 8),
        RoundIcon(
          icon: Icons.text_increase_rounded,
          onTap: () => state.changeFontSize(2),
        ),
      ],
    );
  }
}

class _NextUp extends StatelessWidget {
  final Song song;
  const _NextUp({required this.song});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => state.openSong(song),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Artwork(colors: song.colors, radius: 4, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NEXT UP',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      song.singer,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
