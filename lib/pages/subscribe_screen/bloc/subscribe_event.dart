part of 'subscribe_bloc.dart';

abstract class SubscriptionEvent {}

class SelectMonthly extends SubscriptionEvent {}

class SelectYearly extends SubscriptionEvent {}
