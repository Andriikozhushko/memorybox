import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AudioPageState {
  final AudioPageType type;
  final String audioPath;

  AudioPageState(this.type, {this.audioPath = ''});
}

enum AudioPageType { collection, edit }

class AudioPageCubit extends Cubit<AudioPageState> {
  AudioPageCubit() : super(AudioPageState(AudioPageType.collection));

  void showPlayer(String path) {
    debugPrint('Switching to Player Page with path: $path');
    emit(AudioPageState(AudioPageType.edit, audioPath: path));
  }

  void showProfile() {
    debugPrint('Switching to Profile Page');
    emit(AudioPageState(AudioPageType.collection));
  }

  void showEdit() {
    debugPrint('Switching to Edit Page');
    emit(AudioPageState(AudioPageType.edit));
  }
}
