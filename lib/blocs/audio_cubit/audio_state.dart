import 'package:equatable/equatable.dart';

abstract class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object> get props => [];
}

class AudioInitial extends AudioState {}

class AudioPlaying extends AudioState {
  final String trackName;
  final Duration position;
  final Duration duration;
  final bool isPlaying;

  const AudioPlaying({
    required this.trackName,
    required this.position,
    required this.duration,
    this.isPlaying = true,
  });

  @override
  List<Object> get props => [trackName, position, duration, isPlaying];

  AudioPlaying copyWith({
    String? trackName,
    Duration? position,
    Duration? duration,
    bool? isPlaying,
  }) {
    return AudioPlaying(
      trackName: trackName ?? this.trackName,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isPlaying: isPlaying ?? this.isPlaying,
    );
  }
}
