import 'package:assignment/converter_page.dart';
import 'package:assignment/login_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Home",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: Icon(Icons.grid_view_rounded, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                "Hello Musa 👋",
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Welcome back!",
                style: GoogleFonts.poppins(
                  color: Colors.grey[700],
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ConverterPage();
                        },
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.amber,
                  ),
                  child: Text(
                    "Converter Page",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 20),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return LoginPage();
                        },
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    "Login Page",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: 20),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(side: BorderSide()),
                  child: Text("TextButton"),
                ),
              ],
            ),
            SizedBox(height: 20),

            SizedBox(
              height: 200,
              width: 200,
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                color: Colors.black,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    "https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  "https://images.unsplash.com/photo-1492724441997-5dc865305da7",
                ),
              ),
            ),

            Container(
              width: 300,
              height: 400,
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                "Welcome to my world 🌍",
                style: GoogleFonts.lobster(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        onPressed: () {},
        child: Icon(Icons.add),
      ),

      endDrawer: NavigationDrawer(
        children: [
          ListTile(
            leading: Icon(Icons.home_rounded, color: Colors.black),
            title: Text(
              "Home",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: Colors.blue),
            title: Text(
              "Settings",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.person_rounded, color: Colors.purple),
            title: Text(
              "Profile",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
