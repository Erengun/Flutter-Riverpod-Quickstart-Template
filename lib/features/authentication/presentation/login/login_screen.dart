import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../constants/assets.dart';
import '../../../../router/app_router.dart';
import '../../domain/login_response.dart';
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

  @override
  Widget build(BuildContext context) {
    final AuthUiModel authUiModel = ref.watch(
      loginControllerProvider,
    ); // Access the state
    ref.listen(loginControllerProvider, (
      AuthUiModel? previous,
      AuthUiModel next,
    ) {
      if (next.user != null) {
        _emailController.text = next.user!.email;
        _passwordController.text = next.user!.password;
      }
    });
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Login'),
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
      body: SafeArea(
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
                      'Welcome to the app',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const Gap(10),
                  const Text(
                    'You can login with your email and password',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
                  ),
                  const Spacer(),
                  const Text(
                    'Login',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
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
                        return 'Please enter an email address';
                      }
                      // Regex for validating email format
                      final RegExp emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(value)) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      hintText: 'Enter your email',
                      hintStyle: TextStyle(color: Colors.black54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                  const Gap(15),
                  const Text(
                    'Password',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !authUiModel.showPassword,
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
                    onFieldSubmitted: (String value) {
                      FocusScope.of(context).unfocus();
                      ref
                          .read(loginControllerProvider.notifier)
                          .login(
                            email: _emailController.text,
                            password: _passwordController.text,
                          );
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 15,
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(color: Colors.black54),
                      suffixIcon: IconButton(
                        icon: Icon(
                          authUiModel.showPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => ref
                            .read(loginControllerProvider.notifier)
                            .updateShowPassword(!authUiModel.showPassword),
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
                                .updateRememberMe(value ?? false);
                          },
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const Gap(5),
                      const Text(
                        'Remember me',
                        style: TextStyle(
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
                        child: const Text(
                          'Create an account',
                          style: TextStyle(
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
                    onPressed: () {
                      ref
                          .read(loginControllerProvider.notifier)
                          .login(
                            email: _emailController.text,
                            password: _passwordController.text,
                          )
                          .catchError((dynamic error, StackTrace stackTrace) {
                            // Handle error here
                            if (context.mounted) {
                              // Show error message to the user
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(error.toString())),
                              );
                            }
                            return const LoginResponse(token: '');
                          })
                          .then((LoginResponse loginResponse) {
                            // Check for token and also context.mounted
                            // to avoid context access after dispose
                            if (loginResponse.token.isNotEmpty &&
                                context.mounted) {
                              // Handle successful login
                              context.push(SGRoute.home.route);
                            }
                          });
                    },
                    child: authUiModel.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Login'),
                  ),
                  const Spacer(flex: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
