import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../styles/colors.dart';

class CustomRecordIcon extends StatelessWidget {
  final bool
      isRecordingSelected; // This will control the visibility of the voice icon.

  const CustomRecordIcon({
    super.key,
    required this.isRecordingSelected, // Expecting this to determine if "Запись" is selected.
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF90AF33).withOpacity(0.2),
                blurRadius: 11,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Column(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: recordColor,
                      ),
                    ),
                  ], // добавлены точки с запятой и закрывающая скобка
                ),
              ),
              if (!isRecordingSelected)
                Positioned(
                  top: 11,
                  left: 12.5,
                  child: SvgPicture.asset(
                    'assets/img/icon/svg/voice.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
