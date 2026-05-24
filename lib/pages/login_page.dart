import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_assets.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final short = constraints.maxHeight < 680;

          return Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  AppAssets.loginHeroSoft,
                  fit: BoxFit.cover,
                  alignment: wide ? Alignment.centerRight : Alignment.center,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: wide
                          ? Alignment.centerLeft
                          : Alignment.bottomCenter,
                      end: wide ? Alignment.centerRight : Alignment.topCenter,
                      colors: wide
                          ? [
                              scheme.surface.withValues(alpha: 0.76),
                              scheme.surface.withValues(alpha: 0.38),
                              Colors.transparent,
                            ]
                          : [
                              scheme.surface.withValues(alpha: 0.86),
                              scheme.surface.withValues(alpha: 0.32),
                              Colors.transparent,
                            ],
                      stops: wide
                          ? const [0, 0.43, 0.78]
                          : const [0, 0.46, 0.82],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 60 : 20,
                    wide ? 38 : 20,
                    wide ? 60 : 20,
                    wide ? 38 : 22,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - (wide ? 76 : 42),
                    ),
                    child: Align(
                      alignment: wide
                          ? Alignment.centerLeft
                          : Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: wide ? 430 : 440),
                        child: _LoginContent(auth: auth, dense: short && !wide),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LoginContent extends StatelessWidget {
  final AuthProvider auth;
  final bool dense;

  const _LoginContent({required this.auth, required this.dense});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.36),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(dense ? 18 : 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _LoginBrand(),
                SizedBox(height: dense ? 18 : 24),
                Text(
                  'Write today.\nOpen later.',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    height: 1.05,
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'A quiet letter for future-you, sealed by date and kept until the right moment arrives.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                if (!dense) ...[const SizedBox(height: 18), const _StoryLine()],
                if (auth.error != null) ...[
                  SizedBox(height: dense ? 16 : 20),
                  _AuthErrorBanner(
                    message: auth.error!,
                    onDismissed: auth.clearError,
                  ),
                ],
                SizedBox(height: dense ? 20 : 26),
                _GoogleSignInButton(auth: auth),
                const SizedBox(height: 12),
                Text(
                  'Google only connects the vault to your account.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBrand extends StatelessWidget {
  const _LoginBrand();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            AppAssets.sakuraSealedLetter,
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Future Me',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Time capsule letters',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoryLine extends StatelessWidget {
  const _StoryLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = theme.textTheme.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w800,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Text('Write', style: style),
              _SoftDivider(color: scheme.outlineVariant),
              Text('Seal', style: style),
              _SoftDivider(color: scheme.outlineVariant),
              Expanded(
                child: Text(
                  'Return when time opens it',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  final Color color;

  const _SoftDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Divider(
          color: color.withValues(alpha: 0.72),
          thickness: 1,
          height: 1,
        ),
      ),
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismissed;

  const _AuthErrorBanner({required this.message, required this.onDismissed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      key: const Key('auth-error'),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: scheme.onErrorContainer,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            visualDensity: VisualDensity.compact,
            onPressed: onDismissed,
            color: scheme.onErrorContainer,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final AuthProvider auth;

  const _GoogleSignInButton({required this.auth});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return FilledButton(
      key: const Key('google-signin-button'),
      onPressed: auth.isBusy ? null : auth.signInWithGoogle,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: scheme.onSurface.withValues(alpha: 0.9),
        foregroundColor: scheme.surfaceContainerLowest,
        disabledBackgroundColor: scheme.onSurface.withValues(alpha: 0.28),
        disabledForegroundColor: scheme.surface.withValues(alpha: 0.86),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (auth.isBusy)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: scheme.surfaceContainerLowest,
              ),
            )
          else
            const _GoogleMarkShell(size: 24),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              auth.isBusy ? 'Signing in...' : 'Continue with Google',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMarkShell extends StatelessWidget {
  final double size;

  const _GoogleMarkShell({required this.size});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: CustomPaint(
          size: Size.square(size - 6),
          painter: _GoogleMarkPainter(),
        ),
      ),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.36;
    final stroke = size.width * 0.16;
    final arc = Rect.fromCircle(center: center, radius: radius);

    void segment(double start, double sweep, Color color) {
      canvas.drawArc(
        arc,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = color,
      );
    }

    segment(-math.pi * 0.9, math.pi * 0.47, const Color(0xFFEA4335));
    segment(-math.pi * 0.43, math.pi * 0.42, const Color(0xFFFBBC05));
    segment(-math.pi * 0.01, math.pi * 0.52, const Color(0xFF34A853));
    segment(math.pi * 0.51, math.pi * 0.66, const Color(0xFF4285F4));
    segment(-math.pi * 0.17, math.pi * 0.25, const Color(0xFF4285F4));

    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width * 0.86, center.dy),
      Paint()
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = const Color(0xFF4285F4),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
