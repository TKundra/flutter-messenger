import 'dart:async';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger/data/repository/auth_repository.dart';
import 'package:messenger/logic/cubit/auth/auth_state.dart';

/// emit: updates the state as well as notify the listeners

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  /// Constructor
  /// 1. get authRepository instance, then initialize it to _authRepository
  /// 2. call super to pass initial state
  /// 3. call _init()
  AuthCubit({
    required AuthRepository authRepository,
  })  : _authRepository = authRepository, super(const AuthState()) {
    _init();
  }

  @override
  Future<void> close() {
    log("===========================> “❌” Firebase Connection closed!!");
    _authStateSubscription?.cancel();
    return super.close();
  }

  void _init() {
    log("===========================> “✅” Firebase Connection established!!");

    // set state's status initial
    emit(state.copyWith(status: AuthStatus.initial));

    // listen to authStateChanges stream for changes
    _authStateSubscription = _authRepository.authStateChanges.listen((user) async {
      if (user != null) {
        try {
          // if user exists, get their details from (fire-store)
          final userData = await _authRepository.getUserData(user.uid);

          // update state authenticated & store user details
          emit(state.copyWith(
            status: AuthStatus.authenticated,
            user: userData
          ));
        } catch (e) {
          emit(state.copyWith(error: e.toString(), status: AuthStatus.error));
        }
      } else {
        // if user not found, mark state unauthenticated
        emit(state.copyWith(status: AuthStatus.unauthenticated));
      }
    });
  }

  // sign-in method
  Future<void> signIn({
    required String email,
    required String password
  }) async {
    try {
      // set status loading
      emit(state.copyWith(status: AuthStatus.loading));

      // sign in the user
      final user = await _authRepository.signIn(
        email: email,
        password: password
      );

      // update the state
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        status: AuthStatus.error
      ));
    }
  }

  // sign-up method
  Future<void> signUp({
    required String email,
    required String password,
    required String userName,
    required String phoneNumber,
    required String fullName
  }) async {
    try {
      // set status loading
      emit(state.copyWith(status: AuthStatus.loading));

      // sign-up the user
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        username: userName,
        fullName: fullName
      );

      // update the state
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        error: null
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        status: AuthStatus.error
      ));
    }
  }

  // sign-out
  Future<void> signOut() async {
    try {
      // sign out user
      await _authRepository.signOut();

      // update the state
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null
      ));
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        status: AuthStatus.error
      ));
    }
  }
}