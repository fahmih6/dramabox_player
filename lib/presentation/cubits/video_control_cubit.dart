import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// State
class VideoControlState extends Equatable {
  final bool isSpeedUp;
  final bool areControlsVisible;
  final String? seekAction; // 'forward' or 'backward'

  const VideoControlState({
    this.isSpeedUp = false,
    this.areControlsVisible = true,
    this.seekAction,
  });

  VideoControlState copyWith({
    bool? isSpeedUp,
    bool? areControlsVisible,
    String? seekAction,
    bool clearSeekAction = false,
  }) {
    return VideoControlState(
      isSpeedUp: isSpeedUp ?? this.isSpeedUp,
      areControlsVisible: areControlsVisible ?? this.areControlsVisible,
      seekAction: clearSeekAction ? null : (seekAction ?? this.seekAction),
    );
  }

  @override
  List<Object?> get props => [isSpeedUp, areControlsVisible, seekAction];
}

// Cubit
class VideoControlCubit extends Cubit<VideoControlState> {
  VideoControlCubit() : super(const VideoControlState());

  void startSpeedUp() {
    emit(state.copyWith(isSpeedUp: true));
  }

  void endSpeedUp() {
    emit(state.copyWith(isSpeedUp: false));
  }

  void toggleControls() {
    emit(state.copyWith(areControlsVisible: !state.areControlsVisible));
  }

  void setControlsVisible(bool visible) {
    emit(state.copyWith(areControlsVisible: visible));
  }

  void seek(bool forward) {
    emit(state.copyWith(seekAction: forward ? 'forward' : 'backward'));
    // Auto-clear seek action after a short delay (UI feedback) is handled by the UI widget usually,
    // but we can also just emit a cleared state after the UI consumes it.
    // For now, let's just emit the action.
  }

  void clearSeek() {
    emit(state.copyWith(clearSeekAction: true));
  }
}
