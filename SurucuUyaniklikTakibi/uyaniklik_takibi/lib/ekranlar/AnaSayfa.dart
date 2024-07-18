import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uyaniklik_takibi/ekranlar/giris.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  HomeScreen({required Key key, required this.username}) : super(key: key);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hoşgeldiniz'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              await googleSignIn.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                  (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            Container(
              child: ElevatedButton.icon(
                icon: Icon(Icons.image),
                onPressed: () {},
                label: Text('Resim seçin',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
