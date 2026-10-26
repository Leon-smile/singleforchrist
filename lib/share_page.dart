import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';

const _accessOptions = <String, String>{
  'Anyone with the link': 'Can view · No sign-in needed',
  'Restricted': 'Only you can open this',
};

/// Share the After hours playlist with a link.
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
          'Send your collection to a friend. Find your next words to sing '
          'together.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const Text(
          'General access',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _AccessPicker(state: state),
        const SizedBox(height: 8),
        Text(
          _accessNote(state),
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
        const SizedBox(height: 18),
        const Text(
          'Playlist link',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const _LinkField(),
        const SizedBox(height: 12),
        PrimaryButton(
          expand: true,
          icon: Icons.copy_rounded,
          label: 'Copy link',
          onTap: () => _copy(context),
        ),
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
                      'Included in your link',
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
            'Send After hours to a friend. Find your next words to sing '
            'together.',
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
                        'One link to all ${countWord(n).toLowerCase()} lyrics. '
                        'No need to send them one at a time.',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'General access',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AccessPicker(state: state),
                      const SizedBox(height: 8),
                      Text(
                        _accessNote(state),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Playlist link',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const _LinkField(),
                      const SizedBox(height: 12),
                      PrimaryButton(
                        expand: true,
                        icon: Icons.copy_rounded,
                        label: 'Copy link',
                        onTap: () => _copy(context),
                      ),
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
                      'WHAT YOUR FRIENDS WILL SEE',
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
                    if (first != null) ...[
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
                              '"${first.lines[0]}\n${first.lines[1]}"',
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${first.singer.toUpperCase()} · '
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

  // --------------------------------------------------------------- helpers

  String _accessNote(AppState state) => state.shareAccess == 'Restricted'
      ? 'Only you can open this playlist. Switch access to share it.'
      : 'Friends can read every lyric in this playlist. Only you can add '
            'or remove lyrics.';

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(
      const ClipboardData(text: 'https://${AppState.shareLink}'),
    );
    if (context.mounted) showToast(context, 'Link copied');
  }
}

class _AccessPicker extends StatelessWidget {
  final AppState state;
  const _AccessPicker({required this.state});

  @override
  Widget build(BuildContext context) {
    final open = state.shareAccess == 'Anyone with the link';
    return PopupMenuButton<String>(
      color: AppColors.surfaceHigh,
      onSelected: state.setShareAccess,
      itemBuilder: (_) => [
        for (final o in _accessOptions.keys)
          PopupMenuItem(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Icon(
              open ? Icons.public_rounded : Icons.lock_outline_rounded,
              size: 20,
              color: AppColors.accent,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.shareAccess,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _accessOptions[state.shareAccess]!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more_rounded, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

class _LinkField extends StatelessWidget {
  const _LinkField();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF080A09),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outline),
      ),
      child: const Row(
        children: [
          Icon(Icons.link_rounded, size: 18, color: AppColors.muted),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              AppState.shareLink,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
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
            'Your library stays private. This link shares only After hours.',
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
            '${song.lines.length} lines',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
