import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:memory_box/pages/audio_screen/audiolist_page.dart';
import 'package:memory_box/pages/collection_page/add_collection/add_collections.dart';
import 'package:memory_box/pages/collection_page/collections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../blocs/audio_cubit/audio_cubit.dart';
import '../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/audio_popup_menu.dart';
import '../../widgets/auth_dialog.dart';
import '../../widgets/collection_tile.dart';
import '../../widgets/drawer.dart';
import '../collection_page/selected_collections/selected_collections.dart';
import 'models/audio_data.dart';

class HomeBody extends StatefulWidget {
  final User? currentUser;
  final Stream<List<AudioData>> audioStream;

  const HomeBody({
    super.key,
    required this.currentUser,
    required this.audioStream,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  String _formatDuration(int durationMinutes, int durationSeconds) {
    String minutesText = durationMinutes == 1 ? 'минута' : 'минуты';
    String secondsText = durationSeconds == 1 ? 'секунда' : 'секунды';

    if (durationMinutes > 0 && durationSeconds > 0) {
      return '$durationMinutes $minutesText $durationSeconds $secondsText';
    } else if (durationMinutes > 0) {
      return '$durationMinutes $minutesText';
    } else {
      return '$durationSeconds $secondsText';
    }
  }

  void onAudioSelected(AudioData audioData) {
    setState(() {
      selectedAudioData = audioData;
    });
  }

  AudioData? selectedAudioData;

  Future<List<DocumentSnapshot>> fetchCollections(int limit) async {
    try {
      String? userId = widget.currentUser?.uid;
      var querySnapshot = await FirebaseFirestore.instance
          .collection('collections')
          .where('ownerUid', isEqualTo: userId)
          .orderBy('id', descending: true)
          .limit(limit)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      log("Error fetching collections: $e");
      return [];
    }
  }

  Future<void> downloadAndShare(
    String url,
    String fileName,
  ) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Я записал крутую сказу, послушай!',
      );
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  void addToCollection(AudioData audioData) {
    onAudioSelected(audioData);
    _navigateAndDisplaySelection(context);
  }

  void deleteAudio(AudioData audioData) {
    audioData.delete().then((_) {
      setState(() {});
    }).catchError((error) {
      log("Ошибка удаления: $error");
    });
  }

  void shareAudio(AudioData audioData) {
    final url = _getAudioUrl(audioData.audioFileName);
    final fileName = audioData.audioFileName;
    downloadAndShare(url, fileName);
  }

  void _navigateAndDisplaySelection(BuildContext context) async {
    if (selectedAudioData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select an audio file first")));
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectedCollectionsPage(
          audioData: selectedAudioData,
        ),
      ),
    );

    if (result != null) {
      setState(() {});
    }
  }

  String formatDuration(int totalSeconds) {
    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;
    if (totalSeconds < 60) {
      return '$totalSeconds сек';
    } else {
      return '$minutes:${seconds.toString().padLeft(2, '0')} мин';
    }
  }

