import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';

import '../../styles/colors.dart';
import '../../styles/ellipse_clipper.dart';
import '../../styles/fonts.dart';
import '../../widgets/drawer.dart';
import '../audio_screen/widget/audio_list_view.dart';
import '../collection_page/selected_collections/selected_collections.dart';
import '../home_screen/models/audio_data.dart';
import 'bloc/search_bloc.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchView();
  }
}

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  SearchViewState createState() => SearchViewState();
}

class SearchViewState extends State<SearchView> {
  late User? currentUser;
  late List<AudioData> filteredAudioList = [];
  late AudioPlayer player;
  bool isButtonActive = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    searchController.addListener(_updateSearch);
    _updateSearch();
  }

  @override
  void dispose() {
    searchController.removeListener(_updateSearch);
    searchController.dispose();
    super.dispose();
  }

  void _updateSearch() {
    if (currentUser != null) {
      context
          .read<AudioBloc>()
          .add(LoadAudios(currentUser!.uid, searchController.text));
    }
  }

  late StreamSubscription<List<AudioData>> audioStreamSubscription;

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

  void deleteAudio(AudioData audioData) {
    audioData.delete().then((_) {
      setState(() {});
    }).catchError((error) {});
  }

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) {
      _hideOverlay();
    }
    _overlayEntry = createOverlayEntry(context);
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry createOverlayEntry(BuildContext context) {
    return OverlayEntry(
      builder: (context) => Positioned(
        width: 360,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60),
          child: Material(
            elevation: 4.0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            shadowColor: const Color(0x0000002E),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: BlocBuilder<AudioBloc, AudioState>(
                builder: (context, state) {
                  List<AudioData> items = [];
                  if (state is AudioLoadSuccess) {
                    items = state.audios;
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final audioName = items[index].name;
                      return ListTile(
                        title: Text(audioName),
                        onTap: () {
                          searchController.text = audioName;
                          _hideOverlay();
                          context
                              .read<AudioBloc>()
                              .add(LoadAudios(currentUser!.uid, audioName));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: audiofileColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(40.0),
        child: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: const Icon(Icons.menu, size: 36),
                onPressed: () {
                  if (_overlayEntry != null) {
                    _hideOverlay();
                  }
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          centerTitle: true,
          title: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 0.0),
                child: Text(
                  'Поиск',
                  style: graysize36.copyWith(height: 1),
                ),
              ),
            ],
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: BlocBuilder<AudioBloc, AudioState>(
        builder: (context, state) {
          List<AudioData> audioList = [];
          if (state is AudioLoadSuccess) {
            audioList = state.audios;
          }
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (_overlayEntry != null) {
                _hideOverlay();
              }
            },
            child: Stack(
              children: [
                Container(
                  color: const Color(0xFFF6F6F6),
                ),
                SizedBox(
                  height: 160,
                  child: ClipPath(
                    clipper: EllipseClipper(),
                    child: Container(
                      color: audiofileColor,
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
                  top: 56,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        AudioListView(
                          audioList: audioList,
                          isButtonActive: isButtonActive,
                          onAddToCollection: addToCollection,
                          onDelete: deleteAudio,
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Найди потеряшку',
                      style: graysize16.copyWith(height: 1),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 60,
                  ),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(41),
                      color: Colors.white,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CompositedTransformTarget(
                        link: _layerLink,
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: 'Поиск',
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.only(left: 30.0, top: 5),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: SvgPicture.asset(
                                  'assets/img/icon/svg/search_drawer_icon.svg'),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              filteredAudioList = audioList
                                  .where((audio) => audio.name
                                      .toLowerCase()
                                      .contains(value.toLowerCase()))
                                  .toList();
                            });
                            _showOverlay(context);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
