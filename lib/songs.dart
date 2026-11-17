import 'package:flutter/material.dart';
import 'package:mobileappsfc/song.dart';

// The sample songs and singers that used to live here are gone. Songs now
// come from Supabase (AppState.dbSongs) and the online lyrics search, and
// singers are built from those songs (AppState.dbSingers).

/// Fallback artwork colors for playlist songs and placeholders.
const List<Color> playlistColors = [Color(0xFF8C6D3F), Color(0xFF13201A)];

/// Kept empty only so any file that still imports these keeps compiling.
/// The analyzer will flag every remaining use; switch those to
/// AppState.dbSongs / AppState.dbSingers, then delete these three.
@Deprecated('Sample data was removed. Use AppState.dbSongs.')
const List<Song> allSongs = [];

@Deprecated('Sample data was removed. Use AppState.dbSingers.')
const List<Singer> allSingers = [];

@Deprecated('Sample data was removed. Look the song up in AppState.dbSongs.')
Song songById(String id) => allSongs.firstWhere((s) => s.id == id);
