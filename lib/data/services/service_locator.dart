import 'package:flutter/cupertino.dart';
import 'package:get_it/get_it.dart';
import 'package:messenger/data/repository/auth_repository.dart';
import 'package:messenger/data/repository/chat_repository.dart';
import 'package:messenger/data/repository/contact_repository.dart';
import 'package:messenger/firebase_options.dart';
import 'package:messenger/logic/cubit/auth/auth_cubit.dart';
import 'package:messenger/logic/cubit/chat/chat_cubit.dart';
import 'package:messenger/router/app_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /**
   * Only create one instance of the class.
   * But only create it when first needed (lazy).
   * Reuses the same instance every time it’s requested.
   * Whenever you call getIt<FirebaseAuth>(), you'll get the same FirebaseAuth
   * instance (just like a singleton).
   * */
  getIt.registerLazySingleton(() => AppRouter());

  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);

  getIt.registerLazySingleton(() => AuthRepository());
  getIt.registerLazySingleton(() => ContactRepository());
  getIt.registerLazySingleton(() => ChatRepository());

  getIt.registerLazySingleton(
      () => AuthCubit(authRepository: getIt<AuthRepository>())
  );
  getIt.registerFactory(
      () => ChatCubit(
        chatRepository: getIt<ChatRepository>(),
        currentUserId: getIt<FirebaseAuth>().currentUser!.uid
      )
  );
}