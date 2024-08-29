import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';

class AudioData {
  final String id;
  String name;
  final String uid;
  final String audioFileName;
  final int durationMinutes;
  final int durationSeconds;
  bool isEditing;
  final DateTime deletedAt;
  bool isSelected = false;

  AudioData({
    required this.id,
    required this.name,
    required this.uid,
    required this.audioFileName,
    required this.durationMinutes,
    required this.durationSeconds,
    this.isEditing = false,
    required this.deletedAt,
    this.isSelected = false,
  });

  factory AudioData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    String audioPath = data['audioPath'] as String? ?? 'users//audio/';
    String uid = audioPath.split('/')[1];

    return AudioData(
      id: doc.id,
      name: data['name'] as String? ?? '',
      uid: uid,
      audioFileName: data['audioFileName'] as String? ?? '',
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      deletedAt: (data['deletedAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  String getFormattedDate() {
    return DateFormat('dd.MM.yyyy').format(deletedAt);
  }

  Future<void> rename(String newName) async {
    name = newName;
    await FirebaseFirestore.instance
        .collection('recently_deleted')
        .doc(id)
        .update({'name': newName});
  }

  Future<void> delete() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseStorage storage = FirebaseStorage.instance;

    String filePath = 'users/$uid/audio/$audioFileName';

    try {
      await firestore.collection('recently_deleted').doc(id).delete();

      await storage.ref(filePath).delete();

      log("Файл успешно удален из Firestore и Storage.");
    } catch (e) {
      log("Ошибка при удалении: $e");
      throw Exception("Ошибка при удалении файла: $e");
    }
  }
}
