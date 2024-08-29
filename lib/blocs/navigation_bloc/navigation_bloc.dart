import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvents, int> {
  final Function(int) onNavigate;

  NavigationBloc({required this.onNavigate}) : super(0) {
    on<NavigationEvents>((event, emit) {
      int newState;
      switch (event) {
        case NavigationEvents.home:
          newState = 0;
          break;
        case NavigationEvents.collection:
          newState = 1;
          break;
        case NavigationEvents.record:
          newState = 2;
          break;
        case NavigationEvents.audio:
          newState = 3;
          break;
        case NavigationEvents.profile:
          newState = 4;
          break;
        default:
          newState = state;
          break;
      }
      if (newState != state) {
        emit(newState);
        onNavigate(newState);
      }
    });
  }
}
