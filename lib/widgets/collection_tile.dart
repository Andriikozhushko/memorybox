import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:memory_box/widgets/page_builder.dart';

import '../blocs/navigation_bloc/navigation_bloc.dart';
import '../pages/collection_page/collections_detail/collections_details.dart';
import '../styles/colors.dart';

class CollectionCard extends StatelessWidget {
  final DocumentSnapshot collection;
  final bool isLargeCard;
  const CollectionCard({
    super.key,
    required this.collection,
    this.isLargeCard = false,
  });

  String _formatDuration(int durationMinutes, int durationSeconds) {
    int totalSeconds = durationMinutes * 60 + durationSeconds;
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;

    if (totalSeconds < 60) {
      return '$seconds сек';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')} мин';
    }
  }

  @override
  Widget build(BuildContext context) {
    double cardWidth = 185.w;
    double cardHeight = isLargeCard ? 240.h : 112.h;

    List<dynamic> audioFiles = collection['audioFiles'] as List<dynamic>;
    int totalDuration = 0;
    for (var audioData in audioFiles) {
      int durationInSeconds = audioData['durationInSeconds'] as int;
      totalDuration += durationInSeconds;
    }
    String formattedDuration =
        _formatDuration(totalDuration ~/ 60, totalDuration % 60);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => miniPlayer(
              context,
              CollectionDetailsPage(
                collectionId: collection.id,
              ),
            ),
          ),
        );
        context.read<NavigationBloc>().add(NavigationEvents.collection);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isLargeCard
              ? primaryColor.withOpacity(0.9)
              : recordColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(15),
        ),
        width: cardWidth,
        height: cardHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                collection['imageUrl'],
                fit: BoxFit.cover,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 70,
                    child: Text(
                      collection['title'],
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
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${audioFiles.length} аудио',
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        formattedDuration,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
