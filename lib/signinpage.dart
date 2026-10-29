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
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _pwFocus = FocusNode();

  bool _obscure = true;
  bool _remember = true;
  bool _loading = false;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    _pwFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    // Prototype: pretend to check the account. Replace with Supabase /
    // Firebase sign-in here.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    showToast(context, 'Welcome back!');
    setState(() => _loading = false);
    AppScope.of(context).signIn();
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
              'Sign in to access your saved lyrics and playlists.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _RecentlySynced(song: song),
            const SizedBox(height: 22),
            const _Label('Email or Username'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _id,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              onFieldSubmitted: (_) => _pwFocus.requestFocus(),
              decoration: _decoration(
                hint: 'listener@sfclyrics.app',
                icon: Icons.mail_outline_rounded,
              ),
              validator: (v) => (v == null || v.trim().length < 3)
                  ? 'Enter your email or username'
                  : null,
            ),
            const SizedBox(height: 16),
            const _Label('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pw,
              focusNode: _pwFocus,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onFieldSubmitted: (_) => _submit(),
              decoration: _decoration(
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                suffix: IconButton(
                  tooltip: _obscure ? 'Show password' : 'Hide password',
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.muted,
                  ),
                ),
              ),
              validator: (v) => (v == null || v.length < 6)
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _remember,
                    activeColor: AppColors.accent,
                    checkColor: Colors.black,
                    side: const BorderSide(color: AppColors.muted),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    onChanged: (v) => setState(() => _remember = v ?? false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _remember = !_remember),
                    child: const Text(
                      'Remember me',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final email = _id.text.trim();
                    if (!email.contains('@')) {
                      showToast(context, 'Enter your email first');
                      return;
                    }
                    try {
                      await AuthService.resetPassword(email);
                      if (context.mounted) {
                        showToast(
                          context,
                          'Reset link sent. Check your email.',
                        );
                      }
                    } on AuthException catch (e) {
                      if (context.mounted) showToast(context, e.message);
                    }
                  },
                  child: const Text('Forgot password?'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              expand: true,
              icon: _loading ? null : Icons.login_rounded,
              label: _loading ? 'Signing in...' : 'Sign in',
              onTap: _loading ? null : _submit,
            ),
            const SizedBox(height: 16),
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
