import 'package:flutter_bloc/flutter_bloc.dart';

/// Whether the child is playing with a controller: true from the first
/// controller input until the screen is touched or clicked. While true, the
/// focused control glows and controls with a shortcut show their button.
class GamepadCubit extends Cubit<bool> {
  GamepadCubit() : super(false);

  void used() {
    if (!state) emit(true);
  }

  void touched() {
    if (state) emit(false);
  }
}
