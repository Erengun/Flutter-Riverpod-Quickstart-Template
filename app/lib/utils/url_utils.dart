import 'package:url_launcher/url_launcher.dart';

/// Example: Use the url_launcher package to open the browser
Future<bool> openUrl(Uri url) async => await canLaunchUrl(url)
    ? await launchUrl(url, mode: LaunchMode.externalApplication)
    : throw Exception('Could not launch $url');