  DocumentSnapshot? latestCollection;
  DocumentSnapshot? secondLatestCollection;
  DocumentSnapshot? thirdLatestCollection;

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      fetchCollections(3).then((collections) {
        setState(() {
          if (collections.isNotEmpty) {
            latestCollection = collections[0];
          }
          if (collections.length > 1) {
            secondLatestCollection = collections[1];
          }
          if (collections.length > 2) {
            thirdLatestCollection = collections[2];
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, size: 36),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF6F6F6),
          ),
          FractionallySizedBox(
            heightFactor: 0.4,
            child: ClipPath(
              clipper: EllipseClipper(),
              child: Container(
                color: collectionsColor,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 5.0),
                  child: Builder(
                    builder: (BuildContext context) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 90),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 11.0,
                              right: 20.0,
                            ),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 5.0),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child:
                                          Text('Подборки', style: graysize24),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 10.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (FirebaseAuth
                                                    .instance.currentUser ==
                                                null) {
                                              showAuthDialog(context, () {});
                                            } else {
                                              Navigator.pushReplacement(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      const CollectionsPage(),
                                                ),
                                              );
                                              context
                                                  .read<NavigationBloc>()
                                                  .add(NavigationEvents
                                                      .collection);
                                            }
                                          },
                                          child: const Text(
                                            'Открыть все',
                                            style: graysize14,
                                            textAlign: TextAlign.end,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Positioned(
              top: 150.h,
              left: 15,
              child: thirdLatestCollection != null
                  ? CollectionCard(
                      collection: thirdLatestCollection!, isLargeCard: true)
                  : Center(
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(113, 165, 159, 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 4),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(15)),
                        width: 185.w,
                        height: 240.h,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Здесь будет\n твой набор\n сказок',
                              style: graysize20,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(
                              height: 45.h,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (FirebaseAuth.instance.currentUser == null) {
                                  showAuthDialog(context, () {});
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddCollectionsPage(),
                                    ),
                                  );
                                  context
                                      .read<NavigationBloc>()
                                      .add(NavigationEvents.collection);
                                }
                              },
                              child: const Text(
                                'Добавить',
                                style: graysize14,
                              ),
                            ),
                            Container(
                              height: 1,
                              width: 65,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    )),
          Positioned(
              top: 150.h,
              right: 15,
              child: secondLatestCollection != null
                  ? CollectionCard(collection: secondLatestCollection!)
                  : Center(
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color.fromRGBO(241, 180, 136, 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 4),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(15)),
                        width: 185.w,
                        height: 112.h,
                        child: const Center(
                          child: Text(
                            'Тут',
                            style: graysize20,
                          ),
                        ),
                      ),
                    )),
          Positioned(
              top: 278.h,
              right: 15,
              child: latestCollection != null
                  ? CollectionCard(collection: latestCollection!)
                  : Center(
                      child: Container(
                        decoration: BoxDecoration(
                            color: const Color(0x90678BD2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 4),
                                blurRadius: 20,
                                spreadRadius: 0,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(15)),
                        width: 185.w,
                        height: 112.h,
                        child: const Center(
                          child: Text(
                            'И тут',
                            style: graysize20,
                          ),
                        ),
                      ),
                    )),
          Padding(
            padding: EdgeInsets.fromLTRB(5, 430.h, 5, 0),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.0),
                  topRight: Radius.circular(25.0),
                ),
                color: grayTextColor,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x26000000),
                    offset: Offset(0, 4),
                    blurRadius: 24,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(left: 17, right: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Аудиозаписи', style: dark24),
                        GestureDetector(
                          onTap: () {
                            if (FirebaseAuth.instance.currentUser == null) {
                              showAuthDialog(context, () {});
                            } else {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AudioScreen(),
                                ),
                              );
                              context
                                  .read<NavigationBloc>()
                                  .add(NavigationEvents.audio);
                            }
                          },
                          child: const Padding(
                            padding: EdgeInsets.only(top: 9.0),
                            child: Text('Открыть все', style: dark14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: double.infinity,
                        child: StreamBuilder<List<AudioData>>(
                          stream: widget.audioStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              if (snapshot.error
                                  .toString()
                                  .contains('PERMISSION_DENIED')) {
                                return const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Ошибка доступа к данным. Пожалуйста, войдите.',
                                      style: TextStyle(
                                        fontSize: 20,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 30,
                                    ),
                                  ],
                                );
                              } else {
                                return Center(
                                  child: Text('Ошибка: ${snapshot.error}'),
                                );
                              }
                            } else {
                              final audioList = snapshot.data ?? [];
                              if (audioList.isEmpty) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                        'Как только ты запишешь\n аудио, она появится здесь.',
                                        style: opgray20),
                                    const SizedBox(
                                      height: 30,
                                    ),
                                    Image.asset(
                                        'assets/img/icon/arrow_down.png')
                                  ],
                                );
                              } else {
                                return ListView.builder(
                                  padding: const EdgeInsets.only(top: 0),
                                  itemCount: audioList.length,
                                  itemBuilder: (context, index) {
                                    final audioData = audioList[index];
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 5, 10, 0),
                                        child: Container(
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            border: Border.all(
                                                color: borderColor, width: 1.0),
                                          ),
                                          child: Row(
                                            children: [
                                              BlocBuilder<AudioCubit,
                                                  AudioState>(
                                                builder: (context, state) {
                                                  bool isCurrentPlaying = state
                                                          is AudioPlaying &&
                                                      context
                                                              .read<
                                                                  AudioCubit>()
                                                              .currentTrackIndex ==
                                                          index;
                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            5.0),
                                                    child: Container(
                                                      width: 50,
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        color: audiofileColor,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(40.0),
                                                      ),
                                                      child: IconButton(
                                                        icon: Icon(
                                                            isCurrentPlaying &&
                                                                    state
                                                                        .isPlaying
                                                                ? Icons.pause
                                                                : Icons
                                                                    .play_arrow),
                                                        iconSize: 33,
                                                        color: Colors.white,
                                                        onPressed: () {
                                                          if (isCurrentPlaying) {
                                                            context
                                                                .read<
                                                                    AudioCubit>()
                                                                .togglePlayPause();
                                                          } else {
                                                            var urls = audioList
                                                                .map((e) =>
                                                                    _getAudioUrl(
                                                                        e.audioFileName))
                                                                .toList();
                                                            var names =
                                                                audioList
                                                                    .map((e) =>
                                                                        e.name)
                                                                    .toList();
                                                            context
                                                                .read<
                                                                    AudioCubit>()
                                                                .setCurrentTrack(
                                                                    urls,
                                                                    names,
                                                                    index);
                                                          }
                                                        },
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 20),
                                              Expanded(
                                                child: audioData.isEditing
                                                    ? TextField(
                                                        autofocus: true,
                                                        controller: TextEditingController(
                                                            text:
                                                                audioData.name)
                                                          ..selection = TextSelection
                                                              .fromPosition(
                                                                  TextPosition(
                                                                      offset: audioData
                                                                          .name
                                                                          .length)),
                                                        onSubmitted: (newName) {
                                                          audioData
                                                              .rename(newName)
                                                              .then((_) {
                                                            setState(() {
                                                              audioData
                                                                      .isEditing =
                                                                  false; // Exit edit mode
                                                            });
                                                          });
                                                        },
                                                      )
                                                    : Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(audioData.name),
                                                          Text(
                                                              _formatDuration(
                                                                  audioData
                                                                      .durationMinutes,
                                                                  audioData
                                                                      .durationSeconds),
                                                              style: opgray14),
                                                        ],
                                                      ),
                                              ),
                                              AudioPopupMenu(
                                                audioFileName:
                                                    audioData.audioFileName,
                                                onRename: () => setState(() {
                                                  audioData.isEditing = true;
                                                }),
                                                onAddToCollection: () =>
                                                    addToCollection(audioData),
                                                onDelete: () =>
                                                    deleteAudio(audioData),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAudioUrl(String audioFileName) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User is not logged in.");
    }
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F$uid%2Faudio%2F$audioFileName?alt=media&token=';
  }
}
