import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/theme_controller.dart';
import '../constants/app_colors.dart';

class GlassTextField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool? enableSuggestions;
  final bool? autocorrect;

  const GlassTextField({
    super.key,
    required this.hintText,
    required this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.enableSuggestions,
    this.autocorrect,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  bool _obscureText = true;
  late final FocusNode _focusNode;
  late final bool _ownsFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _ownsFocusNode = widget.focusNode == null;
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // GetBuilder reacts to ThemeController.update() without needing
    // Obx — avoids the "no observable in scope" error when !_isFocused.
    return GetBuilder<ThemeController>(
      builder: (theme) {
        final primaryColor = theme.primaryColor;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // #FFFFFF at 5%
            borderRadius: BorderRadius.circular(16), // Radius 16px
            border: Border.all(
              color: _isFocused ? primaryColor : Colors.white.withOpacity(0.10), // #FFFFFF at 10% Unfocused
              width: 1, // 1px border
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            textCapitalization: widget.textCapitalization,
            autofillHints: widget.autofillHints,
            enableSuggestions:
                widget.enableSuggestions ?? (widget.isPassword ? false : true),
            autocorrect: widget.autocorrect ?? (widget.isPassword ? false : true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: Icon(
                widget.prefixIcon,
                color: _isFocused ? primaryColor : AppColors.textSecondary,
                size: 20,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48, // Align text exactly 48px from the left
                minHeight: 24,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              // Top 17px, Right 16px, Bottom 18px. (Left is handled by prefixIconConstraints width 48)
              contentPadding: const EdgeInsets.only(top: 17, bottom: 18, right: 16),
            ),
          ),
        );
      },
    );
  }
}
