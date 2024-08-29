import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:memory_box/pages/profile_screen/main.dart';

import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/drawer.dart';

class EditProfilePage extends StatefulWidget {
  final VoidCallback? onCancelEdit;

  const EditProfilePage({super.key, this.onCancelEdit});

  @override
  EditProfilePageState createState() => EditProfilePageState();
}

class EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  File? _image;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();
  final maskFormatter = MaskTextInputFormatter(
    mask: '+380 (##) ### ## ##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final docSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (docSnapshot.exists) {
      final data = docSnapshot.data();
      _nameController.text = data?['name'] ?? '';
      _imageUrl = data?['imageUrl'];

      if (_imageUrl != null && !_imageUrl!.startsWith('http')) {
        _image = File(_imageUrl!);
      }
      setState(() {});
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path);
        _imageUrl = null;
      });
    }
  }

  Future<void> _uploadProfileData() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    String? imageUrl = _imageUrl;
    if (_image != null && _imageUrl == null) {
      final ref =
          FirebaseStorage.instance.ref().child('user_images').child(userId);
      await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    }

    FirebaseFirestore.instance.collection('users').doc(userId).set({
      'name': _nameController.text.trim(),
      'imageUrl': imageUrl ?? 'default_image_path',
    }, SetOptions(merge: true)).then((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainProfilePage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
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
        centerTitle: true,
        title: const Padding(
          padding: EdgeInsets.only(top: 10.0),
          child: Text('Профиль', style: graysize36),
        ),
      ),
      drawer: const CustomDrawer(),
      body: Stack(
        children: [
          Container(color: const Color(0xFFF6F6F6)),
          FractionallySizedBox(
            heightFactor: 0.4,
            child: ClipPath(
              clipper: EllipseClipper(),
              child: Container(color: const Color(0xFF8C84E2)),
            ),
          ),
          Positioned(
            top: 140,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 228, maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              width: 228,
                              height: 228,
                              color: primaryColor.withOpacity(0.9),
                              child: _image != null
                                  ? Image.file(_image!, fit: BoxFit.cover)
                                  : (_imageUrl != null
                                      ? Image.network(_imageUrl!,
                                          fit: BoxFit.cover)
                                      : Image.asset(
                                          'assets/img/defaultavatar.jpg',
                                          fit: BoxFit.cover)),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            width: 228,
                            height: 228,
                          ),
                          Positioned(
                            top: 70,
                            left: 70,
                            right: 70,
                            bottom: 70,
                            child: SizedBox(
                              width: 100,
                              height: 100,
                              child: SvgPicture.asset(
                                'assets/img/icon/svg/takephoto.svg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: 180,
                      child: TextFormField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        style: dark24,
                        decoration: const InputDecoration(
                          hintText: 'Введите имя...',
                          hintStyle: dark24,
                          enabledBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: borderColor, width: 1.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 80,
                    ),
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        if (state is AuthLoggedInState) {
                          return Container(
                            width: 300,
                            height: 62,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: grayTextColor,
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2B000000),
                                  offset: Offset(0, 4),
                                  blurRadius: 11,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                maskFormatter.maskText(
                                    state.firebaseUser.phoneNumber ??
                                        'Номер телефона не найден'),
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        } else {
                          return Container();
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                    TextButton(
                      onPressed: _uploadProfileData,
                      child: const Text('Сохранить', style: dark14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
