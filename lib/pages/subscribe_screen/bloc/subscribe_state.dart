part of 'subscribe_bloc.dart';

class SubscriptionState {
  final String buttonText;
  final String selectedPlan;

  SubscriptionState._(this.buttonText, this.selectedPlan);

  factory SubscriptionState.initial() {
    return SubscriptionState._('Выберите план подписки', '');
  }

  factory SubscriptionState.monthly() {
    return SubscriptionState._('Подписаться на месяц', 'monthly');
  }

  factory SubscriptionState.yearly() {
    return SubscriptionState._('Подписаться на год', 'yearly');
  }
}

/*
class SubscriptionState {
  final String buttonText;
  final String selectedPlan;

  SubscriptionState(this.buttonText, this.selectedPlan);

  bool get isMonthly => selectedPlan == 'monthly';
  bool get isYearly => selectedPlan == 'yearly';
}

*/
