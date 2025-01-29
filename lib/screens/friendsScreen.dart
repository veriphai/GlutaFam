import 'package:eureka_app/apis/fetchFriends.dart';
import 'package:eureka_app/screens/friendsProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chiclet/chiclet.dart';
import 'package:flutter/services.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFriendsData();
  }

  Future<void> fetchFriendsData() async {
    try {
      final friendsData = await fetchFriends();
      setState(() {
        friends = friendsData;
        isLoading = false;
      });
    } catch (error) {
      print("Error fetching friends data: $error");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildFriendRow(Map<String, dynamic> friend) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FriendsProfileScreen(
                friendId: friend["id"],
                following: true, // Default to true for simplicity
              ),
            ),
          );
        },
        child: Row(
          children: [
            // Friend Image
            ClipRRect(
              borderRadius: BorderRadius.circular(50), // Circular image
              child: Container(
                color: Colors.amber,
                child: friend.containsKey("imgUrl") && friend["imgUrl"] != null
                    ? Image.network(
                        friend["imgUrl"],
                        height: 40,
                        width: 40,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Friend Name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend["name"],
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "5100 XP", // Placeholder for XP
                    style: GoogleFonts.arOneSans(
                      color: Colors.white60,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            // Optional Action Button (e.g., Navigate to profile)
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white60,
              size: 15,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(19, 31, 36, 1),
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(19, 31, 36, 1),
        elevation: 0,
        title: Text(
          "Friends",
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.yellow,
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.separated(
                itemCount: friends.length,
                separatorBuilder: (context, index) => Divider(
                  color: const Color.fromARGB(255, 91, 91, 91),
                  thickness: 0.5,
                  height: 1, // Space between rows
                ),
                itemBuilder: (context, index) {
                  return buildFriendRow(friends[index]);
                },
              ),
            ),
    );
  }
}
