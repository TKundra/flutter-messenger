import 'package:messenger/data/model/user_model.dart';
import 'package:messenger/data/services/base_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactRepository extends BaseRepository {
  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? "";

  // Request contact permission
  Future<bool> requestContactPermission() async {
    return await FlutterContacts.requestPermission();
  }

  Future<List<Map<String, dynamic>>> getRegisteredContacts() async {
    try {
      bool hasPermission = await requestContactPermission();
      if (!hasPermission) {
        return [];
      }

      // get device contacts with phone number & profile pic
      final phoneContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true
      );

      // extract phone numbers and normalize them
      final phoneNumbers = phoneContacts.where((contact) => contact.phones.isNotEmpty)
          .map((contact) => contact.phones.first.normalizedNumber)
          .toSet()
          .toList();

      /**
       * get users from firestore
       * NOTE: Firestore 'whereIn' only supports up to 10 elements at once
       * */
      List<UserModel> matchedUsers = [];
      const int batchSize = 10;
      for (int i=0; i<phoneNumbers.length; i += batchSize) {
        final batch = phoneNumbers.sublist(
          i, i+batchSize > phoneNumbers.length ? phoneNumbers.length : i+batchSize
        );

        final querySnapshot = await fireStore.collection("users")
          .where("phoneNumber", whereIn: batch).get();

        if (querySnapshot.docs.isNotEmpty) {
          matchedUsers.addAll(
            querySnapshot.docs.map((doc) => UserModel.fromFireStore(doc))
          );
        }
      }

      // remove your number from the list
      matchedUsers = matchedUsers
          .where((user) => user.uid != currentUserId)
          .toList();

      /**
       * Create map of phone number to contact name for matched contacts
          {
            "1234567890": "Alice",
            "12345678901": "Bob"
          }
       * */
      final contactNameMap = {
        for (var contact in phoneContacts)
          contact.phones.first.normalizedNumber: contact.displayName
      };

      // Map matched users to contact details
      final matchedContacts = matchedUsers.map((user) {
        return {
          'id': user.uid,
          'name': contactNameMap[user.phoneNumber] ?? "",
          'phoneNumber': user.phoneNumber,
        };
      }).toList();

      return matchedContacts;
    } catch (e) {
      return [];
    }
  }
}