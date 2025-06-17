import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:messenger/data/repository/chat_repository.dart';
import 'package:messenger/logic/cubit/chat/chat_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatCubit extends Cubit<ChatState> {
  final ChatRepository _chatRepository;
  final String currentUserId;

  /// to check partner already in chat or not - help to mark messages as read
  bool _isAlreadyInChat = false;

  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _blockStatusSubscription;
  StreamSubscription? _amIBlockStatusSubscription;

  Timer? typingTimer;

  ChatCubit({
    required ChatRepository chatRepository,
    required this.currentUserId
  }) : _chatRepository = chatRepository, super(const ChatState());

  // enter a room method
  void enterChat(String receiverId) async {
    _isAlreadyInChat = true;

    // update status as loading
    emit(state.copyWith(status: ChatStatus.loading));

    try {
      // get or create room
      final chatRoom = await _chatRepository
          .getOrCreateChatRoom(currentUserId, receiverId);

      // update state with details
      emit(state.copyWith(
        status: ChatStatus.loaded,
        chatRoomId: chatRoom.id,
        receiverId: receiverId,
      ));

      // subscribe to messages
      _subscribeToMessages(chatRoom.id);

      // subscribe to receiver status
      _subscribeToStatus(receiverId);

      // subscribe to user typing status
      _subscribeToTypingStatus(chatRoom.id);

      // subscribe to block status
      _subscribeToBlockStatus(receiverId);

      // update current user status - online/offline
      await _chatRepository.updateStatus(currentUserId, true);
    } catch (e) {
      log("Error while entering the chat: ${e.toString()}");
      emit(state.copyWith(
        status: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  // send message method
  void sendMessage({
    required String content,
    required String receiverId
  }) async {
    if (state.chatRoomId == null) return;

    try {
      await _chatRepository.sendMessage(
        chatRoomId: state.chatRoomId!,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content
      );
    } catch (e) {
      log("Error while sending message: ${e.toString()}");
      emit(state.copyWith(
        status: ChatStatus.error,
        error: e.toString(),
      ));
    }
  }

  // subscribe to messages (for new messages)
  void _subscribeToMessages(String chatRoomId) {
    _messageSubscription?.cancel();
    _messageSubscription = _chatRepository.getMessages(chatRoomId).listen((messages){

      // if current user already in chat, mark messages as read
      if (_isAlreadyInChat) {
        _markMessagesAsRead(chatRoomId);
      }

      emit(state.copyWith(
        messages: messages,
        error: null
      ));
    }, onError: (error){
      emit(state.copyWith(
        error: "Failed to load messages",
        status: ChatStatus.error
      ));
    });
  }

  // mark messages as read
  Future<void> _markMessagesAsRead(String chatRoomId) async {
    try {
      await _chatRepository.markMessageAsRead(
        currentUserId,
        chatRoomId
      );
    } catch (e) {
      log("Error while mark read: ${e.toString()}");
    }
  }

  // is user left the chat room
  Future<void> leaveChat() async {
    _isAlreadyInChat = false;
  }

  // get user online/offline
  void _subscribeToStatus(String userId) {
    _statusSubscription?.cancel();

    _statusSubscription = _chatRepository.getUserStatus(userId).listen((data){
      final isOnline = data['isOnline'] as bool;
      final lastSeen = data['lastSeen'] as Timestamp?;

      emit(state.copyWith(
        isReceiverOnline: isOnline,
        receiverLastSeen: lastSeen
      ));
    }, onError: (error){
      emit(state.copyWith(
        status: ChatStatus.error,
        error: error.toString()
      ));
    });
  }

  // block user method
  Future<void> blockUser(String userId) async {
    try {
      await _chatRepository.blockUser(currentUserId, userId);
    } catch (e) {
      emit(state.copyWith(
          status: ChatStatus.error,
          error: "Failed to block user"
      ));
    }
  }

  // subscribe to block status
  void _subscribeToBlockStatus(String otherUserId) {
    _blockStatusSubscription?.cancel();

    /**
     * keep listening to update status, for block.
     * We have stored blockedUsers & amIBlocked in state.
     * So on any update from stream trigger a state update.
     * */
    _blockStatusSubscription = _chatRepository
        .isUserBlocked(currentUserId, otherUserId)
        .listen((isBlocked) {
          emit(state.copyWith(
              isUserBlocked: isBlocked
          ));

          _amIBlockStatusSubscription?.cancel();
          _amIBlockStatusSubscription = _chatRepository.amIBlocked(currentUserId, otherUserId)
          .listen((isBlocked) {
            emit(state.copyWith(
                amIBlocked: isBlocked
            ));
          });
    }, onError: (error){
      emit(state.copyWith(
          status: ChatStatus.error,
          error: error.toString()
      ));
    });
  }

  // unblock user method
  Future<void> unblockUser(String userId) async {
    try {
      await _chatRepository.unblockUser(currentUserId, userId);
    } catch (e) {
      emit(state.copyWith(
          status: ChatStatus.error,
          error: "Failed to unblock user"
      ));
    }
  }

  // load more messages
  Future<void> loadMoreMessages() async {
    if (state.status != ChatStatus.loaded ||
        state.messages.isEmpty ||
        !state.hasMoreMessages ||
        state.isLoadingMore
    ) return;

    try {
      emit(state.copyWith(isLoadingMore:  true));

      // get the last stored message
      final lastMessage = state.messages.last;

      // get the last message doc from firestore
      final lastDocument = await _chatRepository
          .getChatRoomMessages(state.chatRoomId!).doc(lastMessage.id).get();

      // using that last message, load more docs that come after that doc
      final moreMessages = await _chatRepository
          .getMoreMessages(state.chatRoomId!, lastDocument);

      // if there is no more messages, just mark the state no more messages are in DB
      if (moreMessages.isEmpty) {
        emit(state.copyWith(
          hasMoreMessages: false,
          isLoadingMore: false
        ));
        return;
      }

      // update state, and merge fetched messages with loaded messages
      // again check for limit and update hasMoreMessages could be fetched later or not
      emit(state.copyWith(
        messages: [...state.messages, ...moreMessages],
        hasMoreMessages: moreMessages.length >= 20,
        isLoadingMore: false
      ));
    } catch (e) {
      emit(state.copyWith(
          status: ChatStatus.error,
          isLoadingMore: false,
          error: "Failed to load more messages"
      ));
    }
  }

  // get user typing status
  void _subscribeToTypingStatus(String chatRoomId) {
    _typingSubscription?.cancel();

    _typingSubscription = _chatRepository.getUserTypingStatus(chatRoomId).listen((data){
      final isTyping = data['isTyping'] as bool;
      final typingUserId = data['typingUserId'] as String?;

      emit(state.copyWith(
          isReceiverTyping: isTyping && typingUserId != currentUserId
      ));
    }, onError: (error){
      emit(state.copyWith(
          status: ChatStatus.error,
          error: error.toString()
      ));
    });
  }

  void startTyping() {
    if (state.chatRoomId == null) return;
    typingTimer?.cancel();

    _updateTypingStatus(true);

    typingTimer = Timer(Duration(seconds: 3), (){
      _updateTypingStatus(false);
    });
  }

  Future<void> _updateTypingStatus(bool isTyping) async {
    if (state.chatRoomId == null) return;
    try {
      await _chatRepository.updateTypingStatus(
          state.chatRoomId!, currentUserId, isTyping
      );
    } catch (e) {}
  }
}