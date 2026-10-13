---
version: alpha
name: "Flutter Production Boilerplate"
colors:
  primary: "#223a5e"
  primary-container: "#97baea"
  secondary: "#144955"
  secondary-container: "#a9edff"
  tertiary: "#208399"
  tertiary-container: "#ccf3ff"
  error: "#b00020"
  success: "#2e7d32"
  on-success: "#ffffff"
  warning: "#8a5100"
  on-warning: "#ffffff"
  info: "#1b6c80"
  on-info: "#ffffff"
  primary-dark: "#748bac"
  primary-container-dark: "#1b2e4b"
  secondary-dark: "#539eaf"
  secondary-container-dark: "#004e5d"
  tertiary-dark: "#219ab5"
  tertiary-container-dark: "#0f5b6a"
  error-dark: "#cf6679"
  success-dark: "#81c784"
  on-success-dark: "#003909"
  warning-dark: "#ffb86e"
  on-warning-dark: "#4a2800"
  info-dark: "#8ed0e4"
  on-info-dark: "#00363f"
typography:
  display-lg:
    fontFamily: Roboto
    fontSize: 57px
    fontWeight: 400
    lineHeight: 64px
    letterSpacing: -0.25px
  display-md:
    fontFamily: Roboto
    fontSize: 45px
    fontWeight: 400
    lineHeight: 52px
    letterSpacing: 0px
  display-sm:
    fontFamily: Roboto
    fontSize: 36px
    fontWeight: 400
    lineHeight: 44px
    letterSpacing: 0px
  headline-lg:
    fontFamily: Roboto
    fontSize: 32px
    fontWeight: 400
    lineHeight: 40px
    letterSpacing: 0px
  headline-md:
    fontFamily: Roboto
    fontSize: 28px
    fontWeight: 400
    lineHeight: 36px
    letterSpacing: 0px
  headline-sm:
    fontFamily: Roboto
    fontSize: 24px
    fontWeight: 400
    lineHeight: 32px
    letterSpacing: 0px
  title-lg:
    fontFamily: Roboto
    fontSize: 22px
    fontWeight: 400
    lineHeight: 28px
    letterSpacing: 0px
  title-md:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 500
    lineHeight: 24px
    letterSpacing: 0.15px
  title-sm:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 500
    lineHeight: 20px
    letterSpacing: 0.1px
  body-lg:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 400
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 400
    lineHeight: 20px
    letterSpacing: 0.25px
  body-sm:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 400
    lineHeight: 16px
    letterSpacing: 0.4px
  label-lg:
    fontFamily: Roboto
    fontSize: 14px
    fontWeight: 500
    lineHeight: 20px
    letterSpacing: 0.1px
  label-md:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 500
    lineHeight: 16px
    letterSpacing: 0.5px
  label-sm:
    fontFamily: Roboto
    fontSize: 11px
    fontWeight: 500
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 4px
  md: 8px
  lg: 16px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
---

# Design

## Overview

A clean Material 3 interface for a business app: calm, readable and consistent across Android, iOS and the web. Screens favour clear hierarchy and plenty of whitespace over decoration, and every value comes from the shared theme, so light and dark mode stay in step.

## Colors

The palette is built around a primary, a secondary and a tertiary color, each with a container color for larger, quieter surfaces, plus an error color. Success, warning and info cover status messages, each with an "on" color for text and icons placed on top of it. Every color has a light-mode value under its plain name and a dark-mode value under the same name with a `-dark` suffix. Surfaces, outlines and the remaining roles are derived from these colors by the theme.

## Typography

One font family is used throughout, in the Material 3 type scale: display and headline levels for large titles, title levels for section and card headings, body levels for running text, and label levels for buttons, chips and captions. Body medium is the default for most text.

## Layout

Spacing follows a small fixed scale from extra small to extra large. Content sits in a single scrolling column on phones, with the medium step as the usual padding around screen content and between related groups, and the smaller steps inside a control or between a label and its value.

## Elevation & Depth

Depth comes mostly from tonal surfaces rather than shadows: cards, sheets and app bars sit on slightly tinted surface colors that separate them from the background, with light elevation only where an element floats above the page, such as dialogs and menus.

## Shapes

Corners are gently rounded. The small radius suits chips and small controls, the medium radius suits buttons, fields and cards, and the large radius suits sheets and dialogs.
