import 'package:get_it/get_it.dart';
import 'package:dramabox_free/core/services/shorebird_service.dart';
import 'package:dramabox_free/core/network/network_client.dart';
import 'package:dramabox_free/data/datasources/drama_local_data_source.dart';
import 'package:dramabox_free/data/datasources/drama_remote_data_source.dart';
import 'package:dramabox_free/data/repositories/drama_repository_impl.dart';
import 'package:dramabox_free/domain/repositories/drama_repository.dart';
import 'package:dramabox_free/presentation/blocs/home_bloc.dart';
import 'package:dramabox_free/presentation/blocs/player_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Services
  sl.registerLazySingleton(() => ShorebirdService());

  // Blocs
  sl.registerFactory(() => HomeBloc(repository: sl()));
  sl.registerFactory(() => PlayerBloc(repository: sl()));

  // Network
  sl.registerLazySingleton(() => NetworkClient());

  // Data Sources
  sl.registerLazySingleton<DramaRemoteDataSource>(
    () => DramaRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<DramaLocalDataSource>(
    () => DramaLocalDataSourceImpl(),
  );

  // Repositories
  sl.registerLazySingleton<DramaRepository>(
    () => DramaRepositoryImpl(remoteDataSource: sl(), localDataSource: sl()),
  );
}
