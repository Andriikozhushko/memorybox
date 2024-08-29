import 'package:flutter_bloc/flutter_bloc.dart';

part 'records_state.dart';

class RecordPageCubit extends Cubit<RecordPageState> {
  RecordPageCubit() : super(RecordPageState(isIndicatorVisible: false));

  void showIndicator() {
    emit(RecordPageState(isIndicatorVisible: true));
  }

  void hideIndicator() {
    emit(RecordPageState(isIndicatorVisible: false));
  }

  void toggleIndicatorBasedOnIndex(int index) {
    if (index == 2) {
      emit(RecordPageState(isIndicatorVisible: true));
    } else {
      emit(RecordPageState(isIndicatorVisible: false));
    }
  }
}
