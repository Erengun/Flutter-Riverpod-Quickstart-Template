import 'package:ionicons/ionicons.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../utils/context_extensions.dart';
import '../../../../../utils/url_utils.dart';

class SocialTile extends StatelessWidget {
  const SocialTile({
    required this.title,
    required this.url,
    required this.leadingIcon,
    super.key,
  });
  final String title;
  final Uri url;
  final Icon leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        enableFeedback: true,
        title: Text(
          title,
          style: context.textTheme.titleMedium!.copyWith(
            color: context.colorScheme.onSurface,
          ),
        ),
        contentPadding: const EdgeInsets.all(4),
        trailing: Icon(
          Ionicons.arrowForward,
          color: context.colorScheme.primary,
        ),
        tileColor: context.colorScheme.surface,
        selectedTileColor: context.colorScheme.onSurface,
        leading: Container(child: leadingIcon),
        onTap: () => openUrl(url),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }
}
