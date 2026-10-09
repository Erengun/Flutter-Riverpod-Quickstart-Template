import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/core_localizations.dart';
import '../theme/konteyner_tokens.dart';
import 'api_exception.dart';

/// The text to show for [error]: an [ApiException]'s own message or Core's
/// default for its kind, and Core's "something went wrong" for anything
/// else.
String apiErrorMessage(Object error, CoreLocalizations l10n) {
  return error is ApiException
      ? error.localizedMessage(l10n)
      : l10n.errorSomethingWentWrong;
}

/// Shows a screen's failed requests to the user.
extension ApiErrorListening on WidgetRef {
  /// Shows a floating snackbar with the message each time [provider] becomes
  /// an `AsyncError`. Call it in `build`, like `ref.listen`.
  ///
  /// [ApiUnauthorizedException] (the auth Feature redirects) and
  /// [ApiCancelledException] show nothing.
  void listenApiErrors<T>(
    ProviderListenable<AsyncValue<T>> provider,
    BuildContext context,
  ) {
    listen<AsyncValue<T>>(provider, (
      AsyncValue<T>? previous,
      AsyncValue<T> next,
    ) {
      if (next.isLoading || !next.hasError) return;
      final Object error = next.error!;
      if (previous != null &&
          !previous.isLoading &&
          identical(previous.error, error)) {
        return;
      }
      if (error is ApiUnauthorizedException || error is ApiCancelledException) {
        return;
      }
      if (!context.mounted) return;
      final String message = apiErrorMessage(
        error,
        CoreLocalizations.of(context),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    });
  }
}

/// A full-screen error with a retry button, for a screen whose main data
/// failed to load. Opt-in: use it in the `error` branch of
/// `AsyncValue.when`.
class ApiErrorView extends StatelessWidget {
  const ApiErrorView({required this.error, this.onRetry, super.key});

  /// The failure; its message comes from [apiErrorMessage].
  final Object error;

  /// Runs the failed request again (usually `ref.invalidate(provider)`).
  /// No button when `null`.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final CoreLocalizations l10n = CoreLocalizations.of(context);
    final KonteynerTokens tokens = KonteynerTokens.of(context);
    final ThemeData theme = Theme.of(context);
    final VoidCallback? retry = onRetry;
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _iconFor(error),
              size: tokens.spaceXl * 2,
              color: theme.colorScheme.error,
            ),
            SizedBox(height: tokens.spaceMd),
            Text(
              apiErrorMessage(error, l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (retry != null) ...<Widget>[
              SizedBox(height: tokens.spaceLg),
              FilledButton.tonal(
                onPressed: retry,
                child: Text(l10n.errorRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(Object error) {
    return switch (error) {
      ApiConnectionException() => Icons.wifi_off_outlined,
      ApiTimeoutException() => Icons.hourglass_empty_outlined,
      ApiForbiddenException() => Icons.lock_outline,
      ApiNotFoundException() => Icons.search_off_outlined,
      _ => Icons.error_outline,
    };
  }
}
