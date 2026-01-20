import 'package:flutter/material.dart';

import '../utils/url_utils.dart';

class GridItem extends StatelessWidget {
  /// Named parameters are preferred, they make the code easier to understand.
  const GridItem({
    super.key,
    required this.title,
    required this.icon,
    required this.url,
    this.version,
  });

  final String title;
  final IconData icon;
  final Uri url;
  final String? version;

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
        onTap: () => openUrl(url),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium!.apply(
                fontWeightDelta: 2,
                fontSizeDelta: -2,
              ),
            ),
            if (version != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  version!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              const SizedBox(),
          ],
        ),
      ),
    );
  }
}
