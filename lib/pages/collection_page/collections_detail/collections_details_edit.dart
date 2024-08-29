import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/collection_page/collections.dart';

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
    return 'https://firebasestorage.googleapis.com/v0/b/memorybox2-da467.appspot.com/o/users%2FMOyYAuZQ7YdPIcEugsF8DLtzrZ13%2Faudio%2F$audioFileName?alt=media&token=';
  }
}

class CollectionDetailsEditPage extends StatefulWidget {
  final String collectionId;
  final Map<String, dynamic> collectionData;

  const CollectionDetailsEditPage({
    super.key,
    required this.collectionId,
    required this.collectionData,
  });

  @override
  CollectionDetailsEditPageState createState() =>
      CollectionDetailsEditPageState();
}

class CollectionDetailsEditPageState extends State<CollectionDetailsEditPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  AudioPlayer audioPlayer = AudioPlayer();
  List<AudioData> audioList = [];
  DocumentSnapshot? collectionData;
  int totalDurationSeconds = 0;
  bool expandedDescription = false;

  @override
  void initState() {
    super.initState();
    fetchCollection();
    _titleController.text = widget.collectionData['title'];
    _descriptionController.text = widget.collectionData['description'];
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String> uploadImageToServer(File image) async {
    String fileName =
        'collections/${widget.collectionId}/${image.path.split('/').last}';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    UploadTask uploadTask = storageRef.putFile(image);
    TaskSnapshot taskSnapshot = await uploadTask;
    String imageUrl = await taskSnapshot.ref.getDownloadURL();
    return imageUrl;
  }

  Future<void> _saveChanges() async {
    String imageUrl;
    if (_imageFile != null) {
      imageUrl = await uploadImageToServer(_imageFile!);
    } else {
      imageUrl = widget.collectionData['imageUrl'];
    }

    await FirebaseFirestore.instance
        .collection('collections')
        .doc(widget.collectionId)
        .update({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'imageUrl': imageUrl,
    });

    Navigator.pushReplacement(
      // ignore: use_build_context_synchronously
      context,
      MaterialPageRoute(
        builder: (context) => const CollectionsPage(),
      ),
    );
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
      setState(() {
        collectionData = collectionSnapshot;
        totalDurationSeconds = newTotalDurationSeconds;
      });
    }
  }

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
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveChanges,
          )
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
                  TextFormField(
                    controller: _titleController,
                    style: graysize24.copyWith(fontWeight: FontWeight.bold),
                    maxLines: null,
                  ),
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment
                              .center, // Добавляем это свойство для выравнивания по центру
                          children: [
                            Container(
                              width: double.infinity,
                              height: 240,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                image: DecorationImage(
                                  image: _imageFile != null
                                      ? FileImage(_imageFile!)
                                          as ImageProvider<Object>
                                      : NetworkImage(
                                              collectionData!['imageUrl'])
                                          as ImageProvider<Object>,
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
                            Center(
                              child: SvgPicture.asset(
                                'assets/img/icon/svg/takephoto.svg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: null,
                    style: dark14,
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  audioList.isNotEmpty
                      ? Opacity(
                          opacity: 0.5,
                          child: ListView.builder(
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
                                                icon: const Icon(
                                                  Icons.play_arrow,
                                                ),
                                                iconSize: 33,
                                                color: Colors.white,
                                                onPressed: () {},
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
                                            Text(
                                              audioData.name,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              formatDuration(
                                                audioData.durationInSeconds,
                                              ),
                                              style: opgray14,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.only(
                                            right: 25, bottom: 10),
                                        child: const Text('...',
                                            style: TextStyle(fontSize: 24)),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
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
