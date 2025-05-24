
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatRoomPage extends StatefulWidget {
  final String recipientId;
  final String recipientName;

  const ChatRoomPage({
    super.key,
    required this.recipientId,
    required this.recipientName,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  bool isLoading = false;
  String roomId = '', role = '';
  final TextEditingController _controller = TextEditingController();
  final currentUser = FirebaseAuth.instance.currentUser!;

  getroomId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      role = prefs.getString('role')!;
      if (prefs.getString('role') == 'admin') {
        roomId = widget.recipientId;
      } else {
        roomId = prefs.getString('uidUser')!;
      }
    });
  }

  Future<void> _sendMessage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final text = _controller.text.trim();
      if (text.isEmpty) return;

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .add({
        'senderId': currentUser.uid,
        "receiverId": '',
        'text': _controller.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        _controller.clear();
      });
    } catch (e) {
      print('Error sending message: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getroomId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'admin' ? 'Admin  ->  ${widget.recipientName}' : '${widget.recipientName}  ->  Admin'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(roomId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container(height: 50, width: 50, alignment: Alignment.center, child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data()! as Map<String, dynamic>;
                    final isMe = data['senderId'] == currentUser.uid;
                    final senderName = isMe ? "Saya" : widget.recipientName;

                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    final timeStr = DateFormat.Hm().format(timestamp);

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            senderName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey[300],
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(12),
                                topRight: const Radius.circular(12),
                                bottomLeft:
                                    isMe ? const Radius.circular(12) : const Radius.circular(0),
                                bottomRight:
                                    isMe ? const Radius.circular(0) : const Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              data['text'] ?? '',
                              style: TextStyle(
                                color: isMe ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            timeStr,
                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 10, 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                    ),
                  ),
                ),
                IconButton(
                  icon: isLoading ? SizedBox(height: 20, width: 20, child: const CircularProgressIndicator(strokeWidth: 3,)) : Icon(Icons.send),
                  onPressed: isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
