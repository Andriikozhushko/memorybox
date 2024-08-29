import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:memory_box/styles/colors.dart';
import 'package:memory_box/widgets/slider.dart';

import '../blocs/audio_cubit/audio_cubit.dart';
import '../blocs/miniplayer_offset_cubit/miniplayer_cubit.dart';

Widget miniPlayer(BuildContext context, Widget page) {
  return Stack(
    children: [
      Positioned.fill(
        child: page,
      ),
      BlocBuilder<OffsetCubit, Offset>(
        builder: (context, offset) {
          return GestureDetector(
            onPanUpdate: (details) {
              double sensitivityMultiplier = 2;
              Offset newOffset =
                  offset + Offset(0, details.delta.dy * sensitivityMultiplier);

              double topLimit = MediaQuery.of(context).padding.top - 650.h;
              double bottomLimit = MediaQuery.of(context).size.height - 800.h;

              if (newOffset.dy > bottomLimit) {
                newOffset = Offset(newOffset.dx, bottomLimit);
              }
              if (newOffset.dy < topLimit) {
                newOffset = Offset(newOffset.dx, topLimit);
              }

              context.read<OffsetCubit>().updateOffset(newOffset);
            },
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: offset,
                child: BlocBuilder<AudioCubit, AudioState>(
                  builder: (context, state) {
                    if (state is AudioPlaying) {
                      String positionFormatted =
                          "${state.position.inMinutes}:${(state.position.inSeconds % 60).toString().padLeft(2, '0')}";
                      String durationFormatted =
                          "${state.duration.inMinutes}:${(state.duration.inSeconds % 60).toString().padLeft(2, '0')}";

                      return Container(
                        width: MediaQuery.of(context).size.width,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(70),
                          gradient: const LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF8C84E2),
                              Color(0xFF6C689F),
                            ],
                          ),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 12,
                            ),
                            InkWell(
                              borderRadius: BorderRadius.circular(41),
                              onTap: () => BlocProvider.of<AudioCubit>(context)
                                  .togglePlayPause(),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: grayTextColor,
                                  borderRadius: BorderRadius.circular(40.0),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    state.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: const Color(0xFF8C84E2),
                                    size: 33,
                                  ),
                                  onPressed: () =>
                                      BlocProvider.of<AudioCubit>(context)
                                          .togglePlayPause(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 18.0),
                                    child: Text(
                                      state.trackName,
                                      style: const TextStyle(
                                        color: grayTextColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 15,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: SliderTheme(
                                        data: Theme.of(context)
                                            .sliderTheme
                                            .copyWith(
                                              thumbShape: ThumbsSlider(),
                                              trackHeight: 2,
                                              activeTrackColor: grayTextColor,
                                              inactiveTrackColor: grayTextColor,
                                              thumbColor: grayTextColor,
                                              trackShape:
                                                  const RectangularSliderTrackShape(),
                                            ),
                                        child: Slider(
                                          value: state.position.inMilliseconds
                                              .toDouble()
                                              .clamp(
                                                  0,
                                                  state.duration.inMilliseconds
                                                      .toDouble()),
                                          min: 0,
                                          max: state.duration.inMilliseconds
                                              .toDouble(),
                                          onChanged: (value) {},
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                    child: Row(
                                      children: [
                                        Text(
                                          positionFormatted,
                                          style: const TextStyle(
                                            color: grayTextColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          durationFormatted,
                                          style: const TextStyle(
                                            color: grayTextColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => BlocProvider.of<AudioCubit>(context)
                                  .playNext(),
                              child: SvgPicture.asset(
                                  'assets/img/icon/svg/nextrack.svg'),
                            ),
                            const SizedBox(
                              width: 26,
                            ),
                          ],
                        ),
                      );
                    }
                    return Container();
                  },
                ),
              ),
            ),
          );
        },
      ),
    ],
  );
}
