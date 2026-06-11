import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';

// the default font family is empty, so we can use the default font family of the platform
// the system will choose the default font family of the platform
// iOS: San Francisco
// Android: Roboto
// Desktop: Based on the OS
const defaultFontFamily = '';

const builtInCodeFontFamily = 'RobotoMono';

// Alfred brand typography (Fitbill design system).
// Body/UI font: Geist Sans. Heading font: Tex Gyre Heros.
// Both are bundled in pubspec.yaml and used as the default typography.
const builtInBodyFontFamily = 'Geist';
const builtInHeadingFontFamily = 'Tex Gyre Heros';
const builtInHeadingCondensedFontFamily = 'Tex Gyre Heros Cn';

abstract class BaseAppearance {
  final white = const Color(0xFFFFFFFF);

  final Set<WidgetState> scrollbarInteractiveStates = <WidgetState>{
    WidgetState.pressed,
    WidgetState.hovered,
    WidgetState.dragged,
  };

  TextStyle getFontStyle({
    required String fontFamily,
    double? fontSize,
    FontWeight? fontWeight,
    Color? fontColor,
    double? letterSpacing,
    double? lineHeight,
  }) {
    fontSize = fontSize ?? FontSizes.s14;
    fontWeight = fontWeight ?? FontWeight.w400;
    letterSpacing = fontSize * (letterSpacing ?? 0.005);

    final textStyle = TextStyle(
      fontFamily: fontFamily.isEmpty ? null : fontFamily,
      fontSize: fontSize,
      color: fontColor,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    if (fontFamily == defaultFontFamily) {
      return textStyle;
    }

    try {
      return getGoogleFontSafely(
        fontFamily,
        fontSize: fontSize,
        fontColor: fontColor,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        lineHeight: lineHeight,
      );
    } catch (e) {
      return textStyle;
    }
  }

  TextTheme getTextTheme({
    required String fontFamily,
    required Color fontColor,
  }) {
    // Alfred typography: when no custom font is selected (default), headings use
    // Tex Gyre Heros and body text uses Geist. A user-selected font applies to all.
    final headingFontFamily =
        fontFamily.isEmpty ? builtInHeadingFontFamily : fontFamily;
    final bodyFontFamily =
        fontFamily.isEmpty ? builtInBodyFontFamily : fontFamily;
    return TextTheme(
      displayLarge: getFontStyle(
        fontFamily: headingFontFamily,
        fontSize: FontSizes.s32,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
        lineHeight: 42.0,
      ), // h2
      displayMedium: getFontStyle(
        fontFamily: headingFontFamily,
        fontSize: FontSizes.s24,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
        lineHeight: 34.0,
      ), // h3
      displaySmall: getFontStyle(
        fontFamily: headingFontFamily,
        fontSize: FontSizes.s20,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
        lineHeight: 28.0,
      ), // h4
      titleLarge: getFontStyle(
        fontFamily: headingFontFamily,
        fontSize: FontSizes.s18,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
      ), // title
      titleMedium: getFontStyle(
        fontFamily: headingFontFamily,
        fontSize: FontSizes.s16,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
      ), // heading
      titleSmall: getFontStyle(
        fontFamily: headingFontFamily,
        fontSize: FontSizes.s14,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
      ), // subheading
      bodyMedium: getFontStyle(
        fontFamily: bodyFontFamily,
        fontColor: fontColor,
      ), // body-regular
      bodySmall: getFontStyle(
        fontFamily: bodyFontFamily,
        fontColor: fontColor,
        fontWeight: FontWeight.w400,
      ), // body-thin
    );
  }

  ThemeData getThemeData(
    AppTheme appTheme,
    Brightness brightness,
    String fontFamily,
    String codeFontFamily,
  );
}
