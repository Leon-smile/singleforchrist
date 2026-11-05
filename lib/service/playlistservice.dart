import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobileappsfc/song.dart';

/// The signed-in user's playlist row.
class PlaylistInfo {
  final String id;
  final String? shareToken; // null = not shared
  const PlaylistInfo({required this.id, required this.shareToken});
}

/// One song as stored in the database. Only title / singer / source are
/// saved, NOT the lyrics: online lyrics are fetched again when needed.
class SavedSong {
  final String songId; // 'slow-pulse' or 'lyrics-ovh-123'
  final String title;
  final String singer;
  final String source; // 'sample' or 'lyrics.ovh'

  const SavedSong({
    required this.songId,
    required this.title,
    required this.singer,
    required this.source,
  });

  factory SavedSong.fromJson(Map<String, dynamic> j) => SavedSong(
    songId: j['song_id'] as String,
    title: j['title'] as String,
    singer: j['singer'] as String,
    source: (j['source'] as String?) ?? 'sample',
  );
}

/// A playlist opened with a share code (read only).
class SharedPlaylist {
  final String name;
  final List<SavedSong> songs;
  const SharedPlaylist({required this.name, required this.songs});
}

/// All database access for playlists and sharing.
/// Tables: playlists, playlist_songs. Functions: share_playlist,
/// stop_sharing_playlist, get_shared_playlist (see the SQL).
class PlaylistService {
  PlaylistService._();

  static SupabaseClient get _c => Supabase.instance.client;

  /// The user's playlist called [name]. Created the first time.
  /// Needs the unique index on playlists(owner_id, name).
  static Future<PlaylistInfo> ensurePlaylist(String name) async {
    final uid = _c.auth.currentUser?.id;
    if (uid == null) throw const AuthException('Please sign in first.');

    final row = await _c
        .from('playlists')
        .upsert({'owner_id': uid, 'name': name}, onConflict: 'owner_id,name')
        .select('id, share_token')
        .single();

    return PlaylistInfo(
      id: row['id'] as String,
      shareToken: row['share_token'] as String?,
    );
  }

  static Future<List<SavedSong>> songs(String playlistId) async {
    final rows = await _c
        .from('playlist_songs')
        .select('song_id, title, singer, source')
        .eq('playlist_id', playlistId)
        .order('position');
    return [
      for (final r in rows as List)
        SavedSong.fromJson(Map<String, dynamic>.from(r as Map)),
    ];
  }

  static Future<void> addSong(String playlistId, Song song, int position) {
    return _c
        .from('playlist_songs')
        .upsert(
          {
            'playlist_id': playlistId,
            'song_id': song.id,
            'title': song.title,
            'singer': song.singer,
            'source': song.source,
            'position': position,
          },
          onConflict: 'playlist_id,song_id',
          ignoreDuplicates: true,
        );
  }

  static Future<void> removeSong(String playlistId, String songId) {
    return _c
        .from('playlist_songs')
        .delete()
        .eq('playlist_id', playlistId)
        .eq('song_id', songId);
  }

  /// Turns sharing on and returns the code (the same code every time).
  static Future<String> share(String playlistId) async {
    final token = await _c.rpc(
      'share_playlist',
      params: {'p_playlist_id': playlistId},
    );
    return token as String;
  }

  /// Turns sharing off. The old code stops working.
  static Future<void> stopSharing(String playlistId) async {
    await _c.rpc(
      'stop_sharing_playlist',
      params: {'p_playlist_id': playlistId},
    );
  }

  /// Opens a playlist from its share code. Null when the code is not valid
  /// (wrong, or the owner stopped sharing). Works without signing in.
  static Future<SharedPlaylist?> getShared(String code) async {
    final res = await _c.rpc(
      'get_shared_playlist',
      params: {'p_token': code.trim()},
    );
    if (res == null) return null;

    final map = Map<String, dynamic>.from(res as Map);
    final list = (map['songs'] as List?) ?? const [];
    return SharedPlaylist(
      name: (map['name'] as String?) ?? 'Shared playlist',
      songs: [
        for (final s in list)
          SavedSong.fromJson(Map<String, dynamic>.from(s as Map)),
      ],
    );
  }
}
