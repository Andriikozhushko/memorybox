import 'package:flutter_bloc/flutter_bloc.dart';

part 'subscribe_event.dart';
part 'subscribe_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  SubscriptionBloc() : super(SubscriptionState.yearly()) {
    on<SelectMonthly>((event, emit) => emit(SubscriptionState.monthly()));
    on<SelectYearly>((event, emit) => emit(SubscriptionState.yearly()));
  }
}
