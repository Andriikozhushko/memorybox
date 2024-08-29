import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:memory_box/pages/profile_screen/profile.dart';
import 'package:memory_box/pages/profile_screen/profile_edit.dart';
import 'package:memory_box/pages/profile_screen/profile_nav.dart';

class MainProfilePage extends StatelessWidget {
  const MainProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AudioPageCubit>(
      create: (context) => AudioPageCubit(),
      child: BlocBuilder<AudioPageCubit, AudioPageState>(
        builder: (context, state) {
          switch (state.type) {
            case AudioPageType.collection:
              return ProfilePage(
                onSwitch: (path) {
                  context.read<AudioPageCubit>().showPlayer(path);
                },
                onEditProfile: () {
                  context.read<AudioPageCubit>().showEdit();
                },
              );
            case AudioPageType.edit:
              return EditProfilePage(
                onCancelEdit: () {
                  context.read<AudioPageCubit>().showProfile();
                },
              );
            default:
              return const Center(child: Text('Неизвестное состояние'));
          }
        },
      ),
    );
  }
}
