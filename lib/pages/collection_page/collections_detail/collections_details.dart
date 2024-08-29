import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/collection_page/selected_collections/select_collection_from_collections.dart';
import 'package:memory_box/pages/home_screen/homescreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../blocs/audio_cubit/audio_cubit.dart';
import '../../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../../styles/colors.dart';
import '../../../styles/ellipse_clipper.dart';
import '../../../styles/fonts.dart';
import '../../../widgets/audio_popup_menu.dart';
import 'collections_details_edit.dart';
import 'collections_details_selected.dart';

class AudioData {
  final String id;
  String name;
  final int durationSeconds;
  final String audioFileName;
  final int totalDuration;
  final int durationInSeconds;

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

  Future<void> rename(String newName) async {
    name = newName;
    await FirebaseFirestore.instance
        .collection('audio_files')
        .doc(id)
        .update({'name': newName});
  }

  Future<void> delete() async {
    await FirebaseFirestore.instance.collection('audio_files').doc(id).delete();
  }

  static String _getAudioUrl(String audioFileName) {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw Exception("User is not logged in.");
    }

    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2F$uid%2Faudio%2F$audioFileName?alt=media&token=';
  }
}

class CollectionDetailsPage extends StatefulWidget {
  final String collectionId;

  const CollectionDetailsPage({super.key, required this.collectionId});

  @override
  CollectionDetailsPageState createState() => CollectionDetailsPageState();
}

String _getAudioUrl(String audioFileName) {
  return AudioData._getAudioUrl(audioFileName);
}

class CollectionDetailsPageState extends State<CollectionDetailsPage> {
  AudioPlayer audioPlayer = AudioPlayer();

  List<AudioData> audioList = [];
  DocumentSnapshot? collectionData;
  int totalDurationSeconds = 0;
  bool expandedDescription = false;

  @override
  void initState() {
    super.initState();
    fetchCollection().then((_) {
      List<String> urls =
          audioList.map((e) => _getAudioUrl(e.audioFileName)).toList();
      List<String> names = audioList.map((e) => e.name).toList();
      context.read<AudioCubit>().setTracks(urls, names);
    });
  }

