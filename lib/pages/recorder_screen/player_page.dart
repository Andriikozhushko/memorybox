import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/recorder_screen/record_page.dart';
import 'package:share_plus/share_plus.dart';

import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/auth_dialog.dart';
import '../../widgets/drawer.dart';
import '../../widgets/slider.dart';

class PlayerPage extends StatefulWidget {
  final String audioPath;

  const PlayerPage({super.key, required this.audioPath});

  @override
  PlayerPageState createState() => PlayerPageState();
}

class PlayerPageState extends State<PlayerPage> {
  late AudioPlayer audioPlayer;
  late TextEditingController _nameController;
  bool isPlaying = false;
  double sliderValue = 0.0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    audioPlayer = AudioPlayer();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    try {
      await audioPlayer.setFilePath(widget.audioPath);
      audioPlayer.playerStateStream.listen((playerState) {
        setState(() {
          isPlaying = playerState.playing;
        });
      });

      audioPlayer.positionStream.listen((position) {
        setState(() {
          sliderValue = position.inMilliseconds.toDouble();
        });
      });
    } catch (e) {
      debugPrint("Ошибка инициализации аудиоплеера: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _shareAudio() async {
    final file = File(widget.audioPath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(widget.audioPath)],
        text: 'Поделиться аудиофайлом',
      );
    } else {
      log('Ошибка: файл не найден по указанному пути: ${widget.audioPath}');
    }
  }

  Future<void> _downloadAudio() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        final filePath = '$result/audio.mp3';
        final file = File(filePath);
        await file.writeAsBytes(await File(widget.audioPath).readAsBytes());
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Аудиофайл успешно скачан в $filePath'),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не выбрана папка для сохранения аудиофайла'),
          ),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при скачивании аудиофайла: $e'),
        ),
      );
      log('Ошибка при скачивании аудиофайла: $e');
    }
  }

  Future<void> _saveRecording() async {
    final name = _nameController.text;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, введите название аудиозаписи'),
        ),
      );
      return;
    }

    bool success = await _saveToFirebase(
      context,
      name,
      'audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
      widget.audioPath,
    );

    if (success) {
      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(
          builder: (context) => const RecordPage(),
        ),
      );
    }
  }

  Future<bool> _saveToFirebase(BuildContext context, String name,
      String audioFileName, String audioPath) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final audioStorageRef = FirebaseStorage.instance
            .ref()
            .child('users/$uid/audio/$audioFileName');
        await audioStorageRef.putFile(File(audioPath));

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аудиофайл успешно сохранён на Firebase Storage'),
          ),
        );

        final audioFile = File(audioPath);
        final fileSizeInBytes = await audioFile.length();
        final formattedSize =
            (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(3);

        final duration = audioPlayer.duration;
        final minutes = duration!.inMinutes;
        final seconds = duration.inSeconds.remainder(60);
        await FirebaseFirestore.instance.collection('audio_files').add({
          'uid': uid,
          'name': name,
          'audioFileName': audioFileName,
          'audioPath': 'users/$uid/audio/$audioFileName',
          'fileSizeMB': formattedSize,
          'durationMinutes': minutes,
          'durationSeconds': seconds,
        });

        log('Данные об аудиозаписи успешно сохранены в Firestore');
        return true;
      } else {
        log('Пользователь не найден.');
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Ошибка при сохранении аудиофайла на Firebase Storage: $e'),
        ),
      );
      log('Ошибка при сохранении аудиофайла на Firebase Storage: $e');
      return false;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grayTextColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu, size: 36),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          ClipPath(
            clipper: EllipseClipper(),
            child: Container(
              color: collectionsColor,
              height: MediaQuery.of(context).size.height * 0.4.h,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(5.w, 25.h, 5.w, 0),
                child: Container(
                  height: 650.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: grayTextColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(
                          left: 15.0.w,
                          right: 15.0.w,
                          top: 20.0.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: _shareAudio,
                              icon: SvgPicture.asset(
                                  'assets/img/icon/svg/shared_icon_player.svg'),
                              iconSize: 36,
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: _downloadAudio,
                              icon: SvgPicture.asset(
                                  'assets/img/icon/svg/download_icon_player.svg'),
                              iconSize: 36,
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RecordPage(),
                                  ),
                                );
                              },
                              icon: SvgPicture.asset(
                                  'assets/img/icon/svg/trash_icon_player.svg'),
                              iconSize: 36,
                            ),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    if (FirebaseAuth.instance.currentUser ==
                                        null) {
                                      // Пользователь не авторизован, показываем диалог аутентификации
                                      showAuthDialog(context, () {});
                                    } else {
                                      // Пользователь авторизован, сохраняем запись
                                      _saveRecording();
                                    }
                                  },
                                  child: const Text(
                                    'Сохранить',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 100.h),
                      TextFormField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'Название...',
                          hintStyle: dark24,
                          border: InputBorder.none,
                        ),
                        style: dark24,
                      ),
                      SizedBox(
                        height: 80.h,
                      ),
                      StreamBuilder<Duration?>(
                        stream: audioPlayer.durationStream,
                        builder: (context, snapshot) {
                          final duration = snapshot.data ?? Duration.zero;
                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderThemeData(
                                  thumbColor: fontColor,
                                  thumbShape: ThumbsSlider(),
                                  activeTrackColor: const Color(0xFF3A3A55),
                                  inactiveTrackColor: const Color(0xFF3A3A55),
                                ),
                                child: Slider(
                                  value: sliderValue.clamp(
                                      0.0, duration.inMilliseconds.toDouble()),
                                  onChanged: (value) {
                                    audioPlayer.seek(
                                        Duration(milliseconds: value.toInt()));
                                    setState(() {
                                      sliderValue = value;
                                    });
                                  },
                                  min: 0.0,
                                  max: duration.inMilliseconds.toDouble(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 25.0,
                                  right: 25.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(audioPlayer.position),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      _formatDuration(duration),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(
                        height: 110.h,
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ClipOval(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final newPosition = audioPlayer.position -
                                      const Duration(seconds: 15);
                                  audioPlayer.seek(newPosition < Duration.zero
                                      ? Duration.zero
                                      : newPosition);
                                },
                                icon: SvgPicture.asset(
                                    'assets/img/icon/svg/15secdown.svg'),
                                iconSize: 36,
                              ),
                              SizedBox(
                                width: 50.w,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(100),
                                  color: recordColor,
                                ),
                                width: 80,
                                height: 80,
                                child: IconButton(
                                  onPressed: () {
                                    if (isPlaying) {
                                      audioPlayer.pause();
                                    } else {
                                      audioPlayer.play();
                                    }
                                  },
                                  icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  iconSize: 48,
                                ),
                              ),
                              SizedBox(
                                width: 50.w,
                              ),
                              IconButton(
                                onPressed: () {
                                  final remainingTime = audioPlayer.duration! -
                                      audioPlayer.position;
                                  final newPosition = audioPlayer.position +
                                      Duration(
                                          seconds: remainingTime.inSeconds >= 15
                                              ? 15
                                              : remainingTime.inSeconds);
                                  audioPlayer.seek(
                                      newPosition > audioPlayer.duration!
                                          ? audioPlayer.duration!
                                          : newPosition);
                                },
                                icon: SvgPicture.asset(
                                    'assets/img/icon/svg/15secup.svg'),
                                iconSize: 36,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
