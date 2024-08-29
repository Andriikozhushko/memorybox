import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/collection_page/collections.dart';

import '../../../styles/colors.dart';
import '../../../styles/ellipse_clipper.dart';
import '../../../styles/fonts.dart';
import '../cubit/selected_cubit.dart';
import 'add_audio_to_collections.dart';

class AddCollectionsPage extends StatefulWidget {
  const AddCollectionsPage({super.key});

  @override
  AddCollectionsPageState createState() => AddCollectionsPageState();
}

class AddCollectionsPageState extends State<AddCollectionsPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  List<AudioDataSec> selectedAudioFiles = [];
  File? imageFile;
  String? imageUrl;
  late AudioPlayer player;
  late SelectedAudioCubit selectedAudioCubit;

  @override
  void initState() {
    super.initState();
    player = AudioPlayer();
    selectedAudioCubit = context.read<SelectedAudioCubit>();
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File file = File(pickedFile.path);
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        String filePath =
            'users/$userId/collectionscoverimg/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
        firebase_storage.UploadTask uploadTask = firebase_storage
            .FirebaseStorage.instance
            .ref()
            .child(filePath)
            .putFile(file);

        final snapshot = await uploadTask.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();

        setState(() {
          imageFile = file;
          imageUrl = url;
        });
      } catch (e) {
        log("Error uploading image: $e");
      }
    }
  }

  void navigateAndSelectAudio() async {
    var selectedAudios = await Navigator.push<List<AudioDataSec>>(
      context,
      MaterialPageRoute(builder: (_) => const AddAudioCollectionsPage()),
    );
    if (selectedAudios != null) {
      selectedAudioFiles = selectedAudios;
      setState(() {});
    }
  }

  Future<void> toggleAudio(AudioDataSec audio) async {
    if (player.playing) {
      await player.stop();
    }
    try {
      await player.setUrl(audio.audioUrl);
      await player.play();
    } catch (e) {
      log('Error loading audio: $e');
    }
  }

  void removeAudio(AudioDataSec audio) {
    selectedAudioCubit.removeSelectedAudio(audio);
  }

  Future<void> saveCollection() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название коллекции'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте фотографию для коллекции'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedAudioCubit.state.audioDataSecs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте аудиозапись к коллекции'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      log("User is not logged in");
      return;
    }

    var selectedAudios = selectedAudioCubit.state.audioDataSecs;
    var audioFiles = selectedAudios.map((audio) {
      return {
        'audioFileName': audio.audioFileName,
        'durationInSeconds': audio.totalDurationInSeconds
      };
    }).toList();

    var totalDuration = selectedAudios.fold<int>(
        0, (int sum, audio) => sum + audio.totalDurationInSeconds);

    try {
      DocumentReference counterRef = FirebaseFirestore.instance
          .collection('counters')
          .doc('collectionCounter');
      DocumentSnapshot counterSnap = await counterRef.get();
      int currentId = 0;
      if (counterSnap.exists && counterSnap.data() is Map<String, dynamic>) {
        var data = counterSnap.data() as Map<String, dynamic>;
        currentId = data['currentId'] ?? 0;
      }
      int newId = currentId + 1;

      await FirebaseFirestore.instance.collection('collections').add({
        'id': newId,
        'ownerUid': userId,
        'title': titleController.text,
        'description': descriptionController.text,
        'imageUrl': imageUrl,
        'audioFiles': audioFiles,
        'totalDuration': totalDuration,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await counterRef.set({'currentId': newId});

      selectedAudioCubit.clearSelectedAudio();

      Navigator.push(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const CollectionsPage()),
      );
    } catch (e) {
      log("Error saving collection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectedAudioCubit, SelectedState>(
        builder: (context, state) {
      var selectedAudioFiles = state.audioDataSecs;
      return Scaffold(
        extendBodyBehindAppBar: true,
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
                    width: 60,
                    height: 60,
                    child: SvgPicture.asset('assets/img/icon/customback.svg',
                        fit: BoxFit.contain),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: saveCollection,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 17.0),
                    child: Text(
                      'Готово',
                      style: graysize16.copyWith(height: 1),
                    ),
                  ),
                ],
              ),
            )
          ],
          centerTitle: true,
          title: const Padding(
              padding: EdgeInsets.only(top: 0.0),
              child: Text('Подборки', style: graysize36)),
        ),
        body: Stack(
          children: [
            Container(color: grayTextColor),
            SizedBox(
                height: 300,
                child: ClipPath(
                    clipper: EllipseClipper(),
                    child: Container(color: primaryColor))),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              top: 140,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                            hintText: 'Название...',
                            hintStyle: graysize24.copyWith(
                                fontWeight: FontWeight.w700),
                            border: InputBorder.none),
                        style:
                            graysize24.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: imageFile != null
                              ? DecorationImage(
                                  image: FileImage(imageFile!),
                                  fit: BoxFit.cover)
                              : null,
                          color: const Color(0x99F6F6F6),
                          boxShadow: const [
                            BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.25),
                                offset: Offset(0, 4),
                                blurRadius: 20,
                                spreadRadius: 0)
                          ],
                        ),
                        child: imageFile == null
                            ? const Icon(Icons.add_photo_alternate,
                                size: 50, color: Colors.grey)
                            : null,
                      ),
                    ),
                    TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                            labelText: 'Введите описание...',
                            alignLabelWithHint: true),
                        maxLines: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          child: Container(
                            padding: EdgeInsets.zero,
                            child: Text('Готово',
                                style: dark16.copyWith(height: 1)),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: navigateAndSelectAudio,
                        child: Container(
                          decoration: const BoxDecoration(
                              border: Border(
                            bottom: BorderSide(width: 1, color: Colors.black),
                          )),
                          child:
                              const Text('Добавить аудиофайл', style: dark14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (selectedAudioFiles.isNotEmpty) ...[
                      const Text("Выбранные аудиозаписи:",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      ...selectedAudioFiles.map((audio) => Padding(
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
                              child: ListTile(
                                title: Text(audio.name),
                                leading: Transform.translate(
                                  offset: const Offset(-10, 0),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      iconSize: 33,
                                      color: Colors.white,
                                      onPressed: () => toggleAudio(audio),
                                    ),
                                  ),
                                ),
                                trailing: Transform.translate(
                                  offset: const Offset(16, 0),
                                  child: IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () => removeAudio(audio),
                                  ),
                                ),
                              ),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
