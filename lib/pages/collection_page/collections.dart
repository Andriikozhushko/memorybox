import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/page_builder.dart';
import 'add_collection/add_collections.dart';
import 'collections_detail/collections_details.dart';

class CollectionsPage extends StatefulWidget {
  const CollectionsPage({
    super.key,
  });

  @override
  CollectionsPageState createState() => CollectionsPageState();
}

class CollectionsPageState extends State<CollectionsPage> {
  String formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (totalSeconds < 60) {
      return '$totalSeconds сек';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')} мин';
    }
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
          IconButton(
            icon: Image.asset('assets/img/icon/dots.png', height: 13),
            onPressed: () {},
          ),
        ],
        centerTitle: true,
        title: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Text(
                'Подборки',
                style: graysize36.copyWith(height: 1),
              ),
            ),
            Text(
              'Все в одном месте',
              style: graysize16.copyWith(height: 1),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: grayTextColor,
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
          Container(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('collections')
                  .where('ownerUid',
                      isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 240,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  padding: const EdgeInsets.only(
                    top: 50,
                  ),
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    String image = data['imageUrl'];
                    String title = data['title'];
                    var audioCount = (data['audioFiles'] as List).length;
                    var audioFiles = data['audioFiles'] as List<dynamic>;
                    int totalSeconds = 0;
                    for (var audioData in audioFiles) {
                      var durationInSeconds =
                          audioData['durationInSeconds'] as int;
                      totalSeconds += durationInSeconds;
                    }
                    String formattedDuration = formatDuration(totalSeconds);

                    return GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => miniPlayer(
                              context,
                              CollectionDetailsPage(collectionId: doc.id),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: NetworkImage(image),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
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
                              )),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text('$audioCount аудио',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
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
