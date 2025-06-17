import 'package:flutter/material.dart';
import 'package:messenger/data/repository/auth_repository.dart';
import 'package:messenger/data/repository/chat_repository.dart';
import 'package:messenger/data/repository/contact_repository.dart';
import 'package:messenger/data/services/service_locator.dart';
import 'package:messenger/logic/cubit/auth/auth_cubit.dart';
import 'package:messenger/presentation/chat/chat_screen.dart';
import 'package:messenger/presentation/screen/app_screen.dart';
import 'package:messenger/presentation/widget/chat_list_tile.dart';
import 'package:messenger/router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final ContactRepository _contactRepository;
  late final ChatRepository _chatRepository;
  late final String _currentUserId;

  @override
  void initState() {
    _contactRepository = getIt<ContactRepository>();
    _chatRepository = getIt<ChatRepository>();
    _currentUserId = getIt<AuthRepository>().currentUser?.uid ?? "";
    super.initState();
  }

  void _redirectToChat(String receiverId, String receiverName) {
    getIt<AppRouter>().push(
      ChatScreen(receiverId: receiverId, receiverName: receiverName)
    );
  }

  void _showContactList(BuildContext context) {
    showModalBottomSheet(context: context, builder: (context){
      return Container(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Contacts", style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _contactRepository.getRegisteredContacts(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Error: ${snapshot.error.toString()}"),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final contacts = snapshot.data!;
                    if (contacts.isEmpty) {
                      return Center(
                        child: Text("No Contacts Found!!"),
                      );
                    }

                    return ListView.builder(
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                              child: Text(contact["name"][0].toUpperCase()),
                            ),
                            title: Text(contact["name"]),
                            onTap: () => _redirectToChat(
                              contact["id"],
                              contact["name"]
                            ),
                          );
                        }
                    );
                  }
              ),
            )
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chats"),
        actions: [
          IconButton(
            onPressed: () async {
              await getIt<AuthCubit>().signOut();
              getIt<AppRouter>().pushAndRemoveUntil(const AppScreen());
            },
            icon: Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder(
        // stream added users in chat room
        stream: _chatRepository.getChatRooms(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final chats = snapshot.data!;
          if (chats.isEmpty) {
            return Center(
              child: Text("No recent chats"),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return ChatListTile(
                  chat: chat,
                  currentUserId: _currentUserId,
                  onTap: () {
                    final receiverId = chat.participants.firstWhere(
                        (id) => id != _currentUserId
                    );
                    final receiverName = chat.participantsName?[receiverId] ?? "Unknown";
                    getIt<AppRouter>().push(ChatScreen(
                      receiverId: receiverId,
                      receiverName: receiverName
                    ));
                  }
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactList(context),
        child: Icon(
          Icons.chat,
          color: Colors.white,
        ),
      ),
    );
  }
}
