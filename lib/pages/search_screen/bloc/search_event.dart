part of 'search_bloc.dart';

abstract class AudioEvent {}

class LoadAudios extends AudioEvent {
  final String uid;
  final String searchQuery;

  LoadAudios(this.uid, this.searchQuery);
}
