import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:memory_box/pages/audio_screen/audiolist_page.dart';
import 'package:memory_box/pages/collection_page/collections.dart';
import 'package:memory_box/pages/deleted_recently_screen/deleted_recently_screen.dart';
import 'package:memory_box/pages/home_screen/homescreen_body.dart';
import 'package:memory_box/pages/profile_screen/main.dart';
import 'package:url_launcher/url_launcher.dart';

import '../blocs/navigation_bloc/navigation_bloc.dart';
import '../pages/home_screen/models/audio_data.dart';
import '../pages/search_screen/search_screen.dart';
import '../pages/subscribe_screen/subscribe.dart';
import 'auth_dialog.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer> {
  late User? currentUser;
  late Stream<List<AudioData>> audioStream;

  Stream<List<AudioData>> _loadAudioStream() {
    return FirebaseFirestore.instance
        .collection('audio_files')
        .where('uid', isEqualTo: currentUser!.uid)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AudioData.fromFirestore(doc)).toList());
  }

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    audioStream = currentUser != null
        ? _loadAudioStream()
        : const Stream<List<AudioData>>.empty();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF6F6F6),
      child: ListView(
        padding: const EdgeInsets.only(top: 90),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Аудиосказки',
                  style: TextStyle(
                    fontSize: 24,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Меню',
                  style: TextStyle(
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 80,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeBody(
                      currentUser: currentUser,
                      audioStream: audioStream,
                    ),
                  ),
                );
                context.read<NavigationBloc>().add(NavigationEvents.home);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/home_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Главная',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showAuthDialog(context, () {});
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MainProfilePage()),
                  );
                  context.read<NavigationBloc>().add(NavigationEvents.profile);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/profile_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Профиль',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showAuthDialog(context, () {});
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CollectionsPage()),
                  );
                  context
                      .read<NavigationBloc>()
                      .add(NavigationEvents.collection);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/category_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Подборки',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showAuthDialog(context, () {});
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AudioScreen()),
                  );
                  context.read<NavigationBloc>().add(NavigationEvents.audio);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/paper_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Все аудиофайлы',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showAuthDialog(context, () {});
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchPage()),
                  );
                  context.read<NavigationBloc>().add(NavigationEvents.audio);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/search_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Поиск',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showAuthDialog(context, () {});
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const DeletedPage()),
                  );
                  context.read<NavigationBloc>().add(NavigationEvents.audio);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/trash_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Недавно удаленные',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () {
                if (FirebaseAuth.instance.currentUser == null) {
                  showAuthDialog(context, () {});
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SubscribePage()),
                  );
                  context.read<NavigationBloc>().add(NavigationEvents.profile);
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 44.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/wallet_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Подписка',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: GestureDetector(
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@example.com',
                  queryParameters: {'subject': 'Тема письма'},
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                } else {
                  throw 'Could not launch $emailLaunchUri';
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0.0),
                child: Row(
                  children: [
                    SvgPicture.asset(
                      'assets/img/icon/svg/edit_drawer_icon.svg',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 13),
                    const Text(
                      'Написать в\nподдержку ',
                      style: TextStyle(fontSize: 18, height: 1.1),
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
