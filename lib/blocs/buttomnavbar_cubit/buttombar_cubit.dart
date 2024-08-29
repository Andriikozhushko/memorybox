import 'package:flutter_bloc/flutter_bloc.dart';

part 'buttombar_state.dart';

class BottomNavBarVisibilityCubit extends Cubit<BottomNavBarVisibility> {
  BottomNavBarVisibilityCubit() : super(BottomNavBarVisibility.visible);

  void showBottomNavBar() {
    if (state != BottomNavBarVisibility.visible) {
      emit(BottomNavBarVisibility.visible);
    }
  }

  void hideBottomNavBar() {
    if (state != BottomNavBarVisibility.hidden) {
      emit(BottomNavBarVisibility.hidden);
    }
  }
}
