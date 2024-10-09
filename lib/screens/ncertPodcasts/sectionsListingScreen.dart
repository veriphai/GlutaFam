import 'package:eureka_app/screens/ncertPodcasts/podcastScreen.dart';
import 'package:flutter/material.dart';

class Sectionscreen extends StatelessWidget {
  final String chapterName;
  final String chapterImage;
  final List<dynamic> sections;

  const Sectionscreen(
      {required this.chapterName,
      required this.sections,
      required this.chapterImage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            chapterName,
            style: const TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(
            color: Colors.white, // Set the back button color to white
          ),
        ),
        backgroundColor: Colors.black,
        body: Column(
          children: [
            Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    chapterImage,
                    fit: BoxFit.cover,
                    height: 200,
                    width: 200,
                  ),
                )),
            Expanded(
                child: ListView.builder(
                    itemCount: sections.length,
                    itemBuilder: (context, index) {
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                              color: Colors.grey[900],
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                leading: Image.network(
                                  sections[index]['imageUrl'],
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  'Section ${index + 1}: ${sections[index]['name']}',
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                                subtitle: Text(
                                    sections[index]['description'] ??
                                        "No description availabe",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PodcastScreen(
                                        title: sections[index]['name'],
                                        description: sections[index]
                                                ['description'] ??
                                            "No description available",
                                        imageUrl: sections[index]['imageUrl'],
                                        audioUrl: sections[index]['audioUrl'] ??
                                            "", // Assuming audioUrl is part of the section
                                        duration: sections[index]
                                                ['timeToComplete'] ??
                                            "Unknown",
                                      ),
                                    ),
                                  );
                                },
                              )));
                    }))
          ],
        ));
  }
}
