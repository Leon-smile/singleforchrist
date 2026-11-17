import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobileappsfc/downloadservice.dart';
import 'package:mobileappsfc/service/authservice.dart';
import 'package:mobileappsfc/service/downloadservice.dart'
    hide saveLyrics, buildLyricsText;
import 'package:mobileappsfc/service/lyrics_service.dart';
import 'package:mobileappsfc/service/playlistservice.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/song_repository.dart';
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

  // ------------------------------------------- your songs (Supabase `songs`)

  /// Songs you added with chords (Supabase `songs` table).
  List<Song> dbSongs = [];
  bool dbLoading = false;
  String? dbError;

  /// Loads (or reloads) the songs from the `songs` table.
  Future<void> loadDbSongs() async {
    dbLoading = true;
    dbError = null;
    notifyListeners();
    try {
      final rows = await SongRepository.fetchAll();
      dbSongs = rows.map(Song.fromRow).toList();
    } catch (e) {
      debugPrint('Could not load songs: $e');
      dbError = "Couldn't load your songs.";
    }
    dbLoading = false;
    notifyListeners();
  }

  /// Singers built from [dbSongs]: one entry per singer, with their first
  /// few song titles as the highlights and the first song's artwork colors.
  List<Singer> get dbSingers {
    final bySinger = <String, List<Song>>{};
    for (final s in dbSongs) {
      final name = s.singer.trim();
      if (name.isEmpty) continue;
      (bySinger[name] ??= []).add(s);
    }
    return [
      for (final e in bySinger.entries)
        Singer(
          name: e.key,
          highlights: e.value.take(3).map((s) => s.title).join(', '),
          colors: e.value.first.colors,
        ),
    ];
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
    loadDbSongs();
  }

  /// Signs out of Supabase and returns to the Sign in page.
  void signOut() {
    AuthService.signOut();
    _playlistId = null;
    shareToken = null;
    playlist.clear();
    dbSongs = [];
    recents.clear();
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

  /// Turns a saved row back into a [Song]. Songs from your database are
  /// looked up in the `songs` table; online songs get their lyrics fetched
  /// again.
  Future<Song> _songFromSaved(SavedSong s) async {
    if (s.source == 'supabase') {
      final cached = dbSongs.where((x) => x.id == s.songId).firstOrNull;
      if (cached != null) return cached;
      try {
        final row = await SongRepository.fetchById(s.songId);
        if (row != null) return Song.fromRow(row);
      } catch (_) {
        // fall through to the placeholder below
      }
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
      // Rows saved from the old built-in sample songs no longer exist.
      final songs = await Future.wait(
        saved.where((s) => s.source != 'sample').map(_songFromSaved),
      );
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
      if (saved.source == 'sample') continue;
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

  /// Shown only if the reader is somehow opened before a song is picked.
  static const _noSong = Song(
    id: '',
    title: 'No song selected',
    singer: '',
    lines: [],
    colors: playlistColors,
    minutes: 1,
  );

  Song get currentSong => _currentSong ?? dbSongs.firstOrNull ?? _noSong;

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

  /// Starts empty; filled as the user searches and opens things.
  final List<RecentSearch> recents = [];

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
    final songs = dbSongs.where((s) => s.singer.trim() == singer.name).toList();
    if (songs.isEmpty) return false;
    openSong(songs.first);
    return true;
  }

  Song nextSongAfter(Song song) {
    if (dbSongs.isEmpty) return song;
    final i = dbSongs.indexWhere((s) => s.id == song.id);
    return dbSongs[(i + 1) % dbSongs.length];
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

  /// Songs that can still be added to the playlist: the songs in your
  /// database that are not in it yet.
  List<Song> get candidates =>
      dbSongs.where((s) => !playlist.any((p) => p.id == s.id)).toList();

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
    songs: dbSongs,
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
