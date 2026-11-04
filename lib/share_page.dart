import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';

import '../theme.dart';

/// Share the After hours playlist with other people.
///
/// No server is involved: the lyrics are sent through the phone's own share
/// sheet (as text or as a .txt file), copied, or downloaded.
class SharePage extends StatelessWidget {
  final bool desktop;
  const SharePage({super.key, required this.desktop});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return desktop ? _desktop(context, state) : _mobile(context, state);
  }

  // ---------------------------------------------------------------- mobile

  Widget _mobile(BuildContext context, AppState state) {
    final n = state.playlist.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const MobileTopBar(title: 'Share playlist'),
        const SizedBox(height: 16),
        const PlaylistHero(height: 190, titleSize: 40),
        const SizedBox(height: 20),
        const Text(
          'Good words are worth sharing.',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Send your collection to a friend through any app on your phone: '
          'messages, email, social media or cloud drives.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const _ShareActions(),
        const SizedBox(height: 14),
        const _PrivacyNote(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Included when you share',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$n lyrics',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              for (final s in state.playlist)
                SongListRow(song: s, trailing: s.singer),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- desktop

  Widget _desktop(BuildContext context, AppState state) {
    final n = state.playlist.length;
    final first = state.playlist.isEmpty ? null : state.playlist.first;
    final quote = first?.previewLines.take(2).join('\n') ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Breadcrumb(
            crumbs: [
              Crumb('Your library', () => state.go(AppRoute.library)),
              Crumb(AppState.playlistName, () => state.go(AppRoute.library)),
              const Crumb('Share playlist'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Good words are worth sharing.',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Send After hours to a friend. Pick any app on your device to '
            'share the lyrics.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Share playlist',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All ${countWord(n).toLowerCase()} lyrics go in one '
                        'message. No need to send them one at a time.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const _ShareActions(),
                      const SizedBox(height: 14),
                      const _PrivacyNote(),
                      const SizedBox(height: 18),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => state.go(AppRoute.library),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            size: 14,
                            color: AppColors.muted,
                          ),
                          label: const Text(
                            'Back to After hours',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WHAT YOUR FRIENDS WILL GET',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const PlaylistHero(height: 150, titleSize: 38),
                    const SizedBox(height: 8),
                    for (final s in state.playlist) _FriendRow(song: s),
                    if (quote.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.selectedTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '"$quote"',
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${first!.singer.toUpperCase()} · '
                              '${first.title.toUpperCase()}',
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
                    ],
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

/// The share buttons: share sheet (text), share sheet (file), copy, download.
class _ShareActions extends StatelessWidget {
  const _ShareActions();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final songs = state.playlist;
    const heading = AppState.playlistName;

    void act(BuildContext ctx, Future<String> Function() action) {
      if (songs.isEmpty) {
        showToast(ctx, 'Add lyrics to the playlist first');
        return;
      }
      runAction(ctx, action);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Builder(
          builder: (ctx) => PrimaryButton(
            expand: true,
            icon: Icons.ios_share_rounded,
            label: 'Share lyrics',
            onTap: () => act(
              ctx,
              () => shareLyricsText(ctx, songs: songs, heading: heading),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            Builder(
              builder: (ctx) => OutlineAction(
                icon: Icons.attach_file_rounded,
                label: 'Share as file',
                onTap: () => act(
                  ctx,
                  () => shareLyricsFile(
                    ctx,
                    songs: songs,
                    fileName: heading,
                    heading: heading,
                  ),
                ),
              ),
            ),
            OutlineAction(
              icon: Icons.copy_rounded,
              label: 'Copy lyrics',
              onTap: () =>
                  act(context, () => copyLyrics(songs, heading: heading)),
            ),
            OutlineAction(
              icon: Icons.download_outlined,
              label: 'Download .txt',
              onTap: () => act(context, state.downloadPlaylist),
            ),
          ],
        ),
      ],
    );
  }
}

Future<String> shareLyricsText(
  BuildContext ctx, {
  required List<Song> songs,
  required String heading,
}) async {
  return '';
}

Future<String> copyLyrics(List<Song> songs, {required String heading}) async {
  final lyrics = songs
      .map((song) {
        final body = song.previewLines.join('\n');
        return '${song.title} - ${song.singer}\n\n$body';
      })
      .join('\n\n---\n\n');

  await Clipboard.setData(ClipboardData(text: '$heading\n\n$lyrics'));
  return 'Lyrics copied to clipboard';
}

Future<String> shareLyricsFile(
  BuildContext ctx, {
  required List<Song> songs,
  required String fileName,
  required String heading,
}) async {
  return '';
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.verified_user_outlined, size: 16, color: AppColors.accent),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Your library stays private. Only the lyrics in After hours are '
            'shared.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Song song;
  const _FriendRow({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.outline)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  song.singer,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '${song.lineCount} lines',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
