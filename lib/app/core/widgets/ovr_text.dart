import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class OvrText extends StatefulWidget {
  final int? ovr;
  final double fontSize;

  const OvrText({super.key, required this.ovr, this.fontSize = 48});

  @override
  State<OvrText> createState() => _OvrTextState();
}

class _OvrTextState extends State<OvrText> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.ovr == null) {
      return FadeTransition(
        opacity: _animation,
        child: Text(
          '???',
          style: GoogleFonts.bebasNeue(
            fontSize: widget.fontSize,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return Text(
      widget.ovr.toString(),
      style: GoogleFonts.bebasNeue(
        fontSize: widget.fontSize,
        color: AppColors.getTierColor(widget.ovr),
      ),
    );
  }
}
