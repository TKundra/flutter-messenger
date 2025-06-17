import 'dart:developer';

import 'package:messenger/data/model/chat_message.dart';
import 'package:messenger/data/model/chat_room_model.dart';
import 'package:messenger/data/model/user_model.dart';
import 'package:messenger/data/services/base_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRepository extends BaseRepository {
  // reference to collection
  CollectionReference get _chatRooms => fireStore.collection("chatRooms");

  // messages collection inside chatRooms
  CollectionReference getChatRoomMessages(String chatRoomId) {
    return _chatRooms.doc(chatRoomId).collection("messages");
  }

  // get or create room method
  Future<ChatRoomModel> getOrCreateChatRoom(
      String currentUserId,
      String partnerUserId
  ) async {
    /**
     * currentUserId => abc
     * partnerUserId => xyz
     * result will always be "abcxyz", either i initiate the chat or partner
     * */
    final users = [currentUserId, partnerUserId]..sort();
    final roomId = users.join("_");

    // get the chat room
    final roomDocument = await _chatRooms.doc(roomId).get();

    // if room found, return the ChatRoomModel
    if (roomDocument.exists) {
      return ChatRoomModel.fromFireStore(roomDocument);
    }

    // users data
    final currentUserData = (await fireStore.collection("users")
        .doc(currentUserId).get()).data() as Map<String, dynamic>;
    final partnerUserData = (await fireStore.collection("users")
        .doc(partnerUserId).get()).data() as Map<String, dynamic>;

    // create participants map
    final participantsName = {
      currentUserId: currentUserData["fullName"]?.toString() ?? "",
      partnerUserId: partnerUserData["fullName"]?.toString() ?? "",
    };

    // create a room
    final newRoom = ChatRoomModel(
      id: roomId,
      participants: users,
      participantsName: participantsName,
      lastReadTime: {
        currentUserId: Timestamp.now(),
        partnerUserId: Timestamp.now()
      },
    );
    await _chatRooms.doc(roomId).set(newRoom.toMap());

    return newRoom;
  }

  // send message
  Future<void> sendMessage({
    required String chatRoomId,
    required String senderId,
    required String receiverId,
    required String content,
    MessageType type = MessageType.text,
  }) async {
    /**
     * A Firestore batch is used to group multiple write operations (e.g.
     * set,update) into a single atomic transaction — all succeed or none
     * are applied.
     * */
    final batch = fireStore.batch();

    // gets the messages sub-collection for that chat room.
    final messageReference = getChatRoomMessages(chatRoomId);

    // .doc() creates a new message document with a unique auto-ID.
    final messageDoc = messageReference.doc();

    // ChatMessage instance with all relevant details
    final message = ChatMessage(
      id: messageDoc.id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: Timestamp.now(),
      readBy: [senderId],
    );

    // write to add the message to the sub-collection
    batch.set(messageDoc, message.toMap());

    /**
     * updates the parent chat room document to show the latest message details
     * (for displaying chat previews in a list, etc.).
     * */
    batch.update(_chatRooms.doc(chatRoomId), {
      "lastMessage": content,
      "lastMessageSenderId": senderId,
      "lastMessageTime": message.timestamp
    });

    /**
     * Executes all batched operations atomically.
     * If one fails, nothing is written.
     * Ensures data consistency between messages and chat room metadata.
     * */
    await batch.commit();
  }

  // get messages method
  Stream<List<ChatMessage>> getMessages(
    String chatRoomId, {
      DocumentSnapshot? lastDocument
    }
  ) {
    /**
     * First we load first 20 messages order by timestamp,
     * then load more if based on last read document.
     * */
    var query = getChatRoomMessages(chatRoomId)
        .orderBy("timestamp", descending: true)
        .limit(20);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ChatMessage.fromFireStore(doc))
        .toList()
    );
  }

  // get more messages (old messages) method
  Future<List<ChatMessage>> getMoreMessages(
      String chatRoomId,
      DocumentSnapshot lastDocument
  ) async {
    var query = getChatRoomMessages(chatRoomId)
        .orderBy("timestamp", descending: true)
        .startAfterDocument(lastDocument)
        .limit(20);

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ChatMessage.fromFireStore(doc))
        .toList();
  }

  // get users with whom chat recently
  Stream<List<ChatRoomModel>> getChatRooms(String currentUserId) {
    return _chatRooms
        .where("participants", arrayContains: currentUserId)
        .orderBy("lastMessageTime", descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
          .map((doc) => ChatRoomModel.fromFireStore(doc)).toList()
        );
  }

  // unread message counts
  Stream<int> getUnreadMessageCount(
      String userId,
      String chatRoomId
  ) {
    return getChatRoomMessages(chatRoomId)
        .where("receiverId", isEqualTo: userId)
        .where("status", isEqualTo: MessageStatus.sent.toString())
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // mark messages read
  Future<void> markMessageAsRead(
      String userId,
      String chatRoomId
  ) async {
    try {
      // start a batch
      final batch = fireStore.batch();

      // get all unread message, where user is receiver
      final unreadMessages = await getChatRoomMessages(chatRoomId)
          .where("receiverId", isEqualTo: userId)
          .where("status", isEqualTo: MessageStatus.sent.toString()).get();

      // mark those as read
      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([userId]),
          'status': MessageStatus.read.toString()
        });
      }

      // commit changes
      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // user status (online, last seen)
  Stream<Map<String, dynamic>> getUserStatus(String userId) {
    return fireStore.collection("users").doc(userId)
        .snapshots()
        .map((snapshot){
          final data = snapshot.data();
          return {
            'isOnline': data?['isOnline'] ?? false,
            'lastSeen': data?['lastSeen']
          };
      });
  }

  // mark status online, if user opened the chat
  Future<void> updateStatus(String userId, bool isOnline) async {
    await fireStore.collection("users").doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': Timestamp.now()
    });
  }

  // block user
  Future<void> blockUser(
      String currentUserId,
      String userIdToBlock
  ) async {
    final userReference = fireStore.collection("users").doc(currentUserId);
    await userReference.update({
      'blockedUsers': FieldValue.arrayUnion([userIdToBlock])
    });
  }

  // unblock user
  Future<void> unblockUser(
      String currentUserId,
      String userIdToBlock
  ) async {
    final userReference = fireStore.collection("users")
        .doc(currentUserId);
    await userReference.update({
    'blockedUsers': FieldValue.arrayRemove([userIdToBlock])
    });
  }

  // check user is blocked or not
  Stream<bool> isUserBlocked(String currentUserId, String otherUserId) {
    return fireStore.collection("users")
        .doc(currentUserId)
        .snapshots()
        .map((snapshot){
          final userData = UserModel.fromFireStore(snapshot);
          return userData.blockedUsers.contains(otherUserId);
        });
  }

  // check am i blocked or not
  Stream<bool> amIBlocked(String currentUserId, String otherUserId) {
    return fireStore.collection("users")
        .doc(otherUserId)
        .snapshots()
        .map((snapshot){
      final userData = UserModel.fromFireStore(snapshot);
      return userData.blockedUsers.contains(currentUserId);
    });
  }

  // user typing status
  Stream<Map<String, dynamic>> getUserTypingStatus(String chatRoomId) {
    return _chatRooms.doc(chatRoomId)
        .snapshots()
        .map((snapshot){
          if (!snapshot.exists) {
            return {
              'isTyping': false,
              'typingUserId': null
            };
          }

          final data = snapshot.data() as Map<String, dynamic>;
          return {
            'isTyping': data['isTyping'] ?? false,
            'typingUserId': data['typingUserId']
          };
      });
  }

  Future<void> updateTypingStatus(
    String chatRoomId, String userId, bool isTyping
  ) async {
    try {
      final doc = await _chatRooms.doc(chatRoomId).get();
      if (!doc.exists) return;

      await _chatRooms.doc(chatRoomId).update({
        'isTyping': isTyping,
        'typingUserId': isTyping ? userId : null
      });
    } catch (e) {}
  }
}