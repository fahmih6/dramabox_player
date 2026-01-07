import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/app_enums.dart';

class NavigationCubit extends Cubit<AppContentProvider> {
  NavigationCubit() : super(AppContentProvider.dramabox);

  void changeProvider(AppContentProvider provider) {
    if (state != provider) {
      emit(provider);
    }
  }
}
