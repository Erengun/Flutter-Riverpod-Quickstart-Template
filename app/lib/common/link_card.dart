import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkCard extends StatelessWidget {
  const LinkCard({
    super.key,
    required this.title,
    required this.icon,
    required this.url,
  });

  /// The already-localized title to show.
  final String title;
  final IconData icon;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow,
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: ListTile(
        onTap: _launchUrl,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        trailing: Icon(
          Ionicons.openOutline,
          color: Theme.of(context).textTheme.titleMedium!.color,
        ),
        title: Row(
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.apply(fontWeightDelta: 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Example: Use the url_launcher package to open the browser
  Future<bool> _launchUrl() async => await canLaunchUrl(url)
      ? await launchUrl(url)
      : throw Exception('Could not launch $url');
}
