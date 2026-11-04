import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobileappsfc/downloadservice.dart';
import 'package:mobileappsfc/service/authservice.dart';
import 'package:mobileappsfc/service/downloadservice.dart'
    hide saveLyrics, buildLyricsText;
import 'package:mobileappsfc/service/lyrics_service.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/songs.dart';
import 'package:share_plus/share_plus.dart';

enum AppRoute {
  signIn,
  signUp,
  home,
  search,
  library,
  addLyrics,
  share,
  lyrics,
}

/// One entry in the "Recent searches" list.
/// [kind] is 'song', 'singer', 'playlist' or 'query'.
class RecentSearch {
  final String kind;
  final String refId; // song id, singer name, playlist name or query text
  final String title;
  final String subtitle;

  const RecentSearch({
    required this.kind,
    required this.refId,
    required this.title,
    required this.subtitle,
  });
}

/// Holds navigation + playlist state for the whole prototype.
class AppState extends ChangeNotifier {
  AppState() {
    search.addListener(notifyListeners);
    search.addListener(_onSearchChanged);
  }

  // ------------------------------------------------------- online lyrics

  // FIX: this used to be a local stub class (LrclibService) whose search()
  // always returned null, so the real service was never called.
  final LyricsOvhService _lyricsService = LyricsOvhService();
  Timer? _debounce;
  String _remoteQuery = '';

  /// Results from the online lyrics search (Search page only).
  List<Song> remoteResults = [];
  bool remoteLoading = false;
  String? remoteError;

  void _clearRemote() {
    _debounce?.cancel();
    _remoteQuery = '';
    if (remoteResults.isEmpty && !remoteLoading && remoteError == null) return;
    remoteResults = [];
    remoteLoading = false;
    remoteError = null;
    notifyListeners();
  }

