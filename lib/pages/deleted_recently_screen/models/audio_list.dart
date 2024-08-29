import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../blocs/audio_cubit/audio_cubit.dart';
import '../../../styles/colors.dart';
import '../../../styles/fonts.dart';
import 'audio_data.dart';

class AudioListView extends StatefulWidget {
  final List<AudioData> audioList;
  final bool isButtonActive;
  final Function(AudioData) onAddToCollection;
  final Function(AudioData) onDelete;

  const AudioListView({
    super.key,
    required this.audioList,
    required this.isButtonActive,
    required this.onAddToCollection,
    required this.onDelete,
  });

  @override
  AudioListViewState createState() => AudioListViewState();
}

class AudioListViewState extends State<AudioListView> {
  @override
  Widget build(BuildContext context) {
    Map<String, List<AudioData>> groupedByDate = {};
    for (var audio in widget.audioList) {
      String formattedDate = audio.getFormattedDate();
      if (groupedByDate[formattedDate] == null) {
        groupedByDate[formattedDate] = [];
      }
      groupedByDate[formattedDate]!.add(audio);
    }

    List<Widget> dateSections = [];
    groupedByDate.forEach((date, audios) {
      List<Widget> audioWidgets = audios.map((audio) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 0),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<AudioCubit, AudioState>(
                  builder: (context, state) {
                    bool isCurrentPlaying = state is AudioPlaying &&
                        context.read<AudioCubit>().currentTrackIndex ==
                            widget.audioList.indexOf(audio);
                    return Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: audiofileColor,
                          borderRadius: BorderRadius.circular(40.0),
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
                              context.read<AudioCubit>().togglePlayPause();
                            } else {
                              var urls = widget.audioList
                                  .map((e) => _getAudioUrl(e.audioFileName))
                                  .toList();
                              var names =
                                  widget.audioList.map((e) => e.name).toList();
                              context.read<AudioCubit>().setCurrentTrack(
                                    urls,
                                    names,
                                    widget.audioList.indexOf(audio),
                                  );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(audio.name),
                        Text(
                          _formatDuration(
                            audio.durationMinutes,
                            audio.durationSeconds,
                          ),
                          style: opgray14,
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset("assets/img/icon/svg/delete.svg"),
                  onPressed: () {
                    audio.delete().then((_) {
                      setState(() {});
                    }).catchError((error) {
                      log("Ошибка при удалении файла: $error");
                    });
                  },
                ),
              ],
            ),
          ),
        );
      }).toList();

      dateSections.add(
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF3A3A55).withOpacity(0.5),
                ),
              ),
            ),
            ...audioWidgets
          ],
        ),
      );
    });

    return Expanded(
      child: ListView(
        children: dateSections,
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
}
