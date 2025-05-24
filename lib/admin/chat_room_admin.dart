
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatRoomAdmin extends StatefulWidget {
  final String userId, name;
  const ChatRoomAdmin({super.key, required this.userId, required this.name});

  @override
  State<ChatRoomAdmin> createState() => _ChatRoomAdminState();
}

class _ChatRoomAdminState extends State<ChatRoomAdmin> {
  final TextEditingController _controller = TextEditingController();
  final admin = FirebaseAuth.instance.currentUser!;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.userId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': admin.uid,
      "receiverId": widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chat with ${widget.name}")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.userId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return SizedBox(height: 50, width: 50, child: const CircularProgressIndicator());

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isAdmin = data['senderId'] == admin.uid;

                    return Align(
                      alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? Colors.green : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(data['text']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration:
                      const InputDecoration(hintText: "Ketik balasan..."),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: _sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }
}
