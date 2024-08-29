import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class AudioCubit extends Cubit<AudioState> {
  final AudioPlayer _player = AudioPlayer();
  List<String> trackUrls = [];
  List<String> trackNames = [];

  int currentTrackIndex = 0;
  bool isPlaying = false;
  bool isPlaylistMode = false;
  AudioCubit() : super(AudioInitial());

  void setTracks(List<String> urls, List<String> names) {
    log("Setting tracks...");
    trackUrls = urls;
    trackNames = names;
    currentTrackIndex = 0;
    log("Tracks set. Number of tracks: ${trackUrls.length}");
  }

  void setCurrentTrack(
      List<String> urls, List<String> names, int currentIndex) {
    log("Setting current track to index: $currentIndex");
    if (currentIndex < urls.length && currentIndex < names.length) {
      trackUrls = urls;
      trackNames = names;
      currentTrackIndex = currentIndex;
      play(trackUrls[currentTrackIndex], trackNames[currentTrackIndex]);
    } else {
      log("Invalid track index: $currentIndex");
    }
  }

  void playNext() {
    log("Calling playNext...");
    log("Current track index: $currentTrackIndex");
    log("Number of tracks: ${trackUrls.length}");

    if (trackUrls.isEmpty) {
      log("Playlist is empty.");
      return;
    }

    if (currentTrackIndex < trackUrls.length - 1) {
      currentTrackIndex++;
    } else {
      log("Reached the end of the playlist.");
      return;
    }

    log("New track index: $currentTrackIndex");
    log("Playing: ${trackNames[currentTrackIndex]}");
    play(trackUrls[currentTrackIndex], trackNames[currentTrackIndex]);
  }

  Future<void> playAllTracksInBackground(bool isButtonActive) async {
    if (trackUrls.isNotEmpty) {
      currentTrackIndex = 0;
      while (isButtonActive) {
        for (int i = currentTrackIndex;
            i < trackUrls.length && isButtonActive;
            i++) {
          await play(trackUrls[i], trackNames[i]);
          await for (PlayerState state in _player.playerStateStream) {
            if (state.processingState == ProcessingState.completed) {
              break;
            }
          }
          if (i < trackUrls.length - 1) {
            currentTrackIndex++;
          } else {
            if (isButtonActive) {
              currentTrackIndex = 0;
            }
          }
        }
      }
    }
  }

  void playAllTracks(bool isButtonActive) async {
    if (trackUrls.isNotEmpty) {
      currentTrackIndex = 0;
      if (!isButtonActive) {
        for (int i = currentTrackIndex; i < trackUrls.length; i++) {
          await play(trackUrls[i], trackNames[i]);
          await for (PlayerState state in _player.playerStateStream) {
            if (state.processingState == ProcessingState.completed) {
              break;
            }
          }
          if (i < trackUrls.length - 1) {
            currentTrackIndex++;
          }
        }
      } else {
        while (isButtonActive) {
          for (int i = currentTrackIndex;
              i < trackUrls.length && isButtonActive;
              i++) {
            await play(trackUrls[i], trackNames[i]);
            await for (PlayerState state in _player.playerStateStream) {
              if (state.processingState == ProcessingState.completed) {
                break;
              }
            }
            if (i < trackUrls.length - 1) {
              currentTrackIndex++;
            } else {
              if (isButtonActive) {
                currentTrackIndex = 0;
              }
            }
          }
        }
      }
    }
  }

  Future<void> play(String url, String trackName) async {
    log("Playing track: $trackName, URL: $url");
    if (isPlaying) {
      await _player.stop();
    }
    await _player.setUrl(url);

    emit(AudioPlaying(
      trackName: trackName,
      position: Duration.zero,
      duration: Duration.zero,
      isPlaying: true,
    ));

    _player.positionStream.listen((position) {
      final duration = _player.duration ?? Duration.zero;
      emit(AudioPlaying(
        trackName: trackName,
        position: position,
        duration: duration,
        isPlaying: _player.playing,
      ));
    });

    _player.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        _player.stop().then((_) {
          _player.seek(Duration.zero);
          emit(AudioPlaying(
            trackName: trackName,
            position: Duration.zero,
            duration: _player.duration ?? Duration.zero,
            isPlaying: false,
          ));
        });
      }
    });

    await _player.play();
    isPlaying = true;
  }

  void togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    isPlaying = _player.playing;
    if (state is AudioPlaying) {
      final currentState = state as AudioPlaying;
      emit(currentState.copyWith(isPlaying: isPlaying));
    }
  }
}

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
