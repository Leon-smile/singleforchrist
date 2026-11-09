import 'package:flutter/material.dart';
import 'package:mobileappsfc/Theme.dart';
import 'package:mobileappsfc/app_state.dart';
import 'package:mobileappsfc/service/authservice.dart';
import 'package:mobileappsfc/common.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

/// ---------------------------------------------------------------------------
/// Design tokens
/// ---------------------------------------------------------------------------
class SonoraColors {
  // Shared with the rest of the app (Theme.dart)
  static const background = AppColors.bg;
  static const surface = AppColors.surface;
  static const field = AppColors.surfaceHigh;
  static const lime = AppColors.accent;
  static const muted = AppColors.muted;
  // Register-page only
  static const limeSoft = Color(0xFFD4F5A8);
  static const text = Color(0xFFF1F5E3);
  static const barOff = Color(0xFF2A302A);
}

/// ---------------------------------------------------------------------------
/// Breakpoints
/// ---------------------------------------------------------------------------
class _Breakpoints {
  static const double tablet = 700;
  static const double desktop = 960;
}

/// ---------------------------------------------------------------------------
/// Page
/// ---------------------------------------------------------------------------
/// Register screen. Opened from the Sign in page's "Sign up" link.
/// Step 1: name + email + password.
/// Step 2: type the 6-digit code that was emailed (when confirmation is on).
class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SonoraColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final isDesktop = w >= _Breakpoints.desktop;
            final hPad = w >= _Breakpoints.tablet ? 32.0 : 16.0;

            return Column(
              children: [
                _TopBar(horizontalPadding: hPad, showTitle: w >= 380),
                Expanded(
                  child: isDesktop
                      ? Row(
                          children: [
                            const Expanded(child: _BrandPanel()),
                            Expanded(
                              child: _FormScroller(horizontalPadding: hPad),
                            ),
                          ],
                        )
                      : _FormScroller(horizontalPadding: hPad),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FormScroller extends StatelessWidget {
  const _FormScroller({required this.horizontalPadding});
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: const _SignUpForm(),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Top bar
/// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  const _TopBar({required this.horizontalPadding, required this.showTitle});
  final double horizontalPadding;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, color: SonoraColors.text),
            tooltip: 'Back',
          ),
          const SizedBox(width: 4),
          const _Logo(),
          const Spacer(),
          if (showTitle)
            const Text(
              'Create Account',
              style: TextStyle(
                color: SonoraColors.limeSoft,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          const Spacer(),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: SonoraColors.limeSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 20,
              color: SonoraColors.background,
            ),
          ),
        ],
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.circle, size: 7, color: SonoraColors.lime),
        SizedBox(width: 5),
        Text(
          'SONORA',
          style: TextStyle(
            color: SonoraColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// ---------------------------------------------------------------------------
/// Desktop-only brand panel
/// ---------------------------------------------------------------------------
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1B2A14), Color(0xFF0F140F)],
          ),
        ),
        padding: const EdgeInsets.all(48),
        alignment: Alignment.bottomLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Icon(Icons.graphic_eq, color: SonoraColors.lime, size: 48),
            SizedBox(height: 24),
            Text(
              'Words that\nsound like midnight.',
              style: TextStyle(
                color: SonoraColors.text,
                fontSize: 44,
                height: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Save lyrics, sync playlists, and discover late-night poetic verses.',
              style: TextStyle(color: SonoraColors.muted, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Form (name + email + password, then confirmation code)
/// ---------------------------------------------------------------------------
class _SignUpForm extends StatefulWidget {
  const _SignUpForm();

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  /// Name the server said is taken (lower case), shown as a field error.
  String? _takenName;
  bool _googleLoading = false;

  /// Set after sign up while we wait for the emailed 6-digit code.
  String? _pendingEmail;
  DateTime _resendAt = DateTime.now();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = AuthService.normalizeName(_name.text);
    setState(() => _loading = true);
    try {
      final signedIn = await AuthService.signUpWithEmail(
        name: name,
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;

      if (signedIn) {
        showToast(context, 'Welcome, $name!');
        AppScope.of(context).signIn();
        // Close the register page (and anything above the root).
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Email confirmation is on: show the code screen.
        setState(() {
          _pendingEmail = AuthService.normalizeEmail(_email.text);
          _resendAt = DateTime.now().add(const Duration(seconds: 30));
        });
      }
    } on NameTakenException catch (e) {
      if (!mounted) return;
      setState(() => _takenName = name.toLowerCase());
      _formKey.currentState?.validate(); // shows the red message on the field
      showToast(context, e.message);
    } on AuthException catch (e) {
      if (mounted) showToast(context, e.message);
    } on PostgrestException {
      if (mounted) {
        showToast(
          context,
          'Your account could not be saved. Please try again.',
        );
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

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (_loading) return;
    if (code.length < 6) {
      showToast(context, 'Enter the 6-digit code from your email.');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.verifySignUpCode(email: _pendingEmail!, code: code);
      if (!mounted) return;
      showToast(context, 'Email confirmed. Welcome!');
      AppScope.of(context).signIn();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthException {
      if (mounted) showToast(context, 'That code is wrong or has expired.');
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

  Future<void> _resend() async {
    if (DateTime.now().isBefore(_resendAt)) {
      showToast(context, 'Please wait a few seconds before resending.');
      return;
    }
    try {
      await AuthService.resendConfirmation(_pendingEmail!);
      _resendAt = DateTime.now().add(const Duration(seconds: 30));
      if (mounted) showToast(context, 'A new code is on its way.');
    } on AuthException catch (e) {
      if (mounted) showToast(context, e.message);
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'Could not reach the server. Check your connection.',
        );
      }
    }
  }

  /// Google sign in.
  ///  * Phone: the account popup finishes here, so we move on right away.
  ///  * Web: the page leaves for Google and reloads; main.dart's saved
  ///    session check signs the user in after the reload.
  Future<void> _google() async {
    if (_loading || _googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;

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

  Widget _buildVerify() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _MembershipCard(),
        const SizedBox(height: 28),
        Text(
          'We sent a 6-digit code to $_pendingEmail.',
          style: const TextStyle(color: SonoraColors.limeSoft, fontSize: 14),
        ),
        const SizedBox(height: 16),
        const _FieldLabel('CONFIRMATION CODE'),
        _SonoraField(
          controller: _code,
          hint: '123456',
          icon: Icons.pin_outlined,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.oneTimeCode],
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: _loading ? 'CHECKING...' : 'CONFIRM',
          onPressed: _loading ? null : _verify,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _resend,
              child: const Text(
                'Resend code',
                style: TextStyle(color: SonoraColors.lime),
              ),
            ),
            TextButton(
              onPressed: () => setState(() {
                _pendingEmail = null;
                _code.clear();
              }),
              child: const Text(
                'Change email',
                style: TextStyle(color: SonoraColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingEmail != null) return _buildVerify();

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MembershipCard(),
          const SizedBox(height: 28),

          const _FieldLabel('YOUR NAME'),
          _SonoraField(
            controller: _name,
            hint: 'E.g. Elena Rostova',
            icon: Icons.person_outline,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            onChanged: (_) {
              if (_takenName != null) setState(() => _takenName = null);
            },
            validator: (v) {
              final value = AuthService.normalizeName(v ?? '');
              if (value.isEmpty) return 'Please enter your name';
              if (value.length < 2) return 'Name is too short';
              if (value.length > 40) return 'Name is too long (40 max)';
              if (_takenName != null && value.toLowerCase() == _takenName) {
                return 'That name is already taken';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          const _FieldLabel('EMAIL'),
          _SonoraField(
            controller: _email,
            hint: 'you@example.com',
            icon: Icons.mail_outline,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) => AuthService.isValidEmail(v ?? '')
                ? null
                : 'Enter a valid email address',
          ),
          const SizedBox(height: 16),

          const _FieldLabel('PASSWORD'),
          _SonoraField(
            controller: _password,
            hint: 'At least 8 characters',
            icon: Icons.lock_outline,
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            onSubmitted: (_) => _submit(),
            suffix: IconButton(
              tooltip: _obscure ? 'Show password' : 'Hide password',
              icon: Icon(
                _obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: SonoraColors.muted,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
            validator: (v) => AuthService.passwordProblem(v ?? ''),
          ),
          const SizedBox(height: 24),

          _PrimaryButton(
            label: _loading ? 'CREATING...' : 'CREATE ACCOUNT',
            onPressed: _loading ? null : _submit,
          ),
          const SizedBox(height: 18),
          const _OrDivider(),
          const SizedBox(height: 18),
          _GoogleButton(
            loading: _googleLoading,
            onPressed: _loading || _googleLoading ? null : _google,
          ),
          const SizedBox(height: 18),

          Center(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Already have an account? ',
                  style: TextStyle(color: SonoraColors.text, fontSize: 13),
                ),
                InkWell(
                  onTap: () => Navigator.maybePop(context), // back to Sign in
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Sign in ›',
                      style: TextStyle(
                        color: SonoraColors.lime,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Components
/// ---------------------------------------------------------------------------
class _MembershipCard extends StatelessWidget {
  const _MembershipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF223219), Color(0xFF131813)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.graphic_eq, size: 14, color: SonoraColors.lime),
              SizedBox(width: 6),
              Text(
                'MEMBERSHIP',
                style: TextStyle(
                  color: SonoraColors.limeSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Create your account',
            style: TextStyle(
              color: SonoraColors.text,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Create your account with your name, email and a password.',
            style: TextStyle(
              color: SonoraColors.limeSoft,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: SonoraColors.limeSoft,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SonoraField extends StatelessWidget {
  const _SonoraField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: c, width: w),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onSubmitted,
      onChanged: onChanged,
      obscureText: obscureText,
      enableSuggestions: !obscureText,
      autocorrect: !obscureText,
      cursorColor: SonoraColors.lime,
      style: const TextStyle(color: SonoraColors.text, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: SonoraColors.muted),
        prefixIcon: Icon(icon, color: SonoraColors.limeSoft, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: SonoraColors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(SonoraColors.lime, 1.5),
        errorBorder: border(Colors.redAccent),
        focusedErrorBorder: border(Colors.redAccent, 1.5),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: SonoraColors.lime.withOpacity(0.35),
            blurRadius: 24,
            spreadRadius: 1,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: SonoraColors.lime,
            disabledBackgroundColor: SonoraColors.lime.withOpacity(0.5),
            foregroundColor: SonoraColors.background,
            disabledForegroundColor: SonoraColors.background,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: Color(0xFF2A302A), height: 1));
    return const Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: SonoraColors.muted,
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
  const _GoogleButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: SonoraColors.text,
          side: const BorderSide(color: Color(0xFF3A423A)),
          shape: const StadiumBorder(),
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
                  color: SonoraColors.lime,
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
              'CONTINUE WITH GOOGLE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
