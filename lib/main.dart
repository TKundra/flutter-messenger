import 'package:flutter/material.dart';
import 'package:messenger/config/theme/app_theme.dart';
import 'package:messenger/data/repository/chat_repository.dart';
import 'package:messenger/data/services/service_locator.dart';
import 'package:messenger/logic/cubit/auth/auth_cubit.dart';
import 'package:messenger/logic/cubit/auth/auth_state.dart';
import 'package:messenger/logic/observer/app_lifecycle_observer.dart';
import 'package:messenger/presentation/screen/app_screen.dart';
import 'package:messenger/router/app_router.dart';

void main() async {
  await setupServiceLocator();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLifeCycleObserver _appLifeCycleObserver;

  @override
  void initState() {
    getIt<AuthCubit>().stream.listen((state){
      if (state.status == AuthStatus.authenticated && state.user != null) {
        _appLifeCycleObserver = AppLifeCycleObserver(
          userId: state.user!.uid,
          chatRepository: getIt<ChatRepository>()
        );
        WidgetsBinding.instance.addObserver(_appLifeCycleObserver);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_appLifeCycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /**
     * Wrapping MaterialApp inside gestureDetector, enables gesture handling.
     * Example - When the user taps anywhere outside an input field (like a
     * TextField), the GestureDetector captures that tap and tells Flutter to
     * remove focus from any currently focused widget. That will dismiss the
     * keyboard.
     * */
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        navigatorKey: getIt<AppRouter>().navigatorKey,
        home: const AppScreen(),
      ),
    );
  }
}
