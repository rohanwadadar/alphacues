import 'package:flutter/material.dart';

class AlphaCuesFullLogo extends StatelessWidget {
  const AlphaCuesFullLogo({
    super.key,
    this.fontSize = 20.0,
  });

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Modernist Stylized Graphic Icon (Stock Growth Cue)
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF7C3AED), // Vibrant Violet/Deep Purple
                Color(0xFFC084FC), // Light Purple Glow
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Brand Typography: "AlphaCues"
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Alpha',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                ),
              ),
              TextSpan(
                text: 'Cues',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color(0xFFA855F7),
                      ],
                    ).createShader(
                      Rect.fromLTWH(0, 0, 100, fontSize),
                    ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
