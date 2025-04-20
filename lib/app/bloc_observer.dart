import 'package:bloc/bloc.dart';

class MyBlocObserver extends BlocObserver {
  const MyBlocObserver();

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    print('[Bloc] onError(${bloc.runtimeType}, $error, $stackTrace)');
  }

  @override
  void onEvent(Bloc<dynamic, dynamic> bloc, Object? event) {
    super.onEvent(bloc, event);
    // print('[Bloc] onEvent ${bloc.runtimeType}, ${event.runtimeType}');
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    // print('[Bloc] onChange ${bloc.runtimeType}, ${change.currentState} => ${change.nextState}');
  }
}