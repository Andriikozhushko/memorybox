import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../main.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/drawer.dart';
import 'deleted_recently_screen_selected.dart';
import 'models/audio_data.dart';
import 'models/audio_list.dart';

class DeletedPage extends StatelessWidget {
  const DeletedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DeletedView();
  }
}

class DeletedView extends StatefulWidget {
  const DeletedView({super.key});

  @override
  DeletedViewState createState() => DeletedViewState();
}

class DeletedViewState extends State<DeletedView> {
  late Stream<List<AudioData>> audioStream;
  late User? currentUser;
  late List<AudioData> audioList = [];
  late List<AudioData> filteredAudioList = [];
  late AudioPlayer player;
  bool isButtonActive = false;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    audioStream = _loadAudioStream();
    audioStream.listen((List<AudioData> data) {
      setState(() {
        audioList = data;
        filteredAudioList = data;
      });
    });
  }

  Future<void> restoreAllAudios() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('recently_deleted')
          .where('uid', isEqualTo: currentUser!.uid)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data();

        await FirebaseFirestore.instance.collection('audio_files').add(data);

        await doc.reference.delete();
      }

      setState(() {
        audioList.clear();
      });
    } catch (e) {
      log('Error restoring all audios: $e');
    }
  }

  void addToCollection(AudioData audioData) {
    onAudioSelected(audioData);
  }

  void onAudioSelected(AudioData audioData) {
    setState(() {
      selectedAudioData = audioData;
    });
  }

  AudioData? selectedAudioData;

  void deleteAudio(AudioData audioData) {
    audioData.delete().then((_) {
      setState(() {});
    }).catchError((error) {});
  }

  Future<void> deleteAllAudios() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseStorage storage = FirebaseStorage.instance;

    List<Future> deletionTasks = [];

    // Применяем операцию удаления ко всем аудиофайлам, а не только к выбранным
    for (var audio in audioList) {
      String filePath =
          'users/${currentUser!.uid}/audio/${audio.audioFileName}';

      // Добавляем задачу удаления из Firestore
      deletionTasks
          .add(firestore.collection('recently_deleted').doc(audio.id).delete());

      // Добавляем задачу удаления из Firebase Storage
      deletionTasks.add(storage.ref(filePath).delete());
    }

    try {
      // Ожидаем завершения всех задач удаления
      await Future.wait(deletionTasks);
      log("Все файлы успешно удалены.");

      // Очищаем список в интерфейсе, если виджет еще в дереве
      if (mounted) {
        setState(() {
          audioList.clear();
        });
      }
    } catch (e) {
      log("Произошла ошибка при удалении: $e");
      throw Exception("Ошибка при удалении файлов: $e");
    }
  }

  Stream<List<AudioData>> _loadAudioStream() {
    return FirebaseFirestore.instance
        .collection('recently_deleted')
        .where('uid', isEqualTo: currentUser!.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AudioData.fromFirestore(doc)).toList()
              ..sort((a, b) => b.deletedAt.compareTo(a.deletedAt)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: audiofileColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'select':
                  navigatorKey.currentState!.pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => const DeletedPageForSelect()),
                    (Route<dynamic> route) => false,
                  );
                  break;
                case 'delete':
                  deleteAllAudios();
                  break;
                case 'restore':
                  restoreAllAudios();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'select',
                child: Text('Выбрать несколько'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Удалить все'),
              ),
              const PopupMenuItem<String>(
                value: 'restore',
                child: Text('Восстановить все'),
              ),
            ],
            icon: Image.asset('assets/img/icon/dots.png', height: 13),
          ),
        ],
        leading: Builder(
          builder: (BuildContext context) {
            return Align(
              alignment: Alignment.topCenter,
              child: IconButton(
                icon: const Icon(Icons.menu, size: 36),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            );
          },
        ),
        centerTitle: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Text(
                'Недавно\nудаленные',
                style: graysize36.copyWith(height: 1),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        toolbarHeight: 80.0,
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF6F6F6),
          ),
          FractionallySizedBox(
            heightFactor: 0.2,
            child: ClipPath(
              clipper: EllipseClipper(),
              child: Container(
                color: audiofileColor,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 5.0),
                  child: Builder(
                    builder: (BuildContext context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 90),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 11.0,
                              right: 20.0,
                            ),
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
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  AudioListView(
                    audioList: filteredAudioList,
                    isButtonActive: isButtonActive,
                    onAddToCollection: addToCollection,
                    onDelete: deleteAudio,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
