import 'package:material_ui/material_ui.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.text});

  /// The already-localized text to show.
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 2, top: 48, bottom: 24),
      child: Text(
        text,
        textAlign: TextAlign.start,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium!.apply(fontWeightDelta: 2),
      ),
    );
  }
}
