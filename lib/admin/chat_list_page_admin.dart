
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mini_chat_app/user/chat_room.dart';

import '../auth/user_auth.dart';
import 'chat_room_admin.dart';

class AdminChatListPage extends StatefulWidget {
  @override
  State<AdminChatListPage> createState() => _AdminChatListPageState();
}

class _AdminChatListPageState extends State<AdminChatListPage> with WidgetsBindingObserver {
  // Dummy list fallback jika Firestore kosong
  final List<Map<String, dynamic>> dummyUsers = [
    {'name': 'Dummy Budi', 'online': true},
    {'name': 'Dummy Sari', 'online': false},
    {'name': 'Dummy Rian', 'online': true},
  ];

  final uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline(true);
  }

  Future<void> _setUserOnline(bool online) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAccount(BuildContext context) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) return;

      final uid = user.uid;

      // 1. Hapus data dari Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).delete();
      await FirebaseFirestore.instance.collection('chats').doc(uid).delete();

      // 2. Hapus akun dari Firebase Auth
      await user.delete();

      // 3. Arahkan ke halaman login
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAuth()));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAuth()));
        // User harus login ulang sebelum menghapus akunnya
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login ulang untuk menghapus akun.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal hapus akun: ${e.message}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _setUserOnline(false);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _logout() async {
    await _setUserOnline(false);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAuth()));
    }
  }

  popupHapusAkun() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus Akun'),
          content: const Text('Apakah Anda yakin ingin menghapus akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                deleteAccount(context);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Chat Page'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          IconButton(onPressed: popupHapusAkun, icon: const Icon(Icons.settings)),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'user')
            .snapshots(),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> userList = [];

          if (snapshot.hasData && snapshot.data != null) {
            final docs = snapshot.data!.docs;

            userList = docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'name': data['name'] ?? 'Tanpa Nama',
                'online': data['isOnline'] ?? false,
                'uid': data['uid'] ?? '',
              };
            }).toList();

            // Jika Firestore kosong, gunakan dummy
            if (userList.isEmpty) {
              userList = dummyUsers;
            } else {
              // Tambahkan dummy di bawah data Firestore (opsional)
              userList.addAll(dummyUsers);
            }
          } else if (snapshot.hasError || snapshot.connectionState == ConnectionState.done) {
            // Error atau selesai, fallback dummy
            userList = dummyUsers;
          }

          return _buildList(userList);
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> users) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
                  leading: CircleAvatar(child: Text(user['name'][0].toUpperCase())),
                    title: Text(user['name']),
                    // subtitle: Text("ID: $userId"),
                    trailing: Text(
                      user['online'] ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: user['online'] ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoomPage(recipientId: '${user['uid'] ?? 'dummy'}', recipientName: user['name'] ?? 'Tanpa Nama'),
                        ),
                      );
                    },
                  );
      },
    );
  }
}
