import 'package:material_ui/material_ui.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'tokens_page.dart';

@widgetbook.UseCase(name: 'Default', type: TokensPage, path: '[Catalog]')
Widget buildTokensPage(BuildContext context) {
  return const TokensPage();
}
