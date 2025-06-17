import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:messenger/data/model/user_model.dart';
import 'package:messenger/data/services/base_repository.dart';
import 'package:messenger/core/utils/utils.dart';

class AuthRepository extends BaseRepository {
  // getter of auth state changes, return streams that caller can listen to
  /*
  * it continuously listens for changes in authentication.
  * Firebase emits an event every time auth state changes:
  * Examples of when it will trigger:
     * User signs in
     * User signs out
     * User's session expires
     * User is deleted
     * Firebase detects token refresh
  * **/
  Stream<User?> get authStateChanges => auth.authStateChanges();

  // sign-up method
  Future<UserModel> signUp({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String phoneNumber
  }) async {
    try {
      // check if email already exists
      final isEmailExists = await checkEmailExists(email);
      if (isEmailExists) {
        throw "An account with same email already exists";
      }

      // check if phone number already exists
      final isPhoneNumberExists = await checkPhoneNumberExists(phoneNumber);
      if (isPhoneNumberExists) {
        throw "Phone number already exists";
      }

      // create user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password
      );
      if (userCredential.user == null) {
        throw "Failed to create user";
      }

      // create a user model and save user in db (fire-store)
      final user = UserModel(
        uid: userCredential.user!.uid,
        username: username,
        email: email,
        fullName: fullName,
        phoneNumber: Utils.formattedPhoneNumber(phoneNumber)
      );

      // save user
      await saveUserData(user);

      return user;
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  // sign-in method
  Future<UserModel> signIn({
    required String email,
    required String password
  }) async {
    try {
      // get user using email & password
      final userCredential = await auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      // if not found, throw error user not found
      if (userCredential.user == null) {
        throw "User not found!!";
      }

      // return user model
      return getUserData(userCredential.user!.uid);
    } catch (e) {
      rethrow;
    }
  }

  // method to save user in db (fire-store)
  Future<void> saveUserData(UserModel user) async {
    /**
     * save user to collection (users)
     * using id (uid)
     * set user data as map to collection as doc
     * */
    await fireStore.collection("users").doc(user.uid).set(user.toMap());
  }

  // get user from db (fire-store)
  Future<UserModel> getUserData(String uid) async {
    try {
      // get doc from users collection using uid
      final doc = await fireStore.collection("users").doc(uid).get();
      if (!doc.exists) {
        throw "User data not found";
      }

      // return the user model
      return UserModel.fromFireStore(doc);
    } catch (e) {
      log(e.toString());
      throw "Failed to get user data";
    }
  }

  // sign-out logged-in user
  Future<void> signOut() async {
    await auth.signOut();
  }

  // util function to check email already exists or not
  Future<bool> checkEmailExists(String email) async {
    try {
      final methods = await auth.fetchSignInMethodsForEmail(email);
      return methods.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // util function to check phone number already exists or not
  Future<bool> checkPhoneNumberExists(String phoneNumber) async {
    try {
      final querySnapshot = await fireStore.collection("users").where(
        "phoneNumber", isEqualTo: Utils.formattedPhoneNumber(phoneNumber)
      ).get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}