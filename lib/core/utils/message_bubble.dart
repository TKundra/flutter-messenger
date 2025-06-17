import 'package:flutter/material.dart';
import 'package:messenger/data/model/chat_message.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage chatMessage;
  final bool isMe;
  // final bool showTime;

  const MessageBubble({
    super.key,
    required this.chatMessage,
    required this.isMe,
    // required this.showTime
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8
        ),
        decoration: BoxDecoration(
          color: isMe ?
            Theme.of(context).primaryColor :
            Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8: 64,
          bottom: 4
        ),
        child: Column(
          crossAxisAlignment: isMe ?
            CrossAxisAlignment.end :
            CrossAxisAlignment.start,
          children: [
            Text(chatMessage.content, style: TextStyle(
              color: isMe ? Colors.white : Colors.black,
            ),),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(DateFormat('h:mm a').format(chatMessage.timestamp.toDate()),
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                    fontSize: 10
                  ),
                ),
                if (isMe) ...[
                  SizedBox(
                    width: 8,
                  ),
                  Icon(
                    Icons.done_all,
                    size: 15,
                    color: chatMessage.status == MessageStatus.read ? Colors.green : Colors.white,
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }
}