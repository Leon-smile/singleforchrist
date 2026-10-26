import 'package:flutter/material.dart';
import 'package:mobileappsfc/LyricsPage.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/functions/add_lyrics.dart';
import 'package:mobileappsfc/homepage.dart';
import 'package:mobileappsfc/library.dart';
import 'package:mobileappsfc/search_page.dart';
import 'package:mobileappsfc/share_page.dart';

/// Chooses phone vs desktop chrome and shows the page for the current route.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final desktop = box.maxWidth >= kDesktopBreakpoint;
        final Widget page = switch (state.route) {
          AppRoute.home => HomePage(desktop: desktop),
          AppRoute.search => SearchPage(desktop: desktop),
          AppRoute.library => LibraryPage(desktop: desktop),
          AppRoute.addLyrics => AddLyricsPage(desktop: desktop),
          AppRoute.share => SharePage(desktop: desktop),
          AppRoute.lyrics => LyricsPage(
            key: ValueKey(state.currentSong.id),
            desktop: desktop,
          ),
        };

        if (desktop) {
          return Scaffold(
            body: Row(
              children: [
                const Sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      const DesktopTopBar(),
                      Expanded(child: page),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          body: SafeArea(child: page),
          bottomNavigationBar: const BottomNav(),
        );
      },
    );
  }
}
