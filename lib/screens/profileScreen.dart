import 'package:eureka_app/widgets/customBottomBar.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      appBar: appBar(),
      body: Center(
        child: Text('Coming Soon!',
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
            )),
      ),
      bottomNavigationBar: CustomBottomNavBar(currentIndex: 3),
    );
  }

  AppBar appBar() {
    return AppBar(
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('Profile',
            style: TextStyle(
                fontSize: 24.0,
                color: Colors.white,
                fontWeight: FontWeight.bold)));
  }
}
