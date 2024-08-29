import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../styles/colors.dart';
import '../../../styles/ellipse_clipper.dart';
import '../../../styles/fonts.dart';
import '../add_collection/add_collections.dart';
import '../collections_detail/collections_details_selected.dart';

class SelectedCollectionsPage extends StatefulWidget {
  final List<AudioData> audioData;

  const SelectedCollectionsPage({
    super.key,
    required this.audioData,
  });

  @override
  SelectedCollectionsPageState createState() => SelectedCollectionsPageState();
}

class SelectedCollectionsPageState extends State<SelectedCollectionsPage> {
  Map<String, bool> selectedItems = {};
  void toggleSelection(String docId) {
    setState(() {
      if (selectedItems.containsKey(docId)) {
        selectedItems[docId] = !selectedItems[docId]!;
      } else {
        selectedItems[docId] = true;
      }
    });
  }

  String formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (totalSeconds < 60) {
      return '$totalSeconds сек';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')} мин';
    }
  }

  void saveSelectedCollections() {
    if (widget.audioData.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No audio data to add")));
      return;
    }

    var batch = FirebaseFirestore.instance.batch();
    List<Future<void>> futures = [];

    selectedItems.forEach((collectionId, isSelected) {
      if (isSelected) {
        DocumentReference collectionRef = FirebaseFirestore.instance
            .collection('collections')
            .doc(collectionId);

        futures.add(collectionRef.get().then((docSnapshot) {
          if (docSnapshot.exists) {
            Map<String, dynamic> data =
                docSnapshot.data() as Map<String, dynamic>;
            List<Map<String, dynamic>> existingAudios =
                List<Map<String, dynamic>>.from(data['audioFiles'] ?? []);

            for (var audio in widget.audioData) {
              bool alreadyExists = existingAudios.any((existingAudio) =>
                  existingAudio['audioFileName'] == audio.audioFileName);
              if (!alreadyExists) {
                int durationInSeconds = audio.durationSeconds;

                int totalDuration = data['totalDuration'] ?? 0;
                totalDuration += durationInSeconds;

                batch.update(collectionRef, {
                  'audioFiles': FieldValue.arrayUnion([
                    {
                      'audioFileName': audio.audioFileName,
                      'durationInSeconds': durationInSeconds,
                    }
                  ]),
                  'totalDuration': totalDuration,
                });
              }
            }
          }
        }).catchError((error) {
          log("Error reading collection: $error");
        }));
      }
    });

    Future.wait(futures).then((_) {
      batch.commit().then((_) {
        Navigator.pop(context);
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error updating collections: $error")));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: SvgPicture.asset('assets/img/icon/svg/plus.svg'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddCollectionsPage()),
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
            child: const Text(
              'Добавить',
              style: graysize16,
            ),
            onPressed: () => saveSelectedCollections(),
          ),
        ],
        centerTitle: true,
        title: Text(
          'Подборки',
          style: graysize36.copyWith(color: const Color(0x50F6F6F6)),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF6F6F6),
          ),
          FractionallySizedBox(
            heightFactor: 0.4,
            child: ClipPath(
              clipper: EllipseClipper(),
              child: Container(
                color: primaryColor,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 5.0),
                  child: Builder(
                    builder: (BuildContext context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 85),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 11.0, right: 20.0),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('collections')
                  .where('ownerUid',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 240,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    var image = data['imageUrl'] as String;
                    var title = data['title'] as String;
                    var audioCount = (data['audioFiles'] as List).length;
                    var audioFiles = data['audioFiles'] as List<dynamic>;
                    var totalSeconds = 0;
                    for (var audioData in audioFiles) {
                      var durationInSeconds =
                          audioData['durationInSeconds'] as int;
                      totalSeconds += durationInSeconds;
                    }
                    String formattedDuration = formatDuration(totalSeconds);

                    return GestureDetector(
                      onTap: () {
                        toggleSelection(doc.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: NetworkImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(15)),
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color.fromRGBO(69, 69, 69, 1)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: SizedBox(
                                      width: 70,
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 3,
                                        softWrap: true,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Text('$audioCount аудио',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8),
                                        child: Text(formattedDuration,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: selectedItems[doc.id] ?? false
                                      ? Colors.black.withOpacity(0.0)
                                      : Colors.black.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Center(
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                    child: (selectedItems[doc.id] ?? false)
                                        ? SvgPicture.asset(
                                            'assets/img/icon/svg/selected.svg')
                                        : SvgPicture.asset(
                                            'assets/img/icon/svg/circlesel.svg'),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
