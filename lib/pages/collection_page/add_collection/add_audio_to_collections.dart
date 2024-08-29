import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';

import '../../../styles/colors.dart';
import '../../../styles/ellipse_clipper.dart';
import '../../../styles/fonts.dart';
import '../cubit/selected_cubit.dart';

class AudioDataSec {
  String audioFileName;
  String name;
  int durationMinutes;
  int durationSeconds;
  bool isSelected;
  String? userUid;

  AudioDataSec({
    required this.audioFileName,
    required this.name,
    required this.durationMinutes,
    required this.durationSeconds,
    this.isSelected = false,
    this.userUid,
  });

  int get totalDurationInSeconds => durationMinutes * 60 + durationSeconds;

  String get audioUrl => userUid != null
      ? 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F$userUid%2Faudio%2F$audioFileName?alt=media&token='
      : throw Exception('User UID is null');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioDataSec &&
          runtimeType == other.runtimeType &&
          audioFileName == other.audioFileName &&
          name == other.name &&
          durationMinutes == other.durationMinutes &&
          durationSeconds == other.durationSeconds &&
          isSelected == other.isSelected &&
          userUid == other.userUid;

  @override
  int get hashCode =>
      audioFileName.hashCode ^
      name.hashCode ^
      durationMinutes.hashCode ^
      durationSeconds.hashCode ^
      isSelected.hashCode ^
      userUid.hashCode;

  factory AudioDataSec.fromFirestore(DocumentSnapshot doc, String? uid) {
    var data = doc.data() as Map<String, dynamic>;
    return AudioDataSec(
      audioFileName: data['audioFileName'] ?? '',
      name: data['name'] ?? '',
      durationMinutes: data['durationMinutes'] ?? 0,
      durationSeconds: data['durationSeconds'] ?? 0,
      isSelected: data['isSelected'] ?? false,
      userUid: uid,
    );
  }
}

class AddAudioCollectionsPage extends StatefulWidget {
  const AddAudioCollectionsPage({super.key});

  @override
  AddAudioCollectionsPageState createState() => AddAudioCollectionsPageState();
}

class AddAudioCollectionsPageState extends State<AddAudioCollectionsPage> {
  late List<AudioDataSec> audioList = [];
  late SelectedAudioCubit selectedAudioCubit;
  late AudioPlayer player;
  String? currentlyPlaying;
  bool _isPlaying = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    player.playerStateStream.listen((playerState) {
      setState(() {
        _isPlaying = playerState.playing;
      });
    });
    loadAudioList();
    selectedAudioCubit = context.read<SelectedAudioCubit>();
    Future.delayed(Duration.zero, () {
      updateSelectedStatus();
    });
  }

  void updateSelectedStatus() {
    var selectedAudios = selectedAudioCubit.state.audioDataSecs;
    setState(() {
      for (var audio in audioList) {
        audio.isSelected = selectedAudios
            .any((selected) => selected.audioFileName == audio.audioFileName);
      }
    });
  }

  void loadAudioList() async {
    var currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    var snapshot = await FirebaseFirestore.instance
        .collection('audio_files')
        .where('uid', isEqualTo: currentUserUid)
        .get();
    List<AudioDataSec> tempAudioList = snapshot.docs
        .map((doc) => AudioDataSec.fromFirestore(doc, currentUserUid))
        .toList();

    var selectedAudios = selectedAudioCubit.state.audioDataSecs;
    for (var audio in tempAudioList) {
      audio.isSelected = selectedAudios
          .any((selected) => selected.audioFileName == audio.audioFileName);
    }

    setState(() {
      audioList = tempAudioList;
    });
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectedAudioCubit = context.read<SelectedAudioCubit>();
    var selectedAudios = selectedAudioCubit.state.audioDataSecs;
    setState(() {
      for (var audio in audioList) {
        audio.isSelected = selectedAudios
            .any((selected) => selected.audioFileName == audio.audioFileName);
      }
    });
  }

  Future<void> toggleAudio(AudioDataSec audio) async {
    String audioUrl = _getAudioUrl(audio.audioFileName);
    if (currentlyPlaying == audio.audioFileName && _isPlaying) {
      await player.pause();
      setState(() {
        _isPlaying = false;
        currentlyPlaying = null;
      });
    } else {
      await player.setUrl(audioUrl);
      await player.play();
      setState(() {
        currentlyPlaying = audio.audioFileName;
        _isPlaying = true;
      });
    }
  }

  void saveSelections() {
    List<AudioDataSec> selectedAudios =
        audioList.where((audio) => audio.isSelected).toList();
    selectedAudioCubit.setAudioSelection(selectedAudios);
    Navigator.pop(context, selectedAudios);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: SvgPicture.asset('assets/img/icon/customback.svg',
                      fit: BoxFit.contain),
                ),
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 17.0),
            child: TextButton(
              child: const Text('Добавить', style: graysize16),
              onPressed: () {
                saveSelections();
              },
            ),
          ),
        ],
        centerTitle: true,
        title: const Text(
          'Выбрать',
          style: TextStyle(fontSize: 36, color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          SizedBox(
            height: 150,
            child: ClipPath(
              clipper: EllipseClipper(),
              child: Container(
                color: primaryColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 50,
                ),
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(41),
                      color: Colors.white),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 30.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Поиск',
                          border: InputBorder.none,
                          suffixIcon: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SvgPicture.asset(
                              'assets/img/icon/svg/search_drawer_icon.svg',
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: audioList.length,
                    itemBuilder: (context, index) {
                      AudioDataSec audio = audioList[index];
                      if (searchController.text.isNotEmpty &&
                          !audio.name
                              .toLowerCase()
                              .contains(searchController.text.toLowerCase())) {
                        return const SizedBox();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                        ),
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
                            children: <Widget>[
                              Container(
                                  width: 50,
                                  height: 50,
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      currentlyPlaying == audio.audioFileName &&
                                              _isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                    onPressed: () => toggleAudio(audio),
                                    iconSize: 33,
                                    color: Colors.white,
                                  )),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(audio.name,
                                        style: const TextStyle(fontSize: 16)),
                                    Text(
                                      audio.durationMinutes != 0
                                          ? '${audio.durationMinutes} минут'
                                          : '${audio.durationSeconds} секунд',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: SvgPicture.asset(
                                  audio.isSelected
                                      ? 'assets/img/icon/svg/selected.svg'
                                      : 'assets/img/icon/svg/circlesel.svg',
                                  width: 50,
                                  height: 50,
                                ),
                                onPressed: () {
                                  setState(() {
                                    audio.isSelected = !audio.isSelected;
                                    if (audio.isSelected) {
                                      selectedAudioCubit
                                          .addSelectedAudio(audio);
                                    } else {
                                      selectedAudioCubit
                                          .removeSelectedAudio(audio);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAudioUrl(String audioFileName) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User is not logged in.");
    }
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F$uid%2Faudio%2F$audioFileName?alt=media&token=';
  }
}
