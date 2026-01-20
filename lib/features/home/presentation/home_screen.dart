import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../utils/context_extensions.dart';
import 'widgets/header.dart';
import 'widgets/language_tile.dart';
import 'widgets/social_tile_widget.dart';
import 'widgets/theme_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.logout_outlined, color: context.colorScheme.primary),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      backgroundColor: context.colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const Header(text: 'intro'),
          const Divider(),
          const ThemeWidget(),
          const LanguageTile(),
          ListView.separated(
            itemCount: 4,
            shrinkWrap: true,
            padding: const EdgeInsets.all(8),
            separatorBuilder: (BuildContext context, int index) {
              return const Gap(5); // Change the height to control the gap size
            },
            itemBuilder: (BuildContext context, int index) {
              // Switch case to return different widgets for each index
              switch (index) {
                case 0:
                  return SocialTile(
                    leadingIcon: Icon(
                      Ionicons.logo_github,
                      color: context.colorScheme.primary,
                    ),
                    title: 'Github',
                    url: Uri.parse('https://github.com/erengun'),
                  );
                case 1:
                  return SocialTile(
                    leadingIcon: Icon(
                      Ionicons.logo_linkedin,
                      color: context.colorScheme.primary,
                    ),
                    title: 'Linkedin',
                    url: Uri.parse('https://www.linkedin.com/in/erengun'),
                  );
                case 2:
                  return SocialTile(
                    leadingIcon: Icon(
                      Ionicons.logo_medium,
                      color: context.colorScheme.primary,
                    ),
                    title: 'Medium',
                    url: Uri.parse('https://erengun.medium.com/'),
                  );
                case 3:
                  return SocialTile(
                    leadingIcon: Icon(
                      Ionicons.globe_outline,
                      color: context.colorScheme.primary,
                    ),
                    title: 'Website',
                    url: Uri.parse('https://erengun.dev'),
                  );
                default:
                  return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
