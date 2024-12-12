import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int currentIndex;

  CustomBottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  @override
  _CustomBottomNavBarState createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  void _onItemTapped(int index) {
    // Here, you can manage navigation based on the index
    switch (index) {}
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color.fromRGBO(255, 255, 255, 0.1),
      currentIndex: widget.currentIndex,
      onTap: _onItemTapped,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
              color: Colors.white,
              size: 40,
            ),
            label: 'Home',
            activeIcon: Icon(
              Icons.home,
              color: Colors.white,
              size: 40,
            )),
        BottomNavigationBarItem(
            icon: Icon(
              Icons.explore_outlined,
              color: Colors.white,
              size: 40,
            ),
            label: 'Explore',
            activeIcon: Icon(
              Icons.explore,
              color: Colors.white,
              size: 40,
            )),
        BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined, color: Colors.white, size: 40),
            label: 'Community',
            activeIcon: Icon(
              Icons.group,
              color: Colors.white,
              size: 40,
            )),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_2_outlined, color: Colors.white, size: 40),
            label: 'Profile',
            activeIcon: Icon(
              Icons.person_2,
              color: Colors.white,
              size: 40,
            ))
      ],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white,
      selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
      unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal, fontSize: 16, color: Colors.white),
      type: BottomNavigationBarType.fixed,
    );
  }
}
