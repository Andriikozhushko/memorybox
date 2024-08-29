import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:memory_box/widgets/recordicon.dart';

import '../blocs/navigation_bloc/navigation_bloc.dart';
import '../styles/colors.dart';

class BottomNavigationBarWidget extends StatelessWidget {
  final Function(int) openPage;

  const BottomNavigationBarWidget({super.key, required this.openPage});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationBloc, int>(
      builder: (context, state) {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          selectedIconTheme: const IconThemeData(color: collectionsColor),
          currentIndex: state,
          onTap: openPage,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: _iconWithPadding('assets/img/icon/svg/home.svg', 0, state),
              activeIcon:
                  _activeIconWithPadding('assets/img/icon/svg/home.svg'),
              label: 'Главная',
            ),
            BottomNavigationBarItem(
              icon: _iconWithPadding(
                  'assets/img/icon/svg/category_icon.svg', 1, state),
              activeIcon: _activeIconWithPadding(
                  'assets/img/icon/svg/category_icon.svg'),
              label: 'Подборки',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.all(5.0),
                child: CustomRecordIcon(isRecordingSelected: state == 2),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.all(5.0),
                child: CustomRecordIcon(isRecordingSelected: true),
              ),
              label: state == 2 ? '' : 'Запись',
            ),
            BottomNavigationBarItem(
              icon: _iconWithPadding(
                  'assets/img/icon/svg/paper_icon.svg', 3, state),
              activeIcon:
                  _activeIconWithPadding('assets/img/icon/svg/paper_icon.svg'),
              label: 'Аудиозаписи',
            ),
            BottomNavigationBarItem(
              icon: _iconWithPadding(
                  'assets/img/icon/svg/profile_icon.svg', 4, state),
              activeIcon: _activeIconWithPadding(
                  'assets/img/icon/svg/profile_icon.svg'),
              label: 'Профиль',
            ),
          ],
        );
      },
    );
  }

  Widget _iconWithPadding(String assetName, int index, int currentIndex) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SvgPicture.asset(
        assetName,
        width: 30,
        height: 30,
        colorFilter: currentIndex == index
            ? const ColorFilter.mode(collectionsColor, BlendMode.srcIn)
            : null,
      ),
    );
  }

  Widget _activeIconWithPadding(String assetName) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SvgPicture.asset(
        assetName,
        width: 30,
        height: 30,
        colorFilter: const ColorFilter.mode(collectionsColor, BlendMode.srcIn),
      ),
    );
  }
}
