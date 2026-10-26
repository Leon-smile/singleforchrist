import 'package:flutter/material.dart';
import 'package:mobileappsfc/song.dart';

// Sample content only (fictional singers, original placeholder lines).
// Swap for real data from Supabase / Firebase later.
// Artwork is a gradient placeholder; replace with network images when ready.

const List<Color> playlistColors = [Color(0xFF8C6D3F), Color(0xFF13201A)];

const List<Singer> allSingers = [
  Singer(
    name: 'Kai Ren',
    highlights: 'Slow pulse, Midnight city, Echoes',
    colors: [Color(0xFFB04BFF), Color(0xFF241766)],
  ),
  Singer(
    name: 'Luna Vance',
    highlights: 'Soft focus, Saltwater, Sunday night',
    colors: [Color(0xFF6FA35A), Color(0xFF1B2A55)],
  ),
  Singer(
    name: 'Noah Kane',
    highlights: 'North wind, Empty room, Lost in the haze',
    colors: [Color(0xFFD08433), Color(0xFF2B1A12)],
  ),
  Singer(
    name: 'Zara Sloan',
    highlights: 'Wildflower, Quiet hours, Paper planes',
    colors: [Color(0xFFE23B4E), Color(0xFF2B1B3A)],
  ),
  Singer(
    name: 'Lena Rose',
    highlights: 'Velvet sky, Slow burn, Morning light',
    colors: [Color(0xFF7FA3B8), Color(0xFF1C2A33)],
  ),
];

const List<Song> allSongs = [
  Song(
    id: 'slow-pulse',
    title: 'Slow pulse',
    singer: 'Kai Ren',
    minutes: 2,
    colors: [Color(0xFFE08A3C), Color(0xFF1F2A1E)],
    lines: [
      'Midnight city, slow pulse',
      'The words we left unsaid',
      'Still echo in the hallway',
      'Where the lights are low and the night is long.',
    ],
  ),
  Song(
    id: 'quiet-hours',
    title: 'Quiet hours',
    singer: 'Luna Vance',
    minutes: 1,
    colors: [Color(0xFF4F7A68), Color(0xFF16221D)],
    lines: [
      'Rain on the roof, coffee cold',
      'A page turned, a story old',
      'The silence feels like a home',
      'Where I can finally be alone.',
    ],
  ),
  Song(
    id: 'summer-nights',
    title: 'Summer nights',
    singer: 'Noah Kane',
    minutes: 2,
    colors: [Color(0xFFB04BFF), Color(0xFF2A1B6B)],
    lines: [
      'Summer nights, salt air',
      "A memory we couldn't share",
      'The highway unwinds like a line',
      'Between what we had and what we left behind.',
    ],
  ),
  Song(
    id: 'wildflower',
    title: 'Wildflower',
    singer: 'Zara Sloan',
    minutes: 2,
    colors: [Color(0xFF5B8BD6), Color(0xFF1B2342)],
    lines: [
      'I grew through the cracks in the stone',
      'Found a little sunlight of my own',
      'Let the wild wind carry me home',
      'I can bloom wherever I roam.',
    ],
  ),
  Song(
    id: 'echoes',
    title: 'Echoes',
    singer: 'Kai Ren',
    minutes: 1,
    colors: [Color(0xFF7B5CFF), Color(0xFF1E1650)],
    lines: [
      'I send my words across the blue',
      'And every echo sounds like you.',
      'Back to me, a little late',
      'Still I wait, still I wait.',
    ],
  ),
  Song(
    id: 'paper-planes',
    title: 'Paper planes',
    singer: 'Zara Sloan',
    minutes: 2,
    colors: [Color(0xFFE5654A), Color(0xFF3A1B1B)],
    lines: [
      'We folded our fears into paper wings',
      'And let the sky hold everything.',
      'Out past the rooftops, out past the rain',
      'They find their way home again.',
    ],
  ),
  Song(
    id: 'morning-light',
    title: 'Morning light',
    singer: 'Lena Rose',
    minutes: 1,
    colors: [Color(0xFFD9A441), Color(0xFF2B2416)],
    lines: [
      'Curtains open, the day begins',
      'Soft gold spilling over the sill',
      'Whatever came before, it fades',
      'In the quiet of the morning light.',
    ],
  ),
  Song(
    id: 'north-wind',
    title: 'North wind',
    singer: 'Noah Kane',
    minutes: 1,
    colors: [Color(0xFF6E8FA6), Color(0xFF1A242C)],
    lines: [
      'North wind knocking at my door',
      'Carrying a cold I know',
      'Pull the blanket, light the stove',
      'Let the winter come and go.',
    ],
  ),
];

Song songById(String id) => allSongs.firstWhere((s) => s.id == id);
