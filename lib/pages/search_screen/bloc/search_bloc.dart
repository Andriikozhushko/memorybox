import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home_screen/models/audio_data.dart';

part 'search_event.dart';
part 'search_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final FirebaseFirestore firestore;

  AudioBloc(this.firestore) : super(AudioInitial()) {
    on<LoadAudios>(_onLoadAudios);
  }

  Future<void> _onLoadAudios(LoadAudios event, Emitter<AudioState> emit) async {
    emit(AudioLoadInProgress());
    try {
      Query query = firestore
          .collection('audio_files')
          .where('uid', isEqualTo: event.uid);
      if (event.searchQuery.isNotEmpty) {
        query = query
            .where('name', isGreaterThanOrEqualTo: event.searchQuery)
            .where('name', isLessThanOrEqualTo: '${event.searchQuery}\uf8ff');
      }
      await query
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => AudioData.fromFirestore(doc)).toList())
          .forEach((data) {
        emit(AudioLoadSuccess(data));
      });
    } catch (e) {
      emit(AudioLoadFailure());
      addError(e);
    }
  }
}
