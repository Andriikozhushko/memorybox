import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OffsetCubit extends Cubit<Offset> {
  OffsetCubit() : super(const Offset(0, 0));

  void updateOffset(Offset newOffset) => emit(newOffset);
}
