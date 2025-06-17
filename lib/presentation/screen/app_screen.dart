import 'package:flutter/material.dart';
import 'package:messenger/core/utils/ui_utils.dart';
import 'package:messenger/data/services/service_locator.dart';
import 'package:messenger/logic/cubit/auth/auth_cubit.dart';
import 'package:messenger/logic/cubit/auth/auth_state.dart';
import 'package:messenger/presentation/home/home_screen.dart';
import 'package:messenger/presentation/screen/auth/login_screen.dart';
import 'package:messenger/router/app_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  // @override
  // void dispose() {
  //   // close subscription to firebase
  //   getIt<AuthCubit>().close();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    /**
     * As we have initialized the AuthCubit, singleton class get generated
     * and constructor get called. Due to which we subscribed to authStateChanges.
     * Whenever changes occurred like user deleted, etc. Our app listening to
     * and emit changes to state accordingly.
     * */
    return BlocConsumer<AuthCubit, AuthState>(
      bloc: getIt<AuthCubit>(),
      listener: (context, state) {
        if (state.status == AuthStatus.authenticated) {
          getIt<AppRouter>().pushAndRemoveUntil(const HomeScreen());
        } else if (state.error != null && state.status == AuthStatus.error) {
          UiUtils.showSnackBar(
            context,
            message: state.error.toString(),
            isError: true
          );
        }
      },
      builder: (context, state) {
        if (
          state.status == AuthStatus.initial ||
          state.status == AuthStatus.loading
        ) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return LoginScreen();
      },
    );
  }
}
