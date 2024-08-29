import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/collection_page/selected_collections/select_collections_from_selected_collections.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../blocs/audio_cubit/audio_cubit.dart';
import '../../../styles/colors.dart';
import '../../../styles/ellipse_clipper.dart';
import '../../../styles/fonts.dart';

class AudioData {
  final String id;
  String name;
  final int durationSeconds;
  final String audioFileName;
  final int totalDuration;
  final int durationInSeconds;
  bool isSelected = false;

  AudioData({
    required this.id,
    required this.name,
    required this.durationSeconds,
    required this.audioFileName,
    required this.totalDuration,
    required this.durationInSeconds,
  });
  bool isEditing = false;
  String get audioUrl => _getAudioUrl(audioFileName);

  factory AudioData.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>? ?? {};
    int totalSeconds =
        (data['durationMinutes'] ?? 0) * 60 + (data['durationSeconds'] ?? 0);
    return AudioData(
      id: doc.id,
      name: data['name'] ?? 'Unknown',
      durationSeconds: totalSeconds,
      audioFileName: data['audioFileName'] ?? '',
      totalDuration: totalSeconds,
      durationInSeconds: data['durationInSeconds'] ?? totalSeconds,
    );
  }

  static String _getAudioUrl(String audioFileName) {
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2FMOyYAuZQ7YdPIcEugsF8DLtzrZ13%2Faudio%2F$audioFileName?alt=media&token=';
  }
}

class SelectedAudioInCollections extends StatefulWidget {
  final String collectionId;

  const SelectedAudioInCollections({super.key, required this.collectionId});

  @override
  SelectedAudioInCollectionsState createState() =>
      SelectedAudioInCollectionsState();
}

String _getAudioUrl(String audioFileName) {
  return AudioData._getAudioUrl(audioFileName);
}

