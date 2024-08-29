import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../blocs/audio_cubit/audio_cubit.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/drawer.dart';
import '../collection_page/selected_collections/selected_collections.dart';
import '../home_screen/models/audio_data.dart';
import 'widget/audio_list_view.dart';

class AudioScreen extends StatefulWidget {
  const AudioScreen({super.key});

  @override
  AudioScreenState createState() => AudioScreenState();
}

class AudioScreenState extends State<AudioScreen> {
  late Stream<List<AudioData>> audioStream;
  late User? currentUser;
  late List<AudioData> audioList = [];
  late AudioPlayer player;
  bool _isPlaying = false;
  late StreamSubscription<PlayerState> _playerStateSubscription;
  bool isButtonActive = false;

  void onAudioSelected(AudioData audioData) {
    setState(() {
      selectedAudioData = audioData;
    });
  }

  AudioData? selectedAudioData;

  Future<List<DocumentSnapshot>> fetchCollections(int limit) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('collections')
          .orderBy('id', descending: true)
          .limit(limit)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      return [];
    }
  }

  Future<void> downloadAndShare(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await Share.shareXFiles([XFile(filePath)],
          text: 'Я записал крутую сказу, послушай!');
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  void addToCollection(AudioData audioData) {
    onAudioSelected(audioData);
    _navigateAndDisplaySelection(context);
  }

  void deleteAudio(AudioData audioData) {
    audioData.moveToRecentlyDeleted().then((_) {
      audioData.delete().then((_) {
        setState(() {});
      }).catchError((error) {});
    }).catchError((error) {});
  }

  void shareAudio(AudioData audioData) {
    final url = _getAudioUrl(audioData.audioFileName);
    final fileName = audioData.audioFileName;
    downloadAndShare(url, fileName);
  }

  void _navigateAndDisplaySelection(BuildContext context) async {
    if (selectedAudioData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an audio file first")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectedCollectionsPage(
          audioData: selectedAudioData,
        ),
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    player = AudioPlayer();
    _playerStateSubscription = player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
    audioStream = currentUser != null
        ? _loadAudioStream()
        : const Stream<List<AudioData>>.empty();
  }

  @override
  void dispose() {
    _playerStateSubscription.cancel();
    super.dispose();
  }

  Stream<List<AudioData>> _loadAudioStream() {
    return FirebaseFirestore.instance
        .collection('audio_files')
        .where('uid', isEqualTo: currentUser!.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AudioData.fromFirestore(doc)).toList());
  }

  String _calculateTotalAudioTime(List<AudioData> audioList) {
    int totalSeconds = 0;
    for (var audioData in audioList) {
      totalSeconds +=
          (audioData.durationMinutes * 60) + audioData.durationSeconds;
    }

    int hours = totalSeconds ~/ 3600;
    int remainingSeconds = totalSeconds % 3600;
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;

    String hoursText =
        hours > 0 ? '$hours ${_pluralize(hours, 'час', 'часа', 'часов')} ' : '';
    String minutesText = minutes > 0
        ? '$minutes ${_pluralize(minutes, 'минута', 'минуты', 'минут')} '
        : '';
    String secondsText = seconds > 0
        ? '$seconds ${_pluralize(seconds, 'секунда', 'секунды', 'секунд')}'
        : '';

    return '$hoursText$minutesText$secondsText';
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

  Future<void> toggleAudio(String audioUrl) async {
    try {
      if (_isPlaying) {
        await player.pause();
      } else {
        await player.setUrl(audioUrl);
        await player.play();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          centerTitle: true,
          title: const Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Text(
              'Аудиозаписи',
              style: TextStyle(fontSize: 36, color: Colors.white),
            ),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: StreamBuilder<List<AudioData>>(
        stream: audioStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active &&
              snapshot.hasData) {
            audioList = snapshot.data!;
            List<String> urls =
                audioList.map((e) => _getAudioUrl(e.audioFileName)).toList();
            List<String> names = audioList.map((e) => e.name).toList();
            BlocProvider.of<AudioCubit>(context, listen: false)
                .setTracks(urls, names);

            return _buildAudioList(_calculateTotalAudioTime(audioList));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return const Center(child: Text('No audio files available.'));
          }
        },
      ),
    );
  }

  Widget _buildAudioList(String totalAudioTime) {
    return Stack(
      children: [
        Container(color: grayTextColor),
        FractionallySizedBox(
          heightFactor: 0.33,
          child: ClipPath(
            clipper: EllipseClipper(),
            child: Container(
              color: audiofileColor,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 90),
                    Padding(
                      padding: const EdgeInsets.only(left: 11.0, right: 20.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        child: const Text(
                          'Все в одном месте',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
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
                  audioList: audioList,
                  isButtonActive: isButtonActive,
                  onAddToCollection: addToCollection,
                  onDelete: deleteAudio,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 150,
          left: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${audioList.length} аудио',
                style: graysize14,
              ),
              Text(
                totalAudioTime,
                style: graysize14,
              ),
            ],
          ),
        ),
        Positioned(
          top: 150,
          right: 10,
          child: Container(
            width: 165,
            height: 45,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
            ),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isButtonActive = !isButtonActive;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isButtonActive
                    ? const Color.fromRGBO(246, 246, 246, 0.2)
                    : const Color.fromRGBO(246, 246, 246, 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Spacer(),
                  isButtonActive
                      ? SvgPicture.asset('assets/img/icon/svg/loop2.svg')
                      : SvgPicture.asset('assets/img/icon/svg/loop.svg'),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 150,
          right: 65,
          child: ElevatedButton.icon(
            onPressed: () {
              BlocProvider.of<AudioCubit>(context)
                  .playAllTracks(isButtonActive);
            },
            icon: Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: collectionsColor,
                  borderRadius: BorderRadius.circular(40.0),
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
            ),
            label: const SizedBox(
                width: 130,
                child: Text('Запустить все', style: TextStyle(fontSize: 14))),
            style: ElevatedButton.styleFrom(
              fixedSize: const Size(165, 45),
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  String _getAudioUrl(String audioFileName) {
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F${currentUser!.uid}%2Faudio%2F$audioFileName?alt=media&token=';
  }
}
