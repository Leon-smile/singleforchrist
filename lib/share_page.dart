import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/service/playlistservice.dart';
import 'package:mobileappsfc/song.dart';
import 'package:share_plus/share_plus.dart';

import '../theme.dart';

/// Share the After hours playlist with other people.
///
/// Two ways to share:
///  * a share CODE (saved in Supabase): the friend opens the playlist in the
///    app and can add it to their own playlist;
///  * the phone's share sheet / copy / download for the lyrics text.
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
          'Give a friend a code to open your playlist in the app, or send the '
          'lyrics through any app on your phone.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 20),
        const _ShareCodeCard(),
        const SizedBox(height: 14),
        const _OpenSharedCard(),
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
            'Give a friend a code to open After hours in the app, or send the '
            'lyrics through any app on your device.',
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
                      const _ShareCodeCard(),
                      const SizedBox(height: 14),
                      const _OpenSharedCard(),
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

// ======================================================================
// Share code (saved in Supabase)
// ======================================================================

class _ShareCodeCard extends StatefulWidget {
  const _ShareCodeCard();

  @override
  State<_ShareCodeCard> createState() => _ShareCodeCardState();
}

class _ShareCodeCardState extends State<_ShareCodeCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() job, String failMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) showToast(context, failMessage);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final code = state.shareToken;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                code == null ? Icons.lock_outline_rounded : Icons.link_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  code == null ? 'Share with a code' : 'Sharing is on',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            code == null
                ? 'Create a code. Anyone you give it to can open this '
                      'playlist in the app (read only).'
                : 'Anyone with this code can open the playlist. Stop sharing '
                      'at any time and the code stops working.',
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 14),
          if (code == null)
            PrimaryButton(
              expand: true,
              icon: _busy ? null : Icons.link_rounded,
              label: _busy ? 'Creating...' : 'Create share code',
              onTap: _busy
                  ? null
                  : () => _run(() async {
                      await state.startSharing();
                      if (mounted) showToast(context, 'Sharing is on');
                    }, "Couldn't create the code. Please try again."),
            )
          else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlineAction(
                  icon: Icons.copy_rounded,
                  label: 'Copy code',
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (context.mounted) showToast(context, 'Code copied');
                  },
                ),
                Builder(
                  builder: (ctx) => OutlineAction(
                    icon: Icons.ios_share_rounded,
                    label: 'Send code',
                    onTap: () => runAction(ctx, () async {
                      try {
                        await Share.share(
                          state.shareInvite(code),
                          sharePositionOrigin: _originOf(ctx),
                        );
                        return 'Code shared';
                      } catch (_) {
                        return "Couldn't share the code. Please try again.";
                      }
                    }),
                  ),
                ),
                OutlineAction(
                  icon: Icons.link_off_rounded,
                  label: _busy ? 'Working...' : 'Stop sharing',
                  onTap: () => _run(() async {
                    await state.stopSharing();
                    if (mounted) {
                      showToast(
                        context,
                        'Sharing stopped. The old code no longer works.',
                      );
                    }
                  }, "Couldn't stop sharing. Please try again."),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ======================================================================
// Open a playlist somebody shared
// ======================================================================

class _OpenSharedCard extends StatefulWidget {
  const _OpenSharedCard();

  @override
  State<_OpenSharedCard> createState() => _OpenSharedCardState();
}

class _OpenSharedCardState extends State<_OpenSharedCard> {
  final _code = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final code = _code.text.trim();
    if (_busy) return;
    if (code.isEmpty) {
      showToast(context, 'Enter the code your friend sent you');
      return;
    }
    final state = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final shared = await state.fetchShared(code);
      if (!mounted) return;
      if (shared == null) {
        showToast(context, 'No playlist found for that code');
        return;
      }
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        builder: (_) => _SharedSheet(state: state, shared: shared),
      );
    } catch (e) {
      debugPrint('Open shared error: $e');
      if (mounted) {
        showToast(
          context,
          "Couldn't open it. Check the code and your connection.",
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(
                Icons.download_done_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Open a shared playlist',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Got a code from a friend? Enter it here.',
            style: TextStyle(color: AppColors.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            enableSuggestions: false,
            onSubmitted: (_) => _open(),
            decoration: InputDecoration(
              hintText: 'Paste the code',
              hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            expand: true,
            icon: _busy ? null : Icons.lock_open_rounded,
            label: _busy ? 'Opening...' : 'Open playlist',
            onTap: _busy ? null : _open,
          ),
        ],
      ),
    );
  }
}