  void _onSearchChanged() {
    final q = search.text.trim();
    if (_route != AppRoute.search || q.length < 2) {
      _clearRemote();
      return;
    }
    if (q == _remoteQuery) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () => _runRemote(q));
  }

  Future<void> _runRemote(String q) async {
    _remoteQuery = q;
    remoteLoading = true;
    remoteError = null;
    notifyListeners();
    try {
      final found = await _lyricsService.search(q);
      if (_remoteQuery != q) return; // a newer search replaced this one
      remoteResults = found;
    } on LyricsServiceException catch (e) {
      if (_remoteQuery != q) return;
      remoteResults = [];
      remoteError = e.message; // the real reason (busy, no connection, ...)
    } catch (_) {
      if (_remoteQuery != q) return;
      remoteResults = [];
      remoteError = "Couldn't reach the lyrics service.";
    }
    remoteLoading = false;
    notifyListeners();
  }

  /// Search again right now (used by the "Try again" link).
  void retryRemote() {
    final q = search.text.trim();
    if (q.length >= 2) _runRemote(q);
  }

  static const userName = 'Alex';
  static const playlistName = 'After hours';
  static const playlistTagline = 'Words for late nights. Ready to sing.';
  static const shareLink = 'sfclyrics.app/p/after-hours-a7k2';

  /// Shared by the top-bar search and the page-level search fields.
  final TextEditingController search = TextEditingController();

  /// Signed-out users start on the Sign in page. (main.dart calls signIn()
  /// right away when Supabase restored a saved session.)
  AppRoute _route = AppRoute.signIn;
  AppRoute get route => _route;

  void signIn() => go(AppRoute.home);

  /// Signs out of Supabase and returns to the Sign in page.
  void signOut() {
    AuthService.signOut();
    go(AppRoute.signIn);
  }

  final List<Song> playlist = [
    songById('slow-pulse'),
    songById('quiet-hours'),
    songById('summer-nights'),
    songById('wildflower'),
  ];

  /// Ids picked on the Add lyrics page, not yet added.
  final Set<String> selected = {};

  String shareAccess = 'Anyone with the link';

  // ------------------------------------------------------- lyrics reader

  Song? _currentSong;
  Song get currentSong => _currentSong ?? allSongs.first;

  /// Where the lyrics page was opened from (so Back returns there).
  AppRoute _lyricsFrom = AppRoute.home;

  double lyricsFontSize = 20;

  /// Which section of the app the user is "in": home, search or library.
  AppRoute get navSection {
    final r = _route == AppRoute.lyrics ? _lyricsFrom : _route;
    if (r == AppRoute.home) return AppRoute.home;
    if (r == AppRoute.search) return AppRoute.search;
    return AppRoute.library;
  }

  // ------------------------------------------------------- recent searches

  final List<RecentSearch> recents = [
    const RecentSearch(
      kind: 'song',
      refId: 'slow-pulse',
      title: 'Slow pulse',
      subtitle: 'Song · Kai Ren',
    ),
    const RecentSearch(
      kind: 'playlist',
      refId: playlistName,
      title: playlistName,
      subtitle: 'Your playlist',
    ),
    const RecentSearch(
      kind: 'singer',
      refId: 'Zara Sloan',
      title: 'Zara Sloan',
      subtitle: 'Singer · 2 lyrics saved',
    ),
  ];

  void addRecent(RecentSearch item) {
    recents.removeWhere((r) => r.kind == item.kind && r.refId == item.refId);
    recents.insert(0, item);
    if (recents.length > 5) recents.removeLast();
    notifyListeners();
  }

  void addRecentQuery(String text) {
    final q = text.trim();
    if (q.isEmpty) return;
    addRecent(
      RecentSearch(kind: 'query', refId: q, title: q, subtitle: 'Search'),
    );
  }

  void removeRecent(RecentSearch item) {
    recents.remove(item);
    notifyListeners();
  }

  void clearRecents() {
    recents.clear();
    notifyListeners();
  }

  void openSong(Song song) {
    if (_route == AppRoute.lyrics) {
      _currentSong = song; // e.g. "Next up" inside the reader
      notifyListeners();
      return;
    }
    _lyricsFrom = _route;
    _currentSong = song;
    _route = AppRoute.lyrics;
    selected.clear();
    search.clear();
    notifyListeners();
  }

  /// Opens the first available song by this singer.
  bool openSinger(Singer singer) {
    final songs = allSongs.where((s) => s.singer == singer.name).toList();
    if (songs.isEmpty) return false;
    openSong(songs.first);
    return true;
  }

  Song nextSongAfter(Song song) {
    final i = allSongs.indexWhere((s) => s.id == song.id);
    return allSongs[(i + 1) % allSongs.length];
  }

  void changeFontSize(double delta) {
    lyricsFontSize = (lyricsFontSize + delta).clamp(14.0, 36.0).toDouble();
    notifyListeners();
  }

  bool isInPlaylist(Song song) => playlist.any((s) => s.id == song.id);

  void addToPlaylist(Song song) {
    if (isInPlaylist(song)) return;
    playlist.add(song);
    notifyListeners();
  }

  // ------------------------------------------------------------ playlist

  int get singerCount => playlist.map((s) => s.singer).toSet().length;

  List<Song> get candidates =>
      allSongs.where((s) => !playlist.any((p) => p.id == s.id)).toList();

  AppRoute get parentRoute => switch (_route) {
    AppRoute.signIn => AppRoute.signIn,
    AppRoute.signUp => AppRoute.signIn,
    AppRoute.home => AppRoute.home,
    AppRoute.search => AppRoute.home,
    AppRoute.library => AppRoute.home,
    AppRoute.addLyrics => AppRoute.library,
    AppRoute.share => AppRoute.library,
    AppRoute.lyrics => _lyricsFrom,
  };

  void go(AppRoute route) {
    if (route == _route) return;
    _route = route;
    selected.clear();
    search.clear();
    notifyListeners();
  }

  void back() => go(parentRoute);

  void toggleSelected(String id) {
    if (!selected.remove(id)) selected.add(id);
    notifyListeners();
  }

  /// Adds the selected songs to the playlist and returns how many were added.
  int addSelected() {
    final toAdd = candidates.where((s) => selected.contains(s.id)).toList();
    playlist.addAll(toAdd);
    selected.clear();
    notifyListeners();
    return toAdd.length;
  }

  void removeFromPlaylist(Song song) {
    playlist.removeWhere((s) => s.id == song.id);
    notifyListeners();
  }

  void setShareAccess(String value) {
    shareAccess = value;
    notifyListeners();
  }

  // ------------------------------------------------------------ downloads

  Future<String> downloadPlaylist() => saveLyrics(
    fileName: playlistName,
    heading: playlistName,
    songs: playlist,
  );

  Future<String> downloadSong(Song song) =>
      saveLyrics(fileName: song.title, heading: song.title, songs: [song]);

  /// Time-synced (.lrc) download; only for songs that have synced lyrics.
  Future<String> downloadSongLrc(Song song) => saveLrc(song);

  Future<String> downloadAll() => saveLyrics(
    fileName: 'lyricflow-lyrics',
    heading: 'LyricFlow lyrics',
    songs: allSongs,
  );

  @override
  void dispose() {
    _debounce?.cancel();
    search.dispose();
    super.dispose();
  }

  Future<String> shareLyricsText(
    BuildContext ctx, {
    required List<Song> songs,
  }) async {
    final heading = songs.length == 1 ? songs.first.title : playlistName;
    final text = buildLyricsText(heading, songs);

    try {
      await Share.share(text, sharePositionOrigin: ctx.sharePositionOrigin);
      return 'Lyrics shared';
    } catch (_) {
      return "Couldn't share the lyrics. Please try again.";
    }
  }
}

extension on BuildContext {
  Rect? get sharePositionOrigin => null;
}

/// Makes [AppState] available to the whole widget tree.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