class SelectedAudioInCollectionsState
    extends State<SelectedAudioInCollections> {
  AudioPlayer audioPlayer = AudioPlayer();
  List<AudioData> audioList = [];
  DocumentSnapshot? collectionData;
  int totalDurationSeconds = 0;
  bool expandedDescription = false;

  @override
  void initState() {
    super.initState();
    fetchCollection();
  }

  Future<void> shareSelectedAudios() async {
    List<String> filePaths = [];
    List<XFile> xFiles = [];
    String shareText = 'Поделитесь выбранными аудиозаписями.';

    final dir = await getApplicationDocumentsDirectory();
    final localContext = context;

    try {
      for (var audio in audioList.where((item) => item.isSelected)) {
        final response = await http.get(Uri.parse(audio.audioUrl));
        if (response.statusCode == 200) {
          String extension = audio.audioFileName.split('.').last;
          final trackName =
              audio.name.replaceAll(' ', '_').replaceAll('/', '_');
          final filePath = '${dir.path}/$trackName.$extension';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes, flush: true);
          filePaths.add(filePath);
          xFiles.add(XFile(filePath));
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }

      if (!mounted) return;

      if (filePaths.isNotEmpty) {
        await Share.shareXFiles(xFiles, text: shareText);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(localContext).showSnackBar(
          const SnackBar(
              content: Text('Нет выбранных аудиозаписей для отправки')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(localContext).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке и отправке файлов: $e')),
      );
    }
  }

  void fetchCollection() async {
    var collectionSnapshot = await FirebaseFirestore.instance
        .collection('collections')
        .doc(widget.collectionId)
        .get();

    if (collectionSnapshot.exists) {
      var audioFilesData = List<Map<String, dynamic>>.from(
          collectionSnapshot.data()?['audioFiles'] ?? []);
      audioList = await fetchAudios(audioFilesData);
      int newTotalDurationSeconds = 0;
      for (var audio in audioList) {
        newTotalDurationSeconds += audio.durationInSeconds;
      }
      if (!mounted) return;
      setState(() {
        collectionData = collectionSnapshot;
        totalDurationSeconds = newTotalDurationSeconds;
      });
    }
  }

  void addToSelectedCollection() {
    List<AudioData> selectedAudios =
        audioList.where((audio) => audio.isSelected).toList();
    if (selectedAudios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Не выбрано аудиозаписей для добавления в подборку")));
      return;
    }

    navigateAndDisplayCollectionSelection(context, selectedAudios);
  }

  void navigateAndDisplayCollectionSelection(
      BuildContext context, List<AudioData> selectedAudios) async {
    void showSnackBar(String text) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(text)));
      }
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SelectedCollectionsPage(audioData: selectedAudios),
      ),
    );

    showSnackBar(result != null
        ? "Аудиозаписи добавлены в подборку"
        : "Аудиозаписи не добавлены");
  }

  Future<void> downloadSelectedAudios() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

    if (selectedDirectory == null) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Папка для сохранения не выбрана')),
      );
      return;
    }

    List<String> downloadedFiles = [];
    for (var audio in audioList.where((item) => item.isSelected)) {
      try {
        final response = await http.get(Uri.parse(audio.audioUrl));
        if (response.statusCode == 200) {
          String extension = audio.audioFileName.split('.').last;
          final fileName =
              "${audio.name.replaceAll(' ', '_').replaceAll('/', '_')}.$extension";
          final filePath = '$selectedDirectory/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes, flush: true);
          downloadedFiles.add(filePath);
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Ошибка при загрузке файла: ${audio.name}, $e')),
        );
      }
    }
    if (downloadedFiles.isNotEmpty) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Выбранные аудиозаписи были успешно сохранены')),
      );
    } else {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Не удалось скачать выбранные аудиозаписи')),
      );
    }
  }

  void deleteSelectedAudios() {
    List<Map<String, dynamic>> selectedAudiosToRemove = audioList
        .where((audio) => audio.isSelected)
        .map((audio) => {
              'audioFileName': audio.audioFileName,
              'durationInSeconds': audio.durationInSeconds
            })
        .toList();

    if (selectedAudiosToRemove.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('collections')
          .doc(widget.collectionId)
          .update({
        'audioFiles': FieldValue.arrayRemove(selectedAudiosToRemove)
      }).then((_) {
        setState(() {
          audioList.removeWhere((audio) => audio.isSelected);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Выбранные аудиозаписи успешно удалены')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка удаления: $error')),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не выбрано аудиозаписей для удаления')),
      );
    }
  }

  Future<List<AudioData>> fetchAudios(
      List<Map<String, dynamic>> audioFilesData) async {
    List<AudioData> audios = [];
    for (var fileData in audioFilesData) {
      try {
        var audioSnapshot = await FirebaseFirestore.instance
            .collection('audio_files')
            .where('audioFileName', isEqualTo: fileData['audioFileName'])
            .get();

        if (audioSnapshot.docs.isNotEmpty) {
          for (var doc in audioSnapshot.docs) {
            var audio = AudioData.fromFirestore(doc);
            log("Audio name: ${audio.name}, Duration: ${audio.durationSeconds}");
            audios.add(audio);
          }
        }
      } catch (e) {
        log("Error fetching audio data for ${fileData['audioFileName']}: $e");
      }
    }
    return audios;
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    super.dispose();
  }

  void playAll() async {
    var urls = audioList.map((audio) => audio.audioUrl).toList();
    var concatenation = ConcatenatingAudioSource(
      children: urls.map((url) => AudioSource.uri(Uri.parse(url))).toList(),
    );
    await audioPlayer.setAudioSource(concatenation);
    audioPlayer.play();
  }

  String formatDuration(int totalSeconds) {
    if (totalSeconds == 0) {
      return '0 секунд';
    }

    final int minutes = totalSeconds ~/ 60;
    final int seconds = totalSeconds % 60;

    String minuteString = _pluralize(minutes, 'минута', 'минуты', 'минут');
    String secondString = _pluralize(seconds, 'секунда', 'секунды', 'секунд');

    if (minutes == 0) {
      return '$seconds $secondString';
    } else if (seconds == 0) {
      return '$minutes $minuteString';
    } else {
      return '$minutes $minuteString $seconds $secondString';
    }
  }

  String _pluralize(int value, String form1, String form2, String form5) {
    if (value % 10 == 1 && value % 100 != 11) {
      return form1;
    } else if (value % 10 >= 2 &&
        value % 10 <= 4 &&
        (value % 100 < 10 || value % 100 >= 20)) {
      return form2;
    } else {
      return form5;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (collectionData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    String formattedDate = DateFormat('dd.MM.yy')
        .format((collectionData!['timestamp'] as Timestamp).toDate());
    int audioCount = audioList.length;
    String totalDurationFormatted = formatDuration(totalDurationSeconds);
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: SizedBox(
                  width: 70,
                  height: 70,
                  child: SvgPicture.asset('assets/img/icon/customback.svg',
                      fit: BoxFit.contain),
                ),
              ),
            );
          },
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'cancel':
                  Navigator.pop(context);
                  break;
                case 'inCollection':
                  addToSelectedCollection();
                  break;
                case 'share':
                  shareSelectedAudios();
                  break;
                case 'download':
                  downloadSelectedAudios();
                  break;
                case 'delete':
                  deleteSelectedAudios();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'cancel',
                child: Text('Отменить выбор'),
              ),
              const PopupMenuItem<String>(
                value: 'inCollection',
                child: Text('Добавить в подборку'),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Text('Поделиться'),
              ),
              const PopupMenuItem<String>(
                value: 'download',
                child: Text('Скачать все'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Удалить все'),
              ),
            ],
            icon: Image.asset('assets/img/icon/dots.png', height: 13),
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFF6F6F6),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: 200,
              child: ClipPath(
                clipper: EllipseClipper(),
                child: Container(
                  color: primaryColor,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, left: 5.0),
                    child: Builder(
                      builder: (BuildContext context) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 85),
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 11.0, right: 20.0),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
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
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    collectionData!['title'],
                    style: graysize24.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: DecorationImage(
                            image: NetworkImage(collectionData!['imageUrl']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color.fromRGBO(69, 69, 69, 1),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 25,
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 25,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$audioCount аудио',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              totalDurationFormatted,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  audioList.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: audioList.length,
                          itemBuilder: (context, index) {
                            final audioData = audioList[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    audioData.isSelected =
                                        !audioData.isSelected;
                                  });
                                },
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(40),
                                    border: Border.all(
                                      color: borderColor,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      BlocBuilder<AudioCubit, AudioState>(
                                        builder: (context, state) {
                                          bool isCurrentPlaying =
                                              state is AudioPlaying &&
                                                  context
                                                          .read<AudioCubit>()
                                                          .currentTrackIndex ==
                                                      index;
                                          return Padding(
                                            padding: const EdgeInsets.all(5.0),
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius:
                                                    BorderRadius.circular(40.0),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  isCurrentPlaying &&
                                                          state.isPlaying
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                ),
                                                iconSize: 33,
                                                color: Colors.white,
                                                onPressed: () {
                                                  if (isCurrentPlaying) {
                                                    context
                                                        .read<AudioCubit>()
                                                        .togglePlayPause();
                                                  } else {
                                                    var urls = audioList
                                                        .map((e) =>
                                                            _getAudioUrl(e
                                                                .audioFileName))
                                                        .toList();
                                                    var names = audioList
                                                        .map((e) => e.name)
                                                        .toList();
                                                    context
                                                        .read<AudioCubit>()
                                                        .setCurrentTrack(
                                                          urls,
                                                          names,
                                                          index,
                                                        );
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(audioData.name),
                                            Text(
                                              formatDuration(
                                                audioData.durationInSeconds,
                                              ),
                                              style: opgray14,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: SvgPicture.asset(
                                          audioData.isSelected
                                              ? 'assets/img/icon/svg/selected.svg'
                                              : 'assets/img/icon/svg/circlesel.svg',
                                          width: 50,
                                          height: 50,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Text("No audio files found."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void playAudio(String url) async {
    await audioPlayer.setUrl(url);
    audioPlayer.play();
  }
}
