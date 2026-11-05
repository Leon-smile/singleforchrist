import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobileappsfc/downloadservice.dart';
import 'package:mobileappsfc/service/authservice.dart';
import 'package:mobileappsfc/service/downloadservice.dart'
    hide saveLyrics, buildLyricsText;
import 'package:mobileappsfc/service/lyrics_service.dart';
import 'package:mobileappsfc/service/playlistservice.dart';
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

  /// Goes to the home page and loads this user's saved playlist.
  void signIn() {
    go(AppRoute.home);
    loadPlaylist();
  }

  /// Signs out of Supabase and returns to the Sign in page.
  void signOut() {
    AuthService.signOut();
    _playlistId = null;
    shareToken = null;
    playlist.clear();
    go(AppRoute.signIn);
  }

  // ------------------------------------------------- saved playlist (Supabase)

  /// Songs of the signed-in user's playlist (loaded by [loadPlaylist]).
  final List<Song> playlist = [];

  String? _playlistId;
  Future<String>? _ensuring;
  bool playlistLoading = false;

  /// Share code of the playlist, or null when it is not shared.
  String? shareToken;

  /// Last problem while saving to the server (null when everything is fine).
  String? syncError;

  Future<String> _ensurePlaylistId() {
    final known = _playlistId;
    if (known != null) return Future.value(known);
    return _ensuring ??= () async {
      try {
        final info = await PlaylistService.ensurePlaylist(playlistName);
        _playlistId = info.id;
        shareToken = info.shareToken;
        return info.id;
      } finally {
        _ensuring = null;
      }
    }();
  }

  /// Turns a saved row back into a [Song]. Built-in songs come from the
  /// sample list; online songs get their lyrics fetched again.
  Future<Song> _songFromSaved(SavedSong s) async {
    if (s.source == 'sample') {
      final match = allSongs.where((x) => x.id == s.songId).firstOrNull;
      if (match != null) return match;
    } else {
      try {
        final song = await _lyricsService.loadSong(
          id: s.songId.replaceFirst('lyrics-ovh-', ''),
          title: s.title,
          artist: s.singer,
        );
        if (song != null) return song;
      } catch (_) {
        // fall through to the placeholder below
      }
    }
    // Keep the song in the list even if its lyrics cannot load right now.
    return Song(
      id: s.songId,
      title: s.title,
      singer: s.singer,
      lines: const ['Lyrics could not be loaded right now. Try again later.'],
      colors: playlistColors,
      minutes: 1,
      source: s.source,
    );
  }

  Future<void> loadPlaylist() async {
    playlistLoading = true;
    syncError = null;
    notifyListeners();
    try {
      final id = await _ensurePlaylistId();
      final saved = await PlaylistService.songs(id);
      final songs = await Future.wait(saved.map(_songFromSaved));
      playlist
        ..clear()
        ..addAll(songs);
    } catch (e) {
      debugPrint('Could not load the playlist: $e');
      syncError = "Couldn't load your playlist. Check your connection.";
    }
    playlistLoading = false;
    notifyListeners();
  }

  void _sync(Future<void> Function() job, {VoidCallback? onFail}) {
    job().catchError((Object e) {
      debugPrint('Playlist sync failed: $e');
      onFail?.call();
    });
  }

  // ----------------------------------------------------------- sharing

  /// Turns sharing on (creates the code the first time) and returns it.
  Future<String> startSharing() async {
    final id = await _ensurePlaylistId();
    final token = await PlaylistService.share(id);
    shareToken = token;
    notifyListeners();
    return token;
  }

  /// Turns sharing off. The old code stops working.
  Future<void> stopSharing() async {
    final id = await _ensurePlaylistId();
    await PlaylistService.stopSharing(id);
    shareToken = null;
    notifyListeners();
  }

  /// Text to send to a friend together with the code.
  String shareInvite(String code) =>
      'Open my "$playlistName" playlist in LyricFlow: go to Share > '
      '"Open a shared playlist" and enter this code:\n\n$code';

  /// Looks up a playlist by share code (null = no such playlist).
  Future<SharedPlaylist?> fetchShared(String code) =>
      PlaylistService.getShared(code);

  /// Adds the songs of a shared playlist to my own playlist.
  Future<int> copySharedToPlaylist(SharedPlaylist shared) async {
    var added = 0;
    for (final saved in shared.songs) {
      final song = await _songFromSaved(saved);
      if (isInPlaylist(song)) continue;
      addToPlaylist(song);
      added++;
    }
    return added;
  }

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
    syncError = null;
    notifyListeners();

    final position = playlist.length;
    _sync(
      () async {
        final id = await _ensurePlaylistId();
        await PlaylistService.addSong(id, song, position);
      },
      onFail: () {
        // Not saved: take it out again so the list tells the truth.
        playlist.removeWhere((s) => s.id == song.id);
        syncError = "Couldn't save \"${song.title}\". Please try again.";
        notifyListeners();
      },
    );
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
    selected.clear();
    for (final song in toAdd) {
      addToPlaylist(song);
    }
    notifyListeners();
    return toAdd.length;
  }

  void removeFromPlaylist(Song song) {
    playlist.removeWhere((s) => s.id == song.id);
    notifyListeners();
    _sync(() async {
      final id = await _ensurePlaylistId();
      await PlaylistService.removeSong(id, song.id);
    });
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
