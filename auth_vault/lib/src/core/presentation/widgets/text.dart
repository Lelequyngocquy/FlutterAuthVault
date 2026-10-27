import 'package:flutter/material.dart';
import '../../../common/constants/colors.dart';

class AppText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  const AppText._({
    super.key,
    required this.text,
    required this.style,
    this.textAlign,
    this.maxLines = 3,
    this.overflow = TextOverflow.ellipsis,
  });
  factory AppText.regular(
    String text, {
    Key? key,
    double fontSize = 14,
    Color? color,
    int? maxLines = 3,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return AppText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color ?? UIColors.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
      ),
    );
  }
  factory AppText.semiBold(
    String text, {
    Key? key,
    double fontSize = 15,
    Color? color,
    int? maxLines = 3,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return AppText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color ?? UIColors.ink,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  factory AppText.bold(
    String text, {
    Key? key,
    double fontSize = 18,
    Color? color,
    int? maxLines = 3,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return AppText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color ?? UIColors.inkStrong,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
      ),
    );
  }
  factory AppText.mono(
    String text, {
    Key? key,
    double fontSize = 13,
    Color? color,
    FontWeight fontWeight = FontWeight.w400,
    int? maxLines = 3,
    TextAlign? textAlign,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return AppText._(
      key: key,
      text: text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontFamily: 'monospace',
        color: color ?? UIColors.primary,
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: 0.5,
      ),
    );
  }
  factory AppText.eyebrow(
    String text, {
    Key? key,
    double fontSize = 12,
    Color? color,
    int? maxLines = 2,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return AppText._(
      key: key,
      text: text.toUpperCase(),
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color ?? UIColors.mute,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
