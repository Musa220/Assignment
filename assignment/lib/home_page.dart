import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("HomePage"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: Icon(Icons.dashboard, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              "Hello 63E",
              style: TextStyle(color: Colors.deepOrangeAccent, fontSize: 30),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              "Welcome to our class",
              style: TextStyle(color: Colors.green[700], fontSize: 20),
            ),
          ),
          Container(
            width: 300,
            height: 400,
            padding: EdgeInsets.all(20),
            margin: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.orangeAccent),
            child: Text(
              "I am container!!!",
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        onPressed: () {},
        child: Icon(Icons.edit),
      ),
      endDrawer: NavigationDrawer(
        children: [
          ListTile(
            leading: Icon(Icons.home_filled, color: Colors.black),
            title: Text("HomePage"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.tune, color: Colors.green),
            title: Text("Settings"),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.account_circle, color: Colors.red),
            title: Text("ProfilePage"),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
