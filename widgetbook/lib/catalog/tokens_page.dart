import 'package:core/core.dart';
import 'package:material_ui/material_ui.dart';

/// The design tokens of the current theme: the hand-set scheme colors and
/// Core's status colors, the spacing scale, the radii and the type scale.
///
/// Everything is read from `Theme.of(context)` and [CoreTokens.of], so the
/// page shows what the app's widgets get, in light and in dark. It shows the
/// same values as `DESIGN.md`'s frontmatter, which is generated from the
/// same theme. A catalog page, not an app widget.
class TokensPage extends StatelessWidget {
  const TokensPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final CoreTokens tokens = CoreTokens.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Design tokens')),
      body: ListView(
        padding: EdgeInsets.all(tokens.spaceMd),
        children: <Widget>[
          const _Heading('Colors'),
          _Swatch('primary', scheme.primary, scheme.onPrimary),
          _Swatch(
            'primaryContainer',
            scheme.primaryContainer,
            scheme.onPrimaryContainer,
          ),
          _Swatch('secondary', scheme.secondary, scheme.onSecondary),
          _Swatch(
            'secondaryContainer',
            scheme.secondaryContainer,
            scheme.onSecondaryContainer,
          ),
          _Swatch('tertiary', scheme.tertiary, scheme.onTertiary),
          _Swatch(
            'tertiaryContainer',
            scheme.tertiaryContainer,
            scheme.onTertiaryContainer,
          ),
          _Swatch('error', scheme.error, scheme.onError),
          _Swatch('success', tokens.success, tokens.onSuccess),
          _Swatch('warning', tokens.warning, tokens.onWarning),
          _Swatch('info', tokens.info, tokens.onInfo),
          const _Heading('Spacing'),
          _Space('xs', tokens.spaceXs),
          _Space('sm', tokens.spaceSm),
          _Space('md', tokens.spaceMd),
          _Space('lg', tokens.spaceLg),
          _Space('xl', tokens.spaceXl),
          const _Heading('Radii'),
          _Radius('sm', tokens.radiusSm),
          _Radius('md', tokens.radiusMd),
          _Radius('lg', tokens.radiusLg),
          const _Heading('Type scale'),
          _TypeSample('displayLarge', text.displayLarge),
          _TypeSample('displayMedium', text.displayMedium),
          _TypeSample('displaySmall', text.displaySmall),
          _TypeSample('headlineLarge', text.headlineLarge),
          _TypeSample('headlineMedium', text.headlineMedium),
          _TypeSample('headlineSmall', text.headlineSmall),
          _TypeSample('titleLarge', text.titleLarge),
          _TypeSample('titleMedium', text.titleMedium),
          _TypeSample('titleSmall', text.titleSmall),
          _TypeSample('bodyLarge', text.bodyLarge),
          _TypeSample('bodyMedium', text.bodyMedium),
          _TypeSample('bodySmall', text.bodySmall),
          _TypeSample('labelLarge', text.labelLarge),
          _TypeSample('labelMedium', text.labelMedium),
          _TypeSample('labelSmall', text.labelSmall),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final CoreTokens tokens = CoreTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceLg, bottom: tokens.spaceSm),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// A color with its name and hex value written in its "on" color.
class _Swatch extends StatelessWidget {
  const _Swatch(this.name, this.color, this.onColor);

  final String name;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    final CoreTokens tokens = CoreTokens.of(context);
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.labelLarge?.copyWith(color: onColor);
    final String hex = (color.toARGB32() & 0xFFFFFF)
        .toRadixString(16)
        .padLeft(6, '0')
        .toUpperCase();
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceXs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMd),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(name, style: style)),
              Text('#$hex', style: style),
            ],
          ),
        ),
      ),
    );
  }
}

/// A spacing step drawn as a bar that wide.
class _Space extends StatelessWidget {
  const _Space(this.name, this.value);

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    final CoreTokens tokens = CoreTokens.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: tokens.spaceXl * 2,
            child: Text('$name ${_format(value)}'),
          ),
          SizedBox(
            width: value,
            height: tokens.spaceMd,
            child: ColoredBox(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

/// A corner radius drawn on a box.
class _Radius extends StatelessWidget {
  const _Radius(this.name, this.value);

  final String name;
  final double value;

  @override
  Widget build(BuildContext context) {
    final CoreTokens tokens = CoreTokens.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceSm),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: tokens.spaceXl * 2,
            child: Text('$name ${_format(value)}'),
          ),
          Container(
            width: tokens.spaceXl * 2,
            height: tokens.spaceXl,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              border: Border.all(color: scheme.primary),
              borderRadius: BorderRadius.circular(value),
            ),
          ),
        ],
      ),
    );
  }
}

/// A type scale level written in its own style.
class _TypeSample extends StatelessWidget {
  const _TypeSample(this.name, this.style);

  final String name;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: CoreTokens.of(context).spaceSm),
      child: Text(name, style: style),
    );
  }
}

/// [value] without a trailing `.0`.
String _format(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
