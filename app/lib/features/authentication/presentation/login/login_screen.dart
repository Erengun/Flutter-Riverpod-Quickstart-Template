import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../constants/assets.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/login_request.dart';
import '../register/register_dialog.dart';
import 'auth_ui_model.dart';
import 'login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  /// Logs in with the form's values; the Login button and the password
  /// field's keyboard action both call it. Empty fields never reach the
  /// controller, whose check throws; every other failure becomes its
  /// `AsyncError`, which `build` shows.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final String email = _emailController.text;
    final String password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage(AppLocalizations.of(context).authCredentialsRequired);
      return;
    }
    // A successful login starts the session and the router's redirect
    // replaces this page with home.
    await ref
        .read(loginControllerProvider.notifier)
        .login(email: email, password: password);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final AsyncValue<AuthUiModel> authUiModelAsync = ref.watch(
      loginControllerProvider,
    ); // Access the state
    final bool sessionExpired = ref.watch(sessionExpiredProvider);
    // Failed logins become an AsyncError; Core shows their message.
    ref.listenApiErrors(loginControllerProvider, context);
    // listenApiErrors skips 401s, which elsewhere mean an expired session.
    // The login call skips auth, so its 401 means wrong credentials: show
    // the backend's message, or the Feature's own text without one.
    ref.listen(loginControllerProvider, (
      AsyncValue<AuthUiModel>? previous,
      AsyncValue<AuthUiModel> next,
    ) {
      final Object? error = next.error;
      if (next.isLoading || error is! ApiUnauthorizedException) return;
      if (previous != null &&
          !previous.isLoading &&
          identical(previous.error, error)) {
        return;
      }
      final String? message = error.message;
      _showMessage(
        message != null && message.isNotEmpty ? message : l10n.authLoginFailed,
      );
    });
    ref.listen(loginControllerProvider, (
      AsyncValue<AuthUiModel>? previous,
      AsyncValue<AuthUiModel> next,
    ) {
      // Pre-fills the form when saved or registered credentials arrive,
      // without undoing the user's typing on other state changes.
      final LoginCredentials? user = next.value?.user;
      if (user != null && user != previous?.value?.user) {
        _emailController.text = user.email;
        _passwordController.text = user.password;
      }
    });
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.authLoginTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.person_outline_outlined),
            onPressed: () async {
              await showAdaptiveDialog<void>(
                context: context,
                builder: (_) {
                  return const RegisterDialog();
                },
              );
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () {
            throw UnimplementedError();
          },
        ),
      ),
      body: authUiModelAsync.when(
        // A failed login keeps the form: listenApiErrors shows a snackbar.
        skipError: true,
        skipLoadingOnReload: true,
        data: (AuthUiModel authUiModel) => SafeArea(
          minimum: const EdgeInsets.symmetric(horizontal: 24),
          child: CustomScrollView(
            slivers: <Widget>[
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Spacer(),
                    Center(
                      child: Image.asset(Assets.logo, height: 90, width: 90),
                    ),
                    const Spacer(),
                    Center(
                      child: Text(
                        l10n.authWelcome,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const Gap(10),
                    Text(
                      l10n.authLoginSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    // Signed out by an expired session; cleared on sign-in.
                    if (sessionExpired) ...<Widget>[
                      Text(
                        CoreLocalizations.of(context).authSessionExpired,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const Gap(10),
                    ],
                    Text(
                      l10n.authLoginTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(10),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const <String>[AutofillHints.email],
                      autovalidateMode: AutovalidateMode.onUnfocus,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          return l10n.authEmailRequired;
                        }
                        // Regex for validating email format
                        final RegExp emailRegex = RegExp(
                          r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return l10n.authEmailInvalid;
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        hintText: l10n.authEmailHint,
                        hintStyle: const TextStyle(color: Colors.black54),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                    const Gap(15),
                    Text(
                      l10n.authPasswordLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(10),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !authUiModelAsync.value!.showPassword,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const <String>[AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.visiblePassword,
                      // validator: (String? value) {
                      //   /// Password validation logic
                      //   if (value != null && value.isNotEmpty) {
                      //     return 'Check letter case carefully.';
                      //   }
                      //   return null;
                      // },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onFieldSubmitted: (String value) => _submit(),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 15,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        hintText: l10n.authPasswordHint,
                        hintStyle: const TextStyle(color: Colors.black54),
                        suffixIcon: IconButton(
                          icon: Icon(
                            authUiModel.showPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => ref
                              .read(loginControllerProvider.notifier)
                              .updateShowPassword(
                                showPassword: !authUiModel.showPassword,
                              ),
                        ),
                      ),
                    ),
                    const Gap(10),
                    Row(
                      children: <Widget>[
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: Checkbox(
                            value: authUiModel.rememberMe,
                            onChanged: (bool? value) {
                              ref
                                  .read(loginControllerProvider.notifier)
                                  .updateRememberMe(rememberMe: value ?? false);
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const Gap(5),
                        Text(
                          CoreLocalizations.of(context).authRememberMe,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          style: TextButton.styleFrom(
                            // ignore: use_named_constants since they dont allow constant values
                            minimumSize: const Size(0, 0),
                            // ignore: use_named_constants
                            padding: const EdgeInsets.all(0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            l10n.authCreateAccount,
                            style: const TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          onPressed: () async {
                            await showAdaptiveDialog<void>(
                              context: context,
                              barrierDismissible: true,
                              barrierColor: Colors.black54,
                              builder: (_) {
                                return const RegisterDialog();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const Spacer(flex: 2),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      onPressed: _submit,
                      child: authUiModelAsync.isLoading
                          ? const CircularProgressIndicator()
                          : Text(l10n.authLoginButton),
                    ),
                    const Spacer(flex: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
        error: (Object error, StackTrace stackTrace) {
          return ApiErrorView(
            error: error,
            onRetry: () => ref.invalidate(loginControllerProvider),
          );
        },
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