  Future<void> fetchCollection() async {
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
      setState(() {
        collectionData = collectionSnapshot;
        totalDurationSeconds = newTotalDurationSeconds;
      });
    }
  }

  void addToCollection(AudioData audioData) {
    onAudioSelected(audioData);
    _navigateAndDisplaySelection(context);
  }

  void onAudioSelected(AudioData audioData) {
    setState(() {
      selectedAudioData = audioData;
    });
  }

  AudioData? selectedAudioData;

  Future<List<DocumentSnapshot>> fetchCollections(int limit) async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('collections')
          .orderBy('id', descending: true)
          .limit(limit)
          .get();
      return querySnapshot.docs;
    } catch (e) {
      log("Error fetching collections: $e");
      return [];
    }
  }

  Future<void> downloadAndShare(String url, String fileName) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes, flush: true);
      await Share.shareXFiles([XFile(filePath)],
          text: 'Я записал крутую сказу, послушай!');
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  Future<void> showDeleteCollectionConfirmationDialog(
      BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap a button to close the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
            child: Text(
              'Подтверждаете удаление?',
              style: TextStyle(color: errorColor, fontSize: 20),
            ),
          ),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(
                  child: Text(
                    'Ваш файл перенесется в папку “Недавно удаленные”. Через 15 дней он исчезнет.',
                    style: TextStyle(
                      color: Color.fromRGBO(58, 58, 85, 0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        collectionsColor,
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all(
                        const Size(121, 40),
                      ),
                    ),
                    onPressed: () async {
                      deleteCollection();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => const HomeScreen()));
                      context.read<NavigationBloc>().add(NavigationEvents.home);
                    },
                    child: const Text(
                      'Да',
                      style: TextStyle(color: grayTextColor),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      minimumSize: MaterialStateProperty.all(
                        const Size(85, 40),
                      ),
                      side: MaterialStateProperty.all(
                        const BorderSide(color: collectionsColor, width: 2),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop(); // Just close the dialog
                    },
                    child: const Text(
                      'Нет',
                      style: TextStyle(color: collectionsColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void deleteCollection() async {
    final localContext = context;

    try {
      await FirebaseFirestore.instance
          .collection('collections')
          .doc(widget.collectionId)
          .delete();

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.pop(localContext);
    } catch (e) {
      if (!mounted) return;

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(localContext).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении подборки: $e')),
      );
    }
  }

  void deleteAudio(AudioData audioData) {
    FirebaseFirestore.instance
        .collection('collections')
        .doc(widget.collectionId)
        .update({
      'audioFiles': FieldValue.arrayRemove([
        {
          'audioFileName': audioData.audioFileName,
          'durationInSeconds': audioData.durationInSeconds
        }
      ])
    }).then((_) {
      setState(() {
        audioList.removeWhere((item) => item.id == audioData.id);
      });
    });
  }

  Future<void> downloadAndShareCollection() async {
    List<XFile> xFiles = [];
    String shareText = 'Посмотрите на эту подборку!';

    final dir = await getApplicationDocumentsDirectory();

    try {
      for (var audio in audioList) {
        final response = await http.get(Uri.parse(audio.audioUrl));
        if (response.statusCode == 200) {
          String extension = audio.audioFileName.split('.').last;
          final trackName =
              audio.name.replaceAll(' ', '_').replaceAll('/', '_');
          final filePath = '${dir.path}/$trackName.$extension';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes, flush: true);
          xFiles.add(XFile(filePath));
        } else {
          throw Exception('Failed to download file: ${response.statusCode}');
        }
      }

      Map<String, dynamic>? data =
          collectionData!.data() as Map<String, dynamic>?;

      if (data != null && data.containsKey('imageUrl')) {
        final imageUrl = data['imageUrl'] as String?;
        if (imageUrl != null) {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            String extension = 'jpg';
            if (response.headers['content-type'] != null) {
              switch (response.headers['content-type']) {
                case 'image/jpeg':
                  extension = 'jpg';
                  break;
                case 'image/png':
                  extension = 'png';
                  break;
                case 'image/gif':
                  extension = 'gif';
                  break;
              }
            }
            final imageFileName = 'photo.$extension';
            final imageFilePath = '${dir.path}/$imageFileName';
            final imageFile = File(imageFilePath);
            await imageFile.writeAsBytes(response.bodyBytes, flush: true);
            xFiles.add(XFile(imageFilePath));
          } else {
            throw Exception('Failed to download image: ${response.statusCode}');
          }
        }
      }

      if (data != null && data.containsKey('title')) {
        shareText += ' Название: ${data['title']}';
      }

      if (xFiles.isNotEmpty) {
        await Share.shareXFiles(xFiles, text: shareText);
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Нет файлов для отправки')),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при загрузке и отправке файлов: $e')),
      );
    }
  }

  void shareAudio(AudioData audioData) {
    final url = AudioData._getAudioUrl(audioData.audioFileName);
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
    Widget descriptionWidget;
    int wordCount = collectionData!['description'].split(' ').length;

    if (wordCount > 50 && !expandedDescription) {
      descriptionWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            collectionData!['description'],
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: dark14,
          ),
          TextButton(
            onPressed: () {
              setState(() {
                expandedDescription = true;
              });
            },
            child: Center(
                child: Text(
              'Подробнее',
              style: dark14.copyWith(height: 1),
            )),
          ),
        ],
      );
    } else {
      descriptionWidget = Text(
        collectionData!['description'],
        style: dark14,
      );
    }
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
                case 'edit':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CollectionDetailsEditPage(
                        collectionId: widget.collectionId,
                        collectionData:
                            collectionData?.data() as Map<String, dynamic>,
                      ),
                    ),
                  );
                  break;
                case 'select':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectedAudioInCollections(
                        collectionId: widget.collectionId,
                      ),
                    ),
                  );
                  break;
                case 'delete':
                  showDeleteCollectionConfirmationDialog(context);

                  break;
                case 'share':
                  downloadAndShareCollection();
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'edit',
                child: Text('Редактировать'),
              ),
              const PopupMenuItem<String>(
                value: 'select',
                child: Text('Выбрать несколько'),
              ),
              const PopupMenuItem<String>(
                value: 'delete',
                child: Text('Удалить подборку'),
              ),
              const PopupMenuItem<String>(
                value: 'share',
                child: Text('Поделиться'),
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
                        bottom: 20,
                        right: 20,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            BlocProvider.of<AudioCubit>(context)
                                .playAllTracks(false);
                          },
                          icon: Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Container(
                              width: 35,
                              height: 35,
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.8),
                                borderRadius: BorderRadius.circular(40.0),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                          label: const SizedBox(
                              width: 130,
                              child: Text('Запустить все',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          Color.fromRGBO(255, 255, 255, 0.8)))),
                          style: ElevatedButton.styleFrom(
                            fixedSize: const Size(165, 45),
                            shadowColor:
                                const Color.fromRGBO(255, 255, 255, 0.15),
                            elevation: 10,
                            backgroundColor:
                                const Color.fromRGBO(246, 246, 246, 0.16),
                            padding: EdgeInsets.zero,
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
                  descriptionWidget,
                  audioList.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          itemCount: audioList.length,
                          itemBuilder: (context, index) {
                            final audioData = audioList[index];
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
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
                                                      .map((e) => _getAudioUrl(
                                                          e.audioFileName))
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
                                      child: audioData.isEditing
                                          ? TextField(
                                              autofocus: true,
                                              controller: TextEditingController(
                                                  text: audioData.name)
                                                ..selection =
                                                    TextSelection.fromPosition(
                                                  TextPosition(
                                                      offset: audioData
                                                          .name.length),
                                                ),
                                              onSubmitted: (newName) {
                                                audioData
                                                    .rename(newName)
                                                    .then((_) {
                                                  setState(() {
                                                    audioData.isEditing = false;
                                                  });
                                                });
                                              },
                                            )
                                          : Column(
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
                                    AudioPopupMenu(
                                      audioFileName: audioData.audioFileName,
                                      onRename: () => setState(() {
                                        audioData.isEditing = true;
                                      }),
                                      onAddToCollection: () =>
                                          addToCollection(audioData),
                                      onDelete: () => deleteAudio(audioData),
                                    ),
                                  ],
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
}
