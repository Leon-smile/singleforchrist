import 'package:flutter/material.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/logo.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/songs.dart';

import '../theme.dart';
import 'artwork.dart';

/// Width at which the layout switches from phone to desktop.
const kDesktopBreakpoint = 900.0;

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
}

/// Runs an async action that returns a message, then shows it as a toast.
Future<void> runAction(
  BuildContext context,
  Future<String> Function() action,
) async {
  final message = await action();
  if (context.mounted) showToast(context, message);
}

String countWord(int n) {
  const words = [
    'Zero',
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
    'Ten',
  ];
  return n >= 0 && n < words.length ? words[n] : '$n';
}

// ======================================================================
// Small building blocks
// ======================================================================

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.accent,
      child: Text(
        'A',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class PillChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.surfaceHigh,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.black : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const RoundIcon({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 20, color: AppColors.muted),
        ),
      ),
    );
  }
}

/// Filled lime button. Pass `onTap: null` to show the disabled look.
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool expand;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.expand = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.accent : AppColors.accentDisabled,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: Colors.black),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark pill with an outline (Share, Download...). Omit [label] for icon-only.
class OutlineAction extends StatelessWidget {
  final String? label;
  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  const OutlineAction({
    super.key,
    required this.icon,
    required this.onTap,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.surface,
      shape: const StadiumBorder(side: BorderSide(color: AppColors.outline)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: label == null ? 13 : 18,
            vertical: 13,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double radius;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffix;

  const SearchField({
    super.key,
    required this.controller,
    this.hint = 'Search lyrics, singers, or lines',
    this.radius = 30,
    this.onSubmitted,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: suffix,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.muted,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

class Crumb {
  final String label;
  final VoidCallback? onTap;
  const Crumb(this.label, [this.onTap]);
}

class Breadcrumb extends StatelessWidget {
  final List<Crumb> crumbs;
  const Breadcrumb({super.key, required this.crumbs});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < crumbs.length; i++) ...[
          InkWell(
            onTap: crumbs[i].onTap,
            child: Text(
              crumbs[i].label,
              style: TextStyle(
                fontSize: 11,
                color: i == crumbs.length - 1
                    ? AppColors.text
                    : AppColors.muted,
              ),
            ),
          ),
          if (i != crumbs.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: AppColors.muted,
              ),
            ),
        ],
      ],
    );
  }
}

/// Phone header for sub-pages: back arrow, title, avatar.
class MobileTopBar extends StatelessWidget {
  final String title;
  const MobileTopBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: state.back,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        const AvatarBadge(),
      ],
    );
  }
}

/// Big playlist card: artwork, label, title, tagline, meta line.
class PlaylistHero extends StatelessWidget {
  final double height;
  final double titleSize;

