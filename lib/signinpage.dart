import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/artwork.dart';
import 'package:mobileappsfc/common.dart';
import 'package:mobileappsfc/logo.dart';
import 'package:mobileappsfc/registerpage.dart';
import 'package:mobileappsfc/service/authservice.dart';
import 'package:mobileappsfc/song.dart';
import 'package:mobileappsfc/songs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Width at which the page shows the brand panel next to the form.
const _wideBreakpoint = 900.0;

/// Sign in screen. Phone: one scrolling column. Web / tablet landscape:
/// brand panel on the left, form card on the right.
class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -1.1),
            radius: 1.1,
            colors: [Color(0x2EA6F36B), AppColors.bg],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final wide = box.maxWidth >= _wideBreakpoint;
              if (wide) {
                return Row(
                  children: [
                    const Expanded(flex: 11, child: _BrandPanel()),
                    Expanded(
                      flex: 10,
                      child: _FormScroller(
                        maxWidth: 440,
                        child: const _SignInCard(showLogo: false),
                      ),
                    ),
                  ],
                );
              }
              return _FormScroller(
                maxWidth: 480,
                child: const _SignInCard(showLogo: true),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Centers [child], caps its width, and scrolls when the screen is short
/// or the keyboard is open.
class _FormScroller extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const _FormScroller({required this.maxWidth, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: (box.maxHeight - 40).clamp(0.0, double.infinity),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================================
// Brand panel (wide screens)
// ======================================================================

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 40, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LogoLockup(markSize: 44, fontSize: 24),
          const Spacer(),
          Text(
            'Know the words.\nShare the song.',
            style: GoogleFonts.inter(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              letterSpacing: -2,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Lyrics for Single for Christ: read them anywhere, keep your '
            'favorites, and share them with the people you sing with.',
            style: TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
          ),
          const SizedBox(height: 32),
          const _Feature(
            icon: Icons.menu_book_rounded,
            title: 'Read lyrics anywhere',
            subtitle: 'Clear, big text that is easy to follow.',
          ),
          const _Feature(
            icon: Icons.library_music_rounded,
            title: 'Build playlists',
            subtitle: 'Collect the songs for your next gathering.',
          ),
          const _Feature(
            icon: Icons.share_rounded,
            title: 'Share with one link',
            subtitle: 'Send a whole playlist to a friend.',
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Feature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.outline),
            ),
            child: Icon(icon, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// Form card
// ======================================================================

class _SignInCard extends StatefulWidget {
  final bool showLogo;
  const _SignInCard({required this.showLogo});

  @override
  State<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends State<_SignInCard> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Name-only sign in. Accounts are created without a password, so the
  /// name is checked against the account saved on this device.
  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final typed = _name.text.trim();
    setState(() => _loading = true);
    try {
      final saved = await AuthService.savedName();
      if (!mounted) return;

      if (saved == null) {
        showToast(
          context,
          'No account found on this device. Tap "Sign up" to create one.',
        );
        return;
      }
      if (saved.trim().toLowerCase() != typed.toLowerCase()) {
        showToast(context, "That name doesn't match this device's account.");
        return;
      }

      showToast(context, 'Welcome back, $saved!');
      AppScope.of(context).signIn();
    } on AuthException catch (e) {
      if (mounted) showToast(context, e.message);
    } on PostgrestException {
      if (mounted) {
        showToast(context, 'Could not load your account. Please try again.');
      }
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'Could not reach the server. Check your connection.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Google sign in (works on any device).
  ///  * Phone: the account popup finishes here, so we move on right away.
  ///  * Web: the page leaves for Google and reloads; main.dart's saved
  ///    session check signs the user in after the reload.
  Future<void> _google() async {
    if (_loading || _googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;

      // isGoogleUser (not just isSignedIn): a leftover name-only session
      // must not count when the user simply closed the Google popup.
      if (AuthService.isGoogleUser) {
        await AuthService.ensureGoogleProfile();
        if (!mounted) return;
        showToast(context, 'Welcome!');
        AppScope.of(context).signIn();
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (e) {
      debugPrint('Google sign in error: $e');
      if (mounted) showToast(context, 'Google sign in failed: $e');
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  InputDecoration _decoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      prefixIcon: Icon(icon, size: 20, color: AppColors.muted),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: border(AppColors.outline),
      enabledBorder: border(AppColors.outline),
      focusedBorder: border(AppColors.accent),
      errorBorder: border(const Color(0xFFE5654A)),
      focusedErrorBorder: border(const Color(0xFFE5654A)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final song = allSongs.first;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.outline),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showLogo) ...[
              const Center(child: LogoMark(size: 64)),
              const SizedBox(height: 16),
            ],
            const Center(
              child: Text(
                'SINGLE FOR CHRIST',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Welcome back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your name to open your saved lyrics and playlists.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _RecentlySynced(song: song),
            const SizedBox(height: 22),
            const _Label('Your name'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _name,
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.name],
              onFieldSubmitted: (_) => _submit(),
              decoration: _decoration(
                hint: 'E.g. Elena Rostova',
                icon: Icons.person_outline_rounded,
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Please enter your name';
                if (value.length < 2) return 'Name is too short';
                if (value.length > 40) return 'Name is too long (40 max)';
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              expand: true,
              icon: _loading ? null : Icons.login_rounded,
              label: _loading ? 'Signing in...' : 'Sign in',
              onTap: _loading ? null : _submit,
            ),
            const SizedBox(height: 16),
            const _OrDivider(),
            const SizedBox(height: 16),
            _GoogleButton(
              loading: _googleLoading,
              onPressed: _loading || _googleLoading ? null : _google,
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpPage()),
                  ),
                  child: const Text(
                    'Sign up',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );
  }
}

class _RecentlySynced extends StatelessWidget {
  final Song song;
  const _RecentlySynced({required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Artwork(colors: song.colors, radius: 6, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RECENTLY READ',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.selectedTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 13,
                  color: AppColors.accent,
                ),
                SizedBox(width: 5),
                Text(
                  'Lyrics ready',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: AppColors.outline, height: 1));
    return const Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
        line,
      ],
    );
  }
}

/// "Continue with Google". Swap the "G" for Google's official logo asset
/// before publishing (see Google's branding guidelines).
class _GoogleButton extends StatelessWidget {
  final bool loading;
  final VoidCallback? onPressed;
  const _GoogleButton({required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.accent,
                ),
              )
            else
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            const SizedBox(width: 10),
            const Text(
              'Continue with Google',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
