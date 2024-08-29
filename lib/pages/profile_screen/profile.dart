import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:memory_box/pages/auth_screens/start_screen.dart';
import 'package:memory_box/pages/profile_screen/profile_edit.dart';

import '../../blocs/auth_bloc/auth_bloc.dart';
import '../../blocs/auth_bloc/auth_event.dart';
import '../../blocs/auth_bloc/auth_state.dart';
import '../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../main.dart';
import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/drawer.dart';
import '../subscribe_screen/subscribe.dart';

class ProfilePage extends StatefulWidget {
  final Function(String) onSwitch;
  final VoidCallback onEditProfile;

  const ProfilePage(
      {super.key, required this.onSwitch, required this.onEditProfile});

  @override
  ProfilePageState createState() => ProfilePageState();
}

final maskFormatter = MaskTextInputFormatter(
  mask: '+380 (##) ### ## ##',
  filter: {"#": RegExp(r'[0-9]')},
);

class ProfilePageState extends State<ProfilePage> {
  String? _userName = 'Загрузка...';
  String? _userImageUrl = 'assets/img/defaultavatar.jpg';
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final String userId = FirebaseAuth.instance.currentUser!.uid;
    final docSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    setState(() {
      _userName = docSnapshot.data()?['name'] ?? 'Нет имени';
      _userImageUrl =
          docSnapshot.data()?['imageUrl'] ?? 'assets/img/defaultavatar.jpg';
    });
  }

  Future<void> deleteFolderContents(String folderPath) async {
    final ref = FirebaseStorage.instance.ref(folderPath);
    final result = await ref.listAll();

    for (var item in result.items) {
      log('Deleting file: ${item.fullPath}');
      await item.delete();
    }

    for (var prefix in result.prefixes) {
      log('Entering folder: ${prefix.fullPath}');
      await deleteFolderContents(prefix.fullPath);
    }
  }

  void deleteAccount(BuildContext context) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final String? userId = auth.currentUser?.uid;

    if (userId == null) {
      log('No user logged in.');
      return;
    }

    try {
      await auth.signOut();
      // ignore: use_build_context_synchronously
      BlocProvider.of<AuthBloc>(context).add(const LogOutEvent());
      log('User signed out.');

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        // ignore: use_build_context_synchronously
        context,
        MaterialPageRoute(builder: (context) => const StartScreen()),
        (Route<dynamic> route) => false,
      );

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final String userFolderPath = 'users/$userId';
      await deleteFolderContents(userFolderPath);
      log('User folder and files deleted: $userFolderPath');

      final userDocRef = firestore.collection('users').doc(userId);
      await userDocRef.delete();
      log('Firestore user data deleted for: $userId');

      final collectionQuery = firestore
          .collection('collections')
          .where('ownerUid', isEqualTo: userId)
          .get();
      final collectionDocs = await collectionQuery;
      for (var doc in collectionDocs.docs) {
        await doc.reference.delete();
        log('Deleted collection owned by user: ${doc.id}');
      }

      final audioFilesQuery = firestore
          .collection('audio_files')
          .where('uid', isEqualTo: userId)
          .get();
      final audioFilesDocs = await audioFilesQuery;
      for (var doc in audioFilesDocs.docs) {
        await doc.reference.delete();
        log('Deleted audio file owned by user: ${doc.id}');
      }
    } catch (e) {
      log('Error during account deletion: $e');
    }
  }

  Future<void> showDeleteAccountConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Center(
              child: Text(
            'Точно удалить аккаунт?',
            style: TextStyle(color: fontColor, fontSize: 20),
          )),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Center(
                  child: Text(
                    'Все аудиофайлы исчезнут и восстановить аккаунт будет невозможно.',
                    style: TextStyle(
                        color: Color.fromRGBO(58, 58, 85, 0.7), fontSize: 14),
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
                          const Color.fromRGBO(226, 119, 119, 1)),
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50))),
                      minimumSize:
                          MaterialStateProperty.all(const Size(121, 40)),
                    ),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      deleteAccount(context);
                    },
                    child: const Text('Удалить',
                        style: TextStyle(color: grayTextColor)),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    style: ButtonStyle(
                      shape: MaterialStateProperty.all(RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50))),
                      minimumSize:
                          MaterialStateProperty.all(const Size(85, 40)),
                      side: MaterialStateProperty.all(
                          const BorderSide(color: collectionsColor, width: 2)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Нет',
                        style: TextStyle(color: collectionsColor)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
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
          centerTitle: true,
          title: const Padding(
            padding: EdgeInsets.only(top: 10.0),
            child: Text(
              'Профиль',
              style: graysize36,
            ),
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
                color: const Color(0xFF8C84E2),
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
                              left: 11.0,
                              right: 20.0,
                            ),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width,
                              child: const Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 5.0),
                                      child: Text(
                                        'Твоя частичка',
                                        style: graysize16,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ],
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
            top: 140,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: 228,
                  maxWidth: 400,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        width: 228.w,
                        height: 228.h,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.9),
                        ),
                        child: _userImageUrl!.startsWith('http')
                            ? Image.network(
                                _userImageUrl!,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                _userImageUrl!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      _userName!,
                      style: dark24,
                    ),
                    SizedBox(height: 20.h),
                    Column(
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthLoggedInState) {
                              return Container(
                                width: 300.w,
                                height: 62.h,
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
                        SizedBox(
                          height: 20.h,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const EditProfilePage()),
                            );
                          },
                          child: const Text(
                            'Редактировать профиль',
                            style: dark14,
                          ),
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SubscribePage(),
                              ),
                            );

                            context
                                .read<NavigationBloc>()
                                .add(NavigationEvents.profile);
                          },
                          child: Text(
                            'Подписка',
                            style: dark14.copyWith(
                              height: 1,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4.0),
                          width: 67.w,
                          height: 1.0,
                          color: fontColor,
                        ),
                        SizedBox(
                          height: 20.h,
                        ),
                        Container(
                          height: 24.h,
                          width: 300.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: fontColor, width: 2),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: 90.w,
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  color: Color(0xFFF1B488),
                                ),
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    width: 210.w,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        const Text(
                          '150/500 мб',
                          style: dark14,
                        ),
                        SizedBox(
                          height: 10.h,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              BlocConsumer<AuthBloc, AuthState>(
                                listener: (context, state) {
                                  if (state is AuthLoggedOutState) {
                                    navigatorKey.currentState!
                                        .pushAndRemoveUntil(
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const StartScreen()),
                                      (Route<dynamic> route) => false,
                                    );
                                    /*final bottomNavBarVisibilityCubit = context
                                        .read<BottomNavBarVisibilityCubit>();
                                    bottomNavBarVisibilityCubit
                                        .hideBottomNavBar();*/
                                  }
                                },
                                builder: (context, state) {
                                  final isAuthenticated =
                                      state is AuthLoggedInState;
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: isAuthenticated
                                            ? () {
                                                BlocProvider.of<AuthBloc>(
                                                        context)
                                                    .add(const LogOutEvent());
                                              }
                                            : null,
                                        child: const Text(
                                          'Выйти из приложения',
                                          style: dark14,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              TextButton(
                                onPressed: () {
                                  showDeleteAccountConfirmationDialog(context);
                                },
                                child: const Text(
                                  'Удалить аккаунт',
                                  style: red14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
