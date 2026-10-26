import 'package:flutter/material.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/artwork.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/songs.dart';

enum _Tab { forYou, saved, singers }

/// Pick more lyrics to add to the After hours playlist.
class AddLyricsPage extends StatefulWidget {
  final bool desktop;
  const AddLyricsPage({super.key, required this.desktop});

  @override
  State<AddLyricsPage> createState() => _AddLyricsPageState();
}

class _AddLyricsPageState extends State<AddLyricsPage> {
  _Tab _tab = _Tab.forYou;

  // Placeholder for "saved" lyrics until a real saved list exists.
  static const _savedIds = {'echoes', 'paper-planes', 'morning-light'};

  List<Song> _suggestions(AppState state) {
    final q = state.search.text.trim().toLowerCase();
    var list = state.candidates.where((s) {
      return q.isEmpty ||
          s.title.toLowerCase().contains(q) ||
          s.singer.toLowerCase().contains(q) ||
          s.lines.any((l) => l.toLowerCase().contains(q));
    }).toList();
    if (_tab == _Tab.saved) {
      list = list.where((s) => _savedIds.contains(s.id)).toList();
    } else if (_tab == _Tab.singers) {
      list.sort((a, b) => a.singer.compareTo(b.singer));
    }
    return list;
  }

  void _add(AppState state) {
    final n = state.addSelected();
    showToast(
      context,
      'Added $n ${n == 1 ? 'lyric' : 'lyrics'} to ${AppState.playlistName}',
    );
    state.go(AppRoute.library);
  }

  Widget _tabs() {
    const labels = {
      _Tab.forYou: 'For you',
      _Tab.saved: 'Saved lyrics',
      _Tab.singers: 'Singers',
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final t in _Tab.values)
          PillChip(
            label: labels[t]!,
            selected: _tab == t,
            onTap: () => setState(() => _tab = t),
          ),
      ],
    );
  }

  Widget _cards(AppState state, List<Song> songs) {
    if (songs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No more lyrics to suggest',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return Column(
      children: [
        for (final s in songs)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableCard(
              song: s,
              selected: state.selected.contains(s.id),
              desktop: widget.desktop,
              onTap: () => state.toggleSelected(s.id),
            ),
          ),
      ],
    );
  }

  Widget _alreadyIn(AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Already in ${AppState.playlistName}',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        for (final s in state.playlist)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.outline)),
            ),
            child: Row(
              children: [
                if (widget.desktop) ...[
                  const Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        s.singer,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Added',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.muted,
                ),
              ],
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
    final songs = _suggestions(state);
    final count = state.selected.length;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            children: [
              const MobileTopBar(title: 'Add lyrics'),
              const SizedBox(height: 20),
              const Text(
                'FOR AFTER HOURS',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Find the words you want to sing next.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SearchField(controller: state.search, radius: 6),
              const SizedBox(height: 14),
              _tabs(),
              const SizedBox(height: 22),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'A few more for the night',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '$count selected',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _cards(state, songs),
              const SizedBox(height: 16),
              _alreadyIn(state),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${state.playlist.length} in playlist · $count ready to add',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                expand: true,
                icon: count == 0 ? null : Icons.add_rounded,
                label: count == 0
                    ? 'Select lyrics to add'
                    : 'Add $count ${count == 1 ? 'lyric' : 'lyrics'} to '
                          '${AppState.playlistName}',
                onTap: count == 0 ? null : () => _add(state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------- desktop

  Widget _desktop(AppState state) {
    final songs = _suggestions(state);
    final count = state.selected.length;
    final picked = state.candidates
        .where((s) => state.selected.contains(s.id))
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Breadcrumb(
            crumbs: [
              Crumb('Your library', () => state.go(AppRoute.library)),
              Crumb(AppState.playlistName, () => state.go(AppRoute.library)),
              const Crumb('Add lyrics'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Find your next words to sing.',
            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add lyrics to After hours. Choose a few favorites and make the '
            'night your own.',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 22),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SearchField(controller: state.search, radius: 8),
                    const SizedBox(height: 14),
                    _tabs(),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'A few more for the night',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '$count selected',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _cards(state, songs),
                    const SizedBox(height: 16),
                    _alreadyIn(state),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              SizedBox(
                width: 300,
                child: _SelectionPanel(
                  picked: picked,
                  onAdd: count == 0 ? null : () => _add(state),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final Song song;
  final bool selected;
  final bool desktop;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.song,
    required this.selected,
    required this.desktop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final preview = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in song.lines.take(2))
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              line,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
          ),
      ],
    );

    return Material(
      color: selected ? AppColors.selectedTint : AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (desktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            song.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            song.singer,
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    else ...[
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
                    const SizedBox(height: 8),
                    preview,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _CheckBox(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  final bool selected;
  const _CheckBox({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected ? AppColors.accent : AppColors.muted,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
          : null,
    );
  }
}

/// Desktop-only side panel summarising what will be added.
class _SelectionPanel extends StatelessWidget {
  final List<Song> picked;
  final VoidCallback? onAdd;

  const _SelectionPanel({required this.picked, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final n = picked.length;
    return Container(
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
              const Artwork(colors: playlistColors, radius: 4, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADDING TO',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      AppState.playlistName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${state.playlist.length} in playlist',
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
          const SizedBox(height: 18),
          Text(
            'Your selection · $n',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          if (n == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Tap a lyric to select it.',
                style: TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ),
          for (final s in picked)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          s.singer,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => state.toggleSelected(s.id),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          PrimaryButton(
            expand: true,
            icon: n == 0 ? null : Icons.add_rounded,
            label: n == 0
                ? 'Select lyrics to add'
                : 'Add $n ${n == 1 ? 'lyric' : 'lyrics'}',
            onTap: onAdd,
          ),
          const SizedBox(height: 10),
          Text(
            'These lyrics will be added after your '
            '${countWord(state.playlist.length).toLowerCase()} current '
            'favorites.',
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
