import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AudioData {
  final String id;
  String name;
  final String audioFileName;
  final int durationMinutes;
  final int durationSeconds;
  bool isEditing;
  final String uid;

  AudioData({
    required this.id,
    required this.name,
    required this.audioFileName,
    required this.durationMinutes,
    required this.durationSeconds,
    this.isEditing = false,
    required this.uid,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'audioFileName': audioFileName,
      'durationMinutes': durationMinutes,
      'durationSeconds': durationSeconds,
    };
  }

  Future<void> moveToRecentlyDeleted() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final audioFileSnapshot =
          await firestore.collection('audio_files').doc(id).get();

      log('Audio file snapshot data: $audioFileSnapshot');

      final audioFileData = audioFileSnapshot.data();

      if (audioFileData != null) {
        final updatedData = {
          ...audioFileData,
          'deletedAt': Timestamp.now(),
        };

        await firestore.collection('recently_deleted').doc(id).set(updatedData);

        await firestore.collection('audio_files').doc(id).delete();
      } else {
        throw Exception('Audio file data is null');
      }
    } catch (error) {
      throw Exception('Failed to move audio to recently deleted: $error');
    }
  }

  Future<void> rename(String newName) async {
    name = newName;
    await FirebaseFirestore.instance
        .collection('audio_files')
        .doc(id)
        .update({'name': newName});
  }

  factory AudioData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    String uid = FirebaseAuth.instance.currentUser?.uid ?? 'defaultUid';
    return AudioData(
      id: doc.id,
      name: data['name'] ?? '',
      audioFileName: data['audioFileName'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      durationSeconds: data['durationSeconds'] ?? 0,
      uid: uid,
    );
  }

  Future<void> delete() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore.collection('audio_files').doc(id).delete();

    final QuerySnapshot collectionsSnapshot =
        await firestore.collection('collections').get();

    for (var doc in collectionsSnapshot.docs) {
      var audioFiles = List.from(doc['audioFiles'] ?? []);

      if (audioFiles.any((item) => item['audioFileName'] == audioFileName)) {
        audioFiles
            .removeWhere((item) => item['audioFileName'] == audioFileName);
        await firestore
            .collection('collections')
            .doc(doc.id)
            .update({'audioFiles': audioFiles});
      }
    }
  }
}
