import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/audio_cubit/audio_cubit.dart';
import '../../../styles/colors.dart';
import '../../../styles/fonts.dart';
import '../../../widgets/audio_popup_menu.dart';
import '../../home_screen/models/audio_data.dart';

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
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 120),
        itemCount: widget.audioList.length,
        itemBuilder: (context, index) {
          final audioData = widget.audioList[index];
          return Center(
            child: Padding(
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
                  children: [
                    BlocBuilder<AudioCubit, AudioState>(
                      builder: (context, state) {
                        bool isCurrentPlaying = state is AudioPlaying &&
                            context.read<AudioCubit>().currentTrackIndex ==
                                index;
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
                                      .map((e) => _getAudioUrl(e))
                                      .toList();
                                  var names = widget.audioList
                                      .map((e) => e.name)
                                      .toList();
                                  context.read<AudioCubit>().setCurrentTrack(
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
                      child: audioData.isEditing
                          ? TextField(
                              autofocus: true,
                              controller:
                                  TextEditingController(text: audioData.name)
                                    ..selection = TextSelection.fromPosition(
                                        TextPosition(
                                            offset: audioData.name.length)),
                              onSubmitted: (newName) {
                                audioData.rename(newName).then((_) {
                                  setState(() {
                                    audioData.isEditing = false;
                                  });
                                });
                              },
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                    AudioPopupMenu(
                      audioFileName: audioData.audioFileName,
                      onRename: () {
                        setState(() {
                          audioData.isEditing = true;
                        });
                      },
                      onAddToCollection: () =>
                          widget.onAddToCollection(audioData),
                      onDelete: () => widget.onDelete(audioData),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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

  String _getAudioUrl(AudioData audioData) {
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F${audioData.uid}%2Faudio%2F${audioData.audioFileName}?alt=media&token=';
  }
}
