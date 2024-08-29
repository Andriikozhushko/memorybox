import 'package:flutter_bloc/flutter_bloc.dart';

import '../add_collection/add_audio_to_collections.dart';

part 'selected_state.dart';

class SelectedAudioCubit extends Cubit<SelectedState> {
  SelectedAudioCubit() : super(const SelectedState([]));

  void addSelectedAudio(AudioDataSec audio) {
    final List<AudioDataSec> updatedList = List.from(state.audioDataSecs);
    if (!updatedList.any((item) => item.audioFileName == audio.audioFileName)) {
      updatedList.add(audio);
      emit(SelectedState(updatedList));
    }
  }

  void removeSelectedAudio(AudioDataSec audio) {
    final List<AudioDataSec> updatedList = state.audioDataSecs
        .where((item) => item.audioFileName != audio.audioFileName)
        .toList();
    emit(SelectedState(updatedList));
  }

  void setAudioSelection(List<AudioDataSec> selectedAudios) {
    emit(SelectedState(selectedAudios));
  }

  void clearSelectedAudio() {
    emit(const SelectedState([]));
  }
}