  const PlaylistHero({
    super.key,
    required this.height,
    required this.titleSize,
  });

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const Artwork(colors: playlistColors, radius: 14),
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
                  const Text(
                    'YOUR LYRICS PLAYLIST',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppState.playlistName,
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    AppState.playlistTagline,
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${AppState.userName} · ${state.playlist.length} lyrics · '
                    '${state.singerCount} singers',
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

// ======================================================================
// App chrome: bottom nav (phone), sidebar + top bar (desktop)
// ======================================================================

class BottomNav extends StatelessWidget {
  const BottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return NavigationBar(
      selectedIndex: switch (state.navSection) {
        AppRoute.home => 0,
        AppRoute.search => 1,
        _ => 2,
      },
      onDestinationSelected: (i) {
        state.go(switch (i) {
          0 => AppRoute.home,
          1 => AppRoute.search,
          _ => AppRoute.library,
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.search_rounded),
          label: 'Search',
        ),
        NavigationDestination(
          icon: Icon(Icons.library_music_outlined),
          selectedIcon: Icon(Icons.library_music_rounded),
          label: 'Your library',
        ),
      ],
    );
  }
}

class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final onHome = state.route == AppRoute.home;
    final onLyrics = state.route == AppRoute.lyrics;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: Row(
        children: [
          RoundIcon(icon: Icons.chevron_left_rounded, onTap: state.back),
          const SizedBox(width: 8),
          RoundIcon(icon: Icons.chevron_right_rounded, onTap: () {}),
          const SizedBox(width: 16),
          SizedBox(width: 420, child: SearchField(controller: state.search)),
          const Spacer(),
          TextButton(
            onPressed: () => showToast(context, 'Explore Premium'),
            child: const Text(
              'Explore Premium',
              style: TextStyle(fontSize: 12, color: AppColors.text),
            ),
          ),
          IconButton(
            tooltip: onLyrics
                ? 'Download these lyrics'
                : onHome
                ? 'Download all lyrics'
                : 'Download this playlist',
            onPressed: () => runAction(
              context,
              onLyrics
                  ? () => state.downloadSong(state.currentSong)
                  : onHome
                  ? state.downloadAll
                  : state.downloadPlaylist,
            ),
            icon: const Icon(Icons.download_outlined, size: 20),
          ),
          IconButton(
            onPressed: () => showToast(context, 'Notifications'),
            icon: const Icon(Icons.notifications_none_rounded, size: 20),
          ),
          const SizedBox(width: 4),
          const AvatarBadge(),
        ],
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final inLibrary = state.navSection == AppRoute.library;
    final playlistSelected =
        state.route == AppRoute.library ||
        state.route == AppRoute.addLyrics ||
        state.route == AppRoute.share;

    return Container(
      width: 300,
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 8, 8, 16),
            child: Align(alignment: Alignment.centerLeft, child: LogoLockup()),
          ),
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: state.navSection == AppRoute.home,
            onTap: () => state.go(AppRoute.home),
          ),
          _NavItem(
            icon: Icons.search_rounded,
            label: 'Search',
            selected: state.navSection == AppRoute.search,
            onTap: () => state.go(AppRoute.search),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => state.go(AppRoute.library),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            Icons.library_music_rounded,
                            size: 18,
                            color: inLibrary
                                ? AppColors.accent
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your library',
                            style: TextStyle(
                              color: inLibrary
                                  ? AppColors.accent
                                  : AppColors.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => showToast(context, 'New playlist'),
                  child: const Icon(
                    Icons.add,
                    size: 18,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                _MiniChip('Singers', selected: false),
                SizedBox(width: 8),
                _MiniChip('Lyrics', selected: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 16, color: AppColors.muted),
                Spacer(),
                Text(
                  'Recents',
                  style: TextStyle(color: AppColors.muted, fontSize: 11),
                ),
                SizedBox(width: 4),
                Icon(Icons.sort_rounded, size: 14, color: AppColors.muted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                LibraryRow(
                  title: 'Saved lyrics',
                  subtitle: 'Pinned · 24 lyrics',
                  colors: const [Color(0xFF5B47D6), Color(0xFF3A2D96)],
                  icon: Icons.favorite_rounded,
                  onTap: () => showToast(context, 'Saved lyrics'),
                ),
                LibraryRow(
                  title: AppState.playlistName,
                  subtitle: 'Playlist · ${state.playlist.length} lyrics',
                  colors: playlistColors,
                  selected: playlistSelected,
                  onTap: () => state.go(AppRoute.library),
                ),
                for (final song in state.playlist)
                  LibraryRow(
                    title: song.title,
                    subtitle: '${song.singer} · Lyrics',
                    colors: song.colors,
                    selected:
                        state.route == AppRoute.lyrics &&
                        state.currentSong.id == song.id,
                    onTap: () => state.openSong(song),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'A space for words',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Your singers. Their lyrics.',
                  style: TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceHigh : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? AppColors.text : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.text : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final bool selected;
  const _MiniChip(this.label, {required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.black : AppColors.text,
        ),
      ),
    );
  }
}

class LibraryRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Color> colors;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  const LibraryRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.colors,
    this.icon,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.surfaceHigh : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Artwork(
                colors: colors,
                radius: 4,
                size: 44,
                child: icon == null
                    ? null
                    : Center(child: Icon(icon, size: 20, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.accent : AppColors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
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

/// Doc icon + title/singer row used in "Included in your link" lists.
class SongListRow extends StatelessWidget {
  final Song song;
  final String trailing;
  final bool divider;

  const SongListRow({
    super.key,
    required this.song,
    required this.trailing,
    this.divider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: divider
            ? const Border(bottom: BorderSide(color: AppColors.outline))
            : null,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.description_rounded,
            size: 18,
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              song.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            trailing,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
