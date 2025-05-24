
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/chat_list_page_admin.dart';
import '../user/chat_list_page.dart';

class UserAuth extends StatefulWidget {
  const UserAuth({super.key});

  @override
  State<UserAuth> createState() => _UserAuthState();
}

class _UserAuthState extends State<UserAuth> {

  bool login = true, showPassword = false, isLoading = false;
  String role = 'user';
  final formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    setState(() {
      isLoading = true;
    });
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user!;
      String? token = await FirebaseMessaging.instance.getToken();
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'name': user.displayName,
        'isOnline': true,
        'role': userDoc.data()?['role'],
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));

      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        prefs.setString('role', userDoc.data()?['role']);
        prefs.setString('uidUser', userDoc.data()?['uid']);
        // isLoading = false;
      });

      if (userDoc.data()?['role'] == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminChatListPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login gagal!')),
      );
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _register() async {
    setState(() {
      isLoading = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user!;
      await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': user.email,
        'name': _nameController.text.trim(),
        'role': role,
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        prefs.setString('role', role);
        prefs.setString('uidUser', user.uid);
      });

      if (role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AdminChatListPage()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ChatListPage()));
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Akun berhasil dibuat!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrasi gagal!')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: Center(
            child: isLoading ? const CircularProgressIndicator() :
            SingleChildScrollView(
              child: Column(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 80),
                  const SizedBox(height: 8),
                  const Text('Mini Chat App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 44),
                  Visibility(
                    visible: !login,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Masukkan nama';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan email';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) {
                        return 'Masukkan email yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            showPassword = !showPassword;
                          });
                        },
                        icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  Visibility(
                    visible: !login,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Admin'),
                        Switch(
                          value: role == 'admin',
                          onChanged: (value) {
                            setState(() {
                              role = value ? 'admin' : 'user';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) login ? _login() : _register();
                    },
                    child: Text(login ? 'Login' : 'Register'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        login = !login;
                        _nameController.clear();
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
                    child: Text(login ? 'Belum punya akun? Registrasi' : 'Sudah punya akun? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
