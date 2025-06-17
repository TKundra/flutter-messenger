import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/core/common/custom_button.dart';
import 'package:messenger/core/common/custom_text_field.dart';
import 'package:messenger/data/services/service_locator.dart';
import 'package:messenger/logic/cubit/auth/auth_cubit.dart';
import 'package:messenger/presentation/screen/auth/signup_screen.dart';
import 'package:messenger/presentation/screen/auth/validators/form_field_validators.dart';
import 'package:messenger/router/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // form key for validation
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // password visibility
  bool _isPasswordVisible = false;

  // focus input
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    super.dispose();
    // input controller dispose
    _emailController.dispose();
    _passwordController.dispose();

    // focus input dispose
    _emailFocus.dispose();
    _passwordFocus.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _emailFocus.unfocus();
      _passwordFocus.unfocus();

      await getIt<AuthCubit>().signIn(
        email: _emailController.text,
        password: _passwordController.text
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  height: 50,
                ),
                Text(
                  "Welcome Back",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text("Sign in to continue",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey)),
                const SizedBox(
                  height: 30,
                ),
                CustomTextField(
                  hintText: "Email",
                  validator: FormFieldValidators.validateEmail,
                  focusNode: _emailFocus,
                  controller: _emailController,
                  prefixIcon: const Icon(Icons.email_outlined),
                  onFieldSubmitted: (_) {
                    // shift focus on enter press
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  }
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomTextField(
                  hintText: "Password",
                  validator: FormFieldValidators.validatePassword,
                  focusNode: _passwordFocus,
                  controller: _passwordController,
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: !_isPasswordVisible,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    child: _isPasswordVisible ?
                    const Icon(Icons.visibility_outlined) :
                    const Icon(Icons.visibility_off_outlined),
                  ),
                ),
                const SizedBox(
                  height: 30,
                ),
                CustomButton(
                  onPressed: _submitForm,
                  text: "Login",
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Don't have an account?  ",
                      style: TextStyle(color: Colors.grey[600]),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = () {
                            getIt<AppRouter>().push(const SignupScreen());
                          }
                        )
                      ]
                    ),
                  ),
                )
              ],
            ),
        )
      ),
    );
  }
}
