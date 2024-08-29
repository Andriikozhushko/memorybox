import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:memory_box/pages/audio_screen/audiolist_page.dart';
import 'package:memory_box/pages/collection_page/collections.dart';
import 'package:memory_box/pages/home_screen/homescreen_body.dart';
import 'package:memory_box/pages/profile_screen/main.dart';
import 'package:memory_box/pages/recorder_screen/cubit/records_cubit.dart';
import 'package:memory_box/pages/recorder_screen/record_page.dart';
import 'package:memory_box/styles/colors.dart';
import 'package:memory_box/widgets/buttonbar.dart';
import 'package:memory_box/widgets/page_builder.dart';

import '../../blocs/buttomnavbar_cubit/buttombar_cubit.dart';
import '../../blocs/navigation_bloc/navigation_bloc.dart';
import '../../widgets/auth_dialog.dart';
import 'models/audio_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late NavigationBloc navigationBloc;
  late Stream<List<AudioData>> audioStream;
  late BottomNavBarVisibilityCubit _bottomNavBarVisibilityCubit;
  late User? currentUser;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _bottomNavBarVisibilityCubit = context.read<BottomNavBarVisibilityCubit>();
    _bottomNavBarVisibilityCubit.showBottomNavBar();
    currentUser = FirebaseAuth.instance.currentUser;
    navigationBloc = NavigationBloc(onNavigate: updateSelectedPageIndex);
    audioStream = currentUser != null
        ? _loadAudioStream()
        : const Stream<List<AudioData>>.empty();
  }

  @override
  void dispose() {
    navigationBloc.close();
    super.dispose();
  }

  Stream<List<AudioData>> _loadAudioStream() {
    if (currentUser == null) {
      return const Stream.empty();
    } else {
      return FirebaseFirestore.instance
          .collection('audio_files')
          .where('uid', isEqualTo: currentUser!.uid)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => AudioData.fromFirestore(doc))
              .toList());
    }
  }

  void playAudio(String path) async {
    try {
      final player = AudioPlayer();
      await player.setFilePath(path);
      await player.play();
    } catch (e) {
      log('Ошибка при проигрывании аудиозаписи: $e');
    }
  }

  void updateSelectedPageIndex(int index) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) {
          Widget page = HomeBody(
            currentUser: currentUser,
            audioStream: audioStream,
          );
          if (settings.name == '/profile') {
            page = const MainProfilePage();
          } else if (settings.name == '/audio') {
            page = const AudioScreen();
          }
          return MaterialPageRoute(
              builder: (_) => miniPlayer(
                    context,
                    page,
                  ));
        },
      ),
      bottomNavigationBar:
          BlocBuilder<BottomNavBarVisibilityCubit, BottomNavBarVisibility>(
        builder: (context, visibility) {
          return Visibility(
            visible: visibility == BottomNavBarVisibility.visible,
            child: Stack(
              children: [
                BottomNavigationBarWidget(
                  openPage: _openPage,
                ),
                BlocBuilder<RecordPageCubit, RecordPageState>(
                  builder: (context, state) {
                    return Positioned(
                      bottom: 40,
                      left: MediaQuery.of(context).size.width / 2 - 2,
                      child: Visibility(
                        visible: state.isIndicatorVisible,
                        maintainSize: true,
                        maintainAnimation: true,
                        maintainState: true,
                        child: Container(
                          height: 60,
                          width: 4,
                          color: recordColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openPage(int index) {
    if ((index == 1 || index == 3 || index == 4) && currentUser == null) {
      showAuthDialog(context, () {});
    } else {
      context.read<RecordPageCubit>().toggleIndicatorBasedOnIndex(index);
      switch (index) {
        case 0:
          setState(() {
            audioStream = _loadAudioStream();
          });
          navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
              builder: (_) => miniPlayer(
                  context,
                  HomeBody(
                      currentUser: currentUser, audioStream: audioStream))));
          context.read<NavigationBloc>().add(NavigationEvents.home);
          break;
        case 1:
          navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
              builder: (_) => miniPlayer(context, const CollectionsPage())));
          context.read<NavigationBloc>().add(NavigationEvents.collection);
          break;
        case 2:
          navigatorKey.currentState!.pushReplacement(
              MaterialPageRoute(builder: (_) => const RecordPage()));
          context.read<NavigationBloc>().add(NavigationEvents.record);
          break;

        case 3:
          navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
              builder: (_) => miniPlayer(context, const AudioScreen())));
          context.read<NavigationBloc>().add(NavigationEvents.audio);
          break;
        case 4:
          navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
              builder: (_) => miniPlayer(context, const MainProfilePage())));
          context.read<NavigationBloc>().add(NavigationEvents.profile);
          break;
        default:
          break;
      }
    }
  }
}
