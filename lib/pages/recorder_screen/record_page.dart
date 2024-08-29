import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/recorder_screen/player_page.dart';
import 'package:memory_box/styles/colors.dart';
import 'package:path_provider/path_provider.dart';

import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/drawer.dart';
import 'cubit/records_cubit.dart';

class AudioDataF {
  final String name;
  final String path;

  AudioDataF({required this.name, required this.path});

  factory AudioDataF.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AudioDataF(
      name: data['name'] ?? '',
      path: data['path'] ?? '',
    );
  }
}

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  late RecorderController recorderController;
  late AudioPlayer audioPlayer;
  RecordPageCubit? cubit;
  String? path;
  bool isRecording = false;
  DateTime? startTime;
  Timer? timer;
  bool isVisible = true;

  @override
  void initState() {
    super.initState();
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
    audioPlayer = AudioPlayer();
    cubit = context.read<RecordPageCubit>();
    cubit?.showIndicator();
  }

  @override
  void dispose() {
    timer?.cancel();
    audioPlayer.dispose();
    cubit?.hideIndicator();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: grayTextColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
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
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Container(
            color: grayTextColor,
          ),
          ClipPath(
            clipper: EllipseClipper(),
            child: Container(
              color: collectionsColor,
              height: MediaQuery.of(context).size.height * 0.4,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(5.w, 25.h, 5.w, 0),
              child: Container(
                height: 600.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: grayTextColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        isRecording
                            ? TextButton(
                                onPressed: _cancelRecording,
                                child: Padding(
                                  padding:
                                      EdgeInsets.fromLTRB(0, 30.h, 20.w, 0),
                                  child: const Text(
                                    'Отменить',
                                    style: dark16,
                                  ),
                                ),
                              )
                            : SizedBox(
                                height: 70.h,
                              ),
                      ],
                    ),
                    const Text(
                      'Запись',
                      style: dark24,
                    ),
                    SizedBox(
                      height: 380.h,
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(pi),
                        child: AudioWaveforms(
                          size: Size(MediaQuery.of(context).size.width, 20.0),
                          recorderController: recorderController,
                          enableGesture: false,
                          waveStyle: WaveStyle(
                            bottomPadding: 205.h,
                            waveColor: fontColor,
                            showDurationLabel: false,
                            waveCap: StrokeCap.round,
                            extendWaveform: true,
                            showMiddleLine: false,
                            scaleFactor: 100.h,
                            waveThickness: 4,
                            spacing: 6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 0),
              child: FractionallySizedBox(
                heightFactor: 0.1,
                child: Container(
                  width: 4,
                  color: recordColor,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 150.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: isVisible ? 1 : 0,
                    child: const Icon(
                      Icons.circle,
                      color: errorColor,
                      size: 10,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDuration(_getCurrentRecordingDuration()),
                    style: dark18,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.h),
              child: ClipOval(
                child: Container(
                  color: recordColor,
                  width: 80,
                  height: 80,
                  child: IconButton(
                    onPressed: isRecording ? _stopRecording : _startRecording,
                    icon: Icon(isRecording ? Icons.pause : Icons.play_arrow),
                    color: grayTextColor,
                    iconSize: 50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    return '${duration.inHours.toString().padLeft(2, '0')}:${(duration.inMinutes % 60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Duration _getCurrentRecordingDuration() {
    if (isRecording && startTime != null) {
      final now = DateTime.now();
      return now.difference(startTime!);
    }
    return Duration.zero;
  }

  void _startRecording() async {
    try {
      final appDirectory = await getApplicationDocumentsDirectory();
      path = "${appDirectory.path}/recording.m4a";
      await recorderController.record(path: path);

      startTime = DateTime.now();

      _startTimer();
      _startAnimation();
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = true;
      });
    }
  }

  void _stopRecording() async {
    try {
      timer?.cancel();
      path = await recorderController.stop(false);

      if (path != null) {
        debugPrint(path!);
        debugPrint("Recorded file size: ${File(path!).lengthSync()}");

        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => PlayerPage(audioPath: path!),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = false;
        isVisible = false;
      });
    }
  }

  void _cancelRecording() async {
    try {
      if (timer != null && timer!.isActive) {
        timer!.cancel();
      }
      await recorderController.stop(true);
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = false;
        isVisible = false;
        startTime = null;
      });
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  void _startAnimation() {
    timer = Timer.periodic(const Duration(milliseconds: 500), (Timer timer) {
      setState(() {
        isVisible = !isVisible;
      });
    });
  }
}
