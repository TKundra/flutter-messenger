import 'dart:developer';

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:messenger/core/utils/message_bubble.dart';
import 'package:messenger/data/model/chat_message.dart';
import 'package:messenger/data/services/service_locator.dart';
import 'package:messenger/logic/cubit/chat/chat_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger/logic/cubit/chat/chat_state.dart';
import 'package:messenger/presentation/widget/loading_dots.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  late final ChatCubit _chatCubit;
  final _scrollController = ScrollController();
  List<ChatMessage> _previousMessages = [];

  bool _isComposing = false;

  @override
  void initState() {
    // enter in chat and start listening to streams
    _chatCubit = getIt<ChatCubit>();
    _chatCubit.enterChat(widget.receiverId);

    // add listeners to textField for any change happened to messages
    _messageController.addListener(_onTextChange);
    _scrollController.addListener(_onScroll);

    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatCubit.leaveChat();
    _scrollController.dispose();
    super.dispose();
  }

  // on scrolling if we are almost near to top, load more messages
  void _onScroll() {
    // load more messages when we reach the top while scrolling
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent-200) {
      _chatCubit.loadMoreMessages();
    }
  }

  /*
  * 1. Store message
  * 2. Clear the textField
  * 3. send message
  * **/
  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    _messageController.clear();

    if (message.isNotEmpty) {
      _chatCubit.sendMessage(
          content: message,
          receiverId: widget.receiverId
      );
    }
  }

  // on text change mark user typing
  void _onTextChange() {
    final isComposing = _messageController.text.isNotEmpty;
    if (isComposing != _isComposing) {
      setState(() {
        _isComposing != isComposing;
      });
      if (isComposing) {
        _chatCubit.startTyping();
      }
    }
  }

  // auto-scroll to bottom with animation
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0, duration: Duration(milliseconds: 300), curve: Curves.easeOut
      );
    }
  }

  /*
  * check if current messages length != already stored messages (conditional listening,)
  * if yes, scroll to bottom & update _previous messages
  * **/
  void _hasNewMessages(List<ChatMessage> messages) {
    if (messages.length != _previousMessages.length) {
      _scrollToBottom();

      _previousMessages = messages;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Text(widget.receiverName[0].toUpperCase()),
            ),
            SizedBox(
              width: 12,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.receiverName),
                BlocBuilder<ChatCubit, ChatState>(
                  bloc: _chatCubit,
                  builder: (context, state) {
                    if (state.isReceiverTyping) {
                      return Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 4),
                            child: const LoadingDots(),
                          ),
                          Text("typing", style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).primaryColor
                          ),)
                        ],
                      );
                    }

                    if (state.isReceiverOnline) {
                      return Text("Online", style: TextStyle(
                          fontSize: 10,
                          color: Colors.green
                      ),);
                    }

                    if (state.receiverLastSeen != null) {
                      final lastSeen = state.receiverLastSeen!.toDate();
                      return Text(
                        "last seen at ${DateFormat('h:mm a').format(lastSeen)}",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600]
                      ),);
                    }

                    return SizedBox();
                  },
                )
              ],
            )
          ],
        ),
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            bloc: _chatCubit,
            builder: (context, state) {
              if (state.isUserBlocked) {
                return TextButton.icon(
                  label: const Text("Unblock"),
                  icon: const Icon(Icons.block),
                  onPressed: () => _chatCubit.unblockUser(widget.receiverId),
                );
              }

              return PopupMenuButton<String>(
                icon: Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == "block") {
                    final bool? confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Block"),
                          iconColor: Colors.red,
                          icon: Icon(Icons.block,),
                          content: Text("Are tou sure you want to block ${widget.receiverName}"),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context, true);
                              },
                              child: Text("Block", style: TextStyle(
                                color: Colors.red
                              ),),
                            ),
                          ],
                        )
                    );

                    if (confirm == true) {
                      await _chatCubit.blockUser(widget.receiverId);
                    }
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem(
                    value:"block",
                    child: Text("Block"),
                  )
                ],
              );
            },
          )
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state.isLoadingMore) {
              log("loading more messages...");
            }
            _hasNewMessages(state.messages);
          },
          bloc: _chatCubit,
          builder: (context, state) {
            if (state.status == ChatStatus.loading) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (state.error == ChatStatus.error) {
              return Center(
                child: Text(state.error.toString()),
              );
            }

            return Column(
              children: [
                if (state.amIBlocked)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.red.withOpacity(0.1),
                    child: Text(
                      "You have been blocked by ${widget.receiverName}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                      reverse: true,
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        final message = state.messages[index];
                        bool isMe = message.senderId == _chatCubit.currentUserId;
                        return MessageBubble(
                            chatMessage: message,
                            isMe: isMe
                        );
                      }
                  ),
                ),
                if (!state.amIBlocked && !state.isUserBlocked) ...[
                  SizedBox(height: 10,),
                  Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: Icon(
                                Icons.emoji_emotions_outlined,
                                color: Theme.of(context).primaryColor
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              controller: _messageController,
                              decoration: InputDecoration(
                                  hintText: "Type a message...",
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8
                                  ),
                                  fillColor: Theme.of(context).cardColor
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _sendMessage,
                            icon: Icon(
                                Icons.send,
                                color: Theme.of(context).primaryColor
                            ),
                          )
                        ],
                      ),
                    ],
                  )
                ]
              ],
            );
          }
        )
      ),
    );
  }
}
