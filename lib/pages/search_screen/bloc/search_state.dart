part of 'search_bloc.dart';

abstract class AudioState {}

class AudioInitial extends AudioState {}

class AudioLoadInProgress extends AudioState {}

class AudioLoadSuccess extends AudioState {
  final List<AudioData> audios;

  AudioLoadSuccess(this.audios);
}

class AudioLoadFailure extends AudioState {}
