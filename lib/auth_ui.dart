import 'package:flutter/material.dart';

abstract final class AuthColors {
  static const background = Color(0xFFF4F7FB);
  static const navy = Color(0xFF10234A);
  static const secondary = Color(0xFF64748B);
  static const input = Color(0xFFF2F6FC);
  static const border = Color(0xFFDBE5F1);
  static const placeholder = Color(0xFF8090A8);
  static const focus = Color(0xFF26BFD0);
  static const label = Color(0xFF111827);
  static const danger = Color(0xFFB42318);
}

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.children,
    this.logoWidth = 240,
    this.footer,
  });

  final List<Widget> children;
  final double logoWidth;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF0F172A) : AuthColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useCard = constraints.maxWidth >= 600;
            final content = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: useCard ? 36 : 0,
                  vertical: useCard ? 36 : 16,
                ),
                decoration: useCard
                    ? BoxDecoration(
                        color: dark ? const Color(0xFF172033) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F2A52),
                            blurRadius: 24,
                            offset: Offset(0, 8),
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/faydam_logo_wide.png',
                        width: logoWidth,
                        fit: BoxFit.contain,
                        semanticLabel: 'Faydam',
                      ),
                    ),
                    const SizedBox(height: 36),
                    ...children,
                    if (footer != null) ...[
                      const SizedBox(height: 28),
                      footer!,
                    ],
                  ],
                ),
              ),
            );
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, useCard ? 32 : 16, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - (useCard ? 64 : 40),
                ),
                child: Center(child: content),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.description});
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONEL DEVAM KONTROL SİSTEMİ',
          style: TextStyle(
            color: AuthColors.focus,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: dark ? Colors.white : AuthColors.navy,
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            color: dark ? const Color(0xFFB3C0D4) : AuthColors.secondary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

InputDecoration authInputDecoration(
  BuildContext context, {
  required String label,
  required String hint,
  Widget? suffixIcon,
  String? errorText,
}) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    errorText: errorText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: dark ? const Color(0xFF1E293B) : AuthColors.input,
    labelStyle: TextStyle(
      color: dark ? const Color(0xFFE2E8F0) : AuthColors.label,
      fontWeight: FontWeight.w600,
    ),
    floatingLabelStyle: const TextStyle(
      color: AuthColors.focus,
      fontWeight: FontWeight.w600,
    ),
    hintStyle: const TextStyle(color: AuthColors.placeholder),
    errorStyle: const TextStyle(color: AuthColors.danger, height: 1.25),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    enabledBorder: border(dark ? const Color(0xFF475569) : AuthColors.border),
    disabledBorder: border(dark ? const Color(0xFF334155) : AuthColors.border),
    focusedBorder: border(AuthColors.focus, 1.6),
    errorBorder: border(AuthColors.danger),
    focusedErrorBorder: border(AuthColors.danger, 1.6),
  );
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Semantics(
      button: true,
      label: loading ? '$label, işlem devam ediyor' : label,
      child: AnimatedOpacity(
        opacity: enabled || loading ? 1 : .55,
        duration: const Duration(milliseconds: 150),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2458BD), Color(0xFF258FC6)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x302458BD),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 54,
                child: Center(
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
