import 'package:flutter/material.dart';

class Singer {
  final String name;
  final String highlights; // comma-separated song titles
  final List<Color> colors; // placeholder artwork gradient

  const Singer({
    required this.name,
    required this.highlights,
    required this.colors,
  });
}

class Song {
  final String id;
  final String title;
  final String singer;
  final List<String> lines;
  final List<Color> colors; // placeholder artwork gradient
  final int minutes;

  const Song({
    required this.id,
    required this.title,
    required this.singer,
    required this.lines,
    required this.colors,
    required this.minutes,
  });
}
