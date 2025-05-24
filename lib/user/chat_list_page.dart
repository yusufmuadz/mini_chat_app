
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/user_auth.dart';
import 'chat_room.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> with WidgetsBindingObserver {
  bool isLoading = false, loadDelete = false;
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

  Future<void> deleteAccount(BuildContext context, StateSetter setS) async {
    setS(() {
      loadDelete = true;
    });

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

    setS(() {
      loadDelete = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserOnline(true);
    } else {
      _setUserOnline(false);
    }
  }

  @override
  void dispose() {
    _setUserOnline(false);
    isLoading = false;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _logout() async {
    setState(() {
      isLoading = true;
    });

    await _setUserOnline(false);
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const UserAuth()));
    }
    setState(() {
      isLoading = false;
    });
  }

  popupHapusAkun() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, StateSetter setS) {
            return AlertDialog(
              title: const Text('Hapus Akun'),
              content: const Text('Apakah Anda yakin ingin menghapus akun ini?'),
              actions: loadDelete ? [
                const Center(child: CircularProgressIndicator()),
              ] : [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () {
                    deleteAccount(context, setS);
                  },
                  child: const Text('Hapus'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Admins'),
        actions: isLoading ? [] : [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
          IconButton(onPressed: popupHapusAkun, icon: const Icon(Icons.settings)),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          :
      StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'admin')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final users = snapshot.data!.docs;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data()! as Map<String, dynamic>;
              return InkWell(
                onTap: () {
                  print('User id: ${users[index].id}');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoomPage(
                        recipientId: users[index].id,
                        recipientName: user['name'] ?? 'Tanpa Nama Admin',
                      ),
                    ),
                  );
                },
                child: ListTile(
                  leading: CircleAvatar(child: Text(user['name'] != null ? user['name'][0].toUpperCase() : 'TN')),
                  title: Text(user['name'] ?? 'Tanpa Nama Admin'),
                  subtitle: Text(user['email']),
                  trailing: Icon(Icons.circle, color: user['isOnline'] ? Colors.green : Colors.grey, size: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
