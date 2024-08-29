import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';

import '../../blocs/audio_cubit/audio_cubit.dart';
import '../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../home_screen/homescreen.dart';
import 'models/audio_data.dart';

class DeletedPageForSelect extends StatelessWidget {
  const DeletedPageForSelect({super.key});

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
  String _getAudioUrl(String audioFileName) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User is not logged in.");
    }
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F$uid%2Faudio%2F$audioFileName?alt=media&token=';
  }

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    audioStream = _loadAudioStream();
    audioStream.listen((List<AudioData> data) {
      if (mounted) {
        setState(() {
          audioList = data;
          filteredAudioList = data;
        });
      }
    });
  }

  String _formatDuration(int durationMinutes, int durationSeconds) {
    String minutesText =
        _pluralize(durationMinutes, 'минута', 'минуты', 'минут');
    String secondsText =
        _pluralize(durationSeconds, 'секунда', 'секунды', 'секунд');

    if (durationMinutes > 0 && durationSeconds > 0) {
      return '$durationMinutes $minutesText $durationSeconds $secondsText';
    } else if (durationMinutes > 0) {
      return '$durationMinutes $minutesText';
    } else {
      return '$durationSeconds $secondsText';
    }
  }

  String _pluralize(int value, String form1, String form2, String form5) {
    if (value % 10 == 1 && value % 100 != 11) {
      return form1;
    } else if (value % 10 >= 2 &&
        value % 10 <= 4 &&
        (value % 100 < 10 || value % 100 >= 20)) {
      return form2;
    } else {
      return form5;
    }
  }

  Future<void> restoreSelectedAudios() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    for (var audio in audioList.where((audio) => audio.isSelected)) {
      // Создание нового документа в коллекции `audio_files` с данными из `recently_deleted`
      await firestore.collection('audio_files').add({
        'name': audio.name,
        'durationMinutes': audio.durationMinutes,
        'durationSeconds': audio.durationSeconds,
        'audioFileName': audio.audioFileName,
        'uid': currentUser!.uid // предполагая, что uid есть в модели AudioData
      });

      // Удаление документа из `recently_deleted`
      await firestore.collection('recently_deleted').doc(audio.id).delete();
    }

    // Обновляем список аудиозаписей в интерфейсе
    if (mounted) {
      setState(() {
        audioList.removeWhere((audio) => audio.isSelected);
      });
    }
  }

  Future<void> deleteSelectedAudios() async {
    List<Future> deletionTasks = [];

    for (var audio in audioList.where((audio) => audio.isSelected)) {
      // ignore: unused_local_variable
      String filePath =
          'users/${currentUser!.uid}/audio/${audio.audioFileName}';

      try {
        await Future.wait(deletionTasks);
        log("Все выбранные файлы успешно удалены.");

        if (mounted) {
          setState(() {
            audioList.removeWhere((audio) => audio.isSelected);
          });
        }
      } catch (e) {
        log("Произошла ошибка при удалении: $e");
        throw Exception("Ошибка при удалении файлов: $e");
      }
    }

    try {
      await Future.wait(deletionTasks);
      log("Все выбранные файлы успешно удалены.");

      setState(() {
        audioList.removeWhere((audio) => audio.isSelected);
      });
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
                case 'delete':
                  deleteSelectedAudios();
                  break;
                case 'restore':
                  restoreSelectedAudios();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Удалить все выбранные'),
              ),
              const PopupMenuItem<String>(
                value: 'restore',
                child: Text('Восстановить все выбранные'),
              ),
            ],
            icon: Image.asset('assets/img/icon/dots.png', height: 13),
          ),
        ],
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
            top: 40,
            right: 15,
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                );
                context.read<NavigationBloc>().add(NavigationEvents.home);
              },
              child: const Text(
                "Отменить",
                style: graysize16,
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
                  ListView.builder(
                    shrinkWrap: true,
                    itemCount: audioList.length,
                    itemBuilder: (context, index) {
                      final audioData = audioList[index];
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              audioData.isSelected = !audioData.isSelected;
                            });
                          },
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: borderColor,
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                BlocBuilder<AudioCubit, AudioState>(
                                  builder: (context, state) {
                                    bool isCurrentPlaying =
                                        state is AudioPlaying &&
                                            context
                                                    .read<AudioCubit>()
                                                    .currentTrackIndex ==
                                                index;
                                    return Padding(
                                      padding: const EdgeInsets.all(5.0),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: audiofileColor,
                                          borderRadius:
                                              BorderRadius.circular(40.0),
                                        ),
                                        child: IconButton(
                                          icon: Icon(
                                            isCurrentPlaying && state.isPlaying
                                                ? Icons.pause
                                                : Icons.play_arrow,
                                          ),
                                          iconSize: 33,
                                          color: Colors.white,
                                          onPressed: () {
                                            if (isCurrentPlaying) {
                                              context
                                                  .read<AudioCubit>()
                                                  .togglePlayPause();
                                            } else {
                                              var urls = audioList
                                                  .map((e) => _getAudioUrl(
                                                      e.audioFileName))
                                                  .toList();
                                              var names = audioList
                                                  .map((e) => e.name)
                                                  .toList();
                                              context
                                                  .read<AudioCubit>()
                                                  .setCurrentTrack(
                                                    urls,
                                                    names,
                                                    index,
                                                  );
                                            }
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(audioData.name),
                                      Text(
                                        _formatDuration(
                                          audioData.durationMinutes,
                                          audioData.durationSeconds,
                                        ),
                                        style: opgray14,
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(5.0),
                                  child: SvgPicture.asset(
                                    audioData.isSelected
                                        ? 'assets/img/icon/svg/selected.svg'
                                        : 'assets/img/icon/svg/circlesel.svg',
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 60.0,
                  right: 60.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.restore,
                              color: Color.fromRGBO(58, 58, 85, 0.8)),
                          onPressed: restoreSelectedAudios,
                        ),
                        const Text(
                          'Восстановить все',
                          style: TextStyle(
                              fontSize: 10,
                              height: 1,
                              color: Color.fromRGBO(58, 58, 85, 0.8)),
                        )
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: <Widget>[
                          IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Color.fromRGBO(58, 58, 85, 0.8)),
                            onPressed: deleteSelectedAudios,
                          ),
                          const Text(
                            'Удалить все',
                            style: TextStyle(
                              fontSize: 10,
                              height: 1,
                              color: Color.fromRGBO(58, 58, 85, 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