class _SharedSheet extends StatefulWidget {
  final AppState state;
  final SharedPlaylist shared;
  const _SharedSheet({required this.state, required this.shared});

  @override
  State<_SharedSheet> createState() => _SharedSheetState();
}

class _SharedSheetState extends State<_SharedSheet> {
  bool _busy = false;

  Future<void> _addAll() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final added = await widget.state.copySharedToPlaylist(widget.shared);
      if (!mounted) return;
      Navigator.pop(context);
      showToast(
        context,
        added == 0
            ? 'Those lyrics are already in ${AppState.playlistName}'
            : 'Added $added to ${AppState.playlistName}',
      );
    } catch (e) {
      debugPrint('Copy shared error: $e');
      if (mounted) {
        showToast(context, "Couldn't add them. Please try again.");
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = widget.shared.songs;
    final maxHeight = MediaQuery.of(context).size.height * 0.8;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SHARED WITH YOU',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.shared.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${songs.length} ${songs.length == 1 ? 'lyric' : 'lyrics'}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: songs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'This playlist is empty.',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        children: [
                          for (final s in songs)
                            ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.description_rounded,
                                size: 18,
                                color: AppColors.accent,
                              ),
                              title: Text(
                                s.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                s.singer,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                expand: true,
                icon: _busy ? null : Icons.add_rounded,
                label: _busy
                    ? 'Adding...'
                    : 'Add all to ${AppState.playlistName}',
                onTap: (_busy || songs.isEmpty) ? null : _addAll,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Share the lyrics text (share sheet / copy / download)
// ======================================================================

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

/// Where the share sheet should appear (needed on iPad / some web browsers).
Rect? _originOf(BuildContext ctx) {
  final box = ctx.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    return box.localToGlobal(Offset.zero) & box.size;
  }
  return null;
}

String _lyricsText(String heading, List<Song> songs) {
  final body = songs
      .map((song) {
        final lines = song.previewLines.join('\n');
        return '${song.title} - ${song.singer}\n\n$lines';
      })
      .join('\n\n---\n\n');
  return '$heading\n\n$body';
}

/// Opens the phone's share sheet with the lyrics as text.
/// (This used to be an empty stub that returned '' and shared nothing.)
Future<String> shareLyricsText(
  BuildContext ctx, {
  required List<Song> songs,
  required String heading,
}) async {
  try {
    await Share.share(
      _lyricsText(heading, songs),
      subject: heading,
      sharePositionOrigin: _originOf(ctx),
    );
    return 'Lyrics shared';
  } catch (_) {
    return "Couldn't share the lyrics. Please try again.";
  }
}

Future<String> copyLyrics(List<Song> songs, {required String heading}) async {
  await Clipboard.setData(ClipboardData(text: _lyricsText(heading, songs)));
  return 'Lyrics copied to clipboard';
}

/// Opens the share sheet with a .txt file attached.
Future<String> shareLyricsFile(
  BuildContext ctx, {
  required List<Song> songs,
  required String fileName,
  required String heading,
}) async {
  try {
    final safe = fileName.replaceAll(RegExp(r'[^\w\- ]'), '').trim();
    final name = '${safe.isEmpty ? 'lyrics' : safe}.txt';
    final bytes = Uint8List.fromList(utf8.encode(_lyricsText(heading, songs)));
    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'text/plain', name: name)],
      fileNameOverrides: [name],
      subject: heading,
      sharePositionOrigin: _originOf(ctx),
    );
    return 'Lyrics file shared';
  } catch (_) {
    return "Couldn't share the file. Please try again.";
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
            'Your library stays private. Only After hours can be opened, and '
            'only by people who have your code.',
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
