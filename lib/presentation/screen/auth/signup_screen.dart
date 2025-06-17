import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/core/common/custom_button.dart';
import 'package:messenger/core/common/custom_text_field.dart';
import 'package:messenger/data/services/service_locator.dart';
import 'package:messenger/logic/cubit/auth/auth_cubit.dart';
import 'package:messenger/presentation/screen/auth/validators/form_field_validators.dart';
import 'package:messenger/router/app_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // form key for validation
  final _formKey = GlobalKey<FormState>();

  // input controller
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // password visibility
  bool _isPasswordVisible = false;

  // focus input
  final _nameFocus = FocusNode();
  final _userNameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _phoneFocus = FocusNode();

  @override
  void dispose() {
    super.dispose();

    // input controller dispose
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _userNameController.dispose();
    _phoneController.dispose();

    // focus input dispose
    _nameFocus.dispose();
    _userNameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _phoneFocus.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      _nameFocus.unfocus();
      _userNameFocus.unfocus();
      _emailFocus.unfocus();
      _passwordFocus.unfocus();
      _phoneFocus.unfocus();

      await getIt<AuthCubit>().signUp(
        fullName: _nameController.text,
        userName: _userNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Create Account",
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                    "Please fill in the details to continue",
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.grey)
                ),
                const SizedBox(
                  height: 30,
                ),
                CustomTextField(
                  hintText: "Full Name",
                  validator: FormFieldValidators.validateName,
                  focusNode: _nameFocus,
                  controller: _nameController,
                  prefixIcon: const Icon(Icons.person_outline),
                    onFieldSubmitted: (_) {
                      // shift focus on enter press
                      FocusScope.of(context).requestFocus(_userNameFocus);
                    }
                ),
                const SizedBox(
                  height: 16,
                ),
                CustomTextField(
                  hintText: "Username",
                  validator: FormFieldValidators.validateUserName,
                  focusNode: _userNameFocus,
                  controller: _userNameController,
                  prefixIcon: const Icon(Icons.alternate_email),
                    onFieldSubmitted: (_) {
                      // shift focus on enter press
                      FocusScope.of(context).requestFocus(_emailFocus);
                    }
                ),
                const SizedBox(
                  height: 16,
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
                    onFieldSubmitted: (_) {
                      // shift focus on enter press
                      FocusScope.of(context).requestFocus(_phoneFocus);
                    },
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
                  height: 16,
                ),
                CustomTextField(
                  hintText: "Phone Number",
                  validator: FormFieldValidators.validatePhone,
                  focusNode: _phoneFocus,
                  controller: _phoneController,
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
                const SizedBox(
                  height: 30,
                ),
                CustomButton(
                  onPressed: _submitForm,
                  text: "Sign Up",
                ),
                const SizedBox(
                  height: 20,
                ),
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: "Already have an account?  ",
                      style: TextStyle(color: Colors.grey[600]),
                      children: [
                        TextSpan(
                          text: "Login",
                          style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold
                          ),
                          recognizer: TapGestureRecognizer()..onTap=(){
                            getIt<AppRouter>().pop();
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
      )
    );
  }
}
