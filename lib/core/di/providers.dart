import 'package:eld_management_system/core/di/injection.dart';
import 'package:eld_management_system/features/auth/domain/repositories/auth_repository.dart';
import 'package:eld_management_system/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eld_management_system/features/ble/domain/repositories/eld_repository.dart';
import 'package:eld_management_system/features/ble/presentation/bloc/eld_bloc.dart';
import 'package:eld_management_system/features/hos/domain/repositories/hos_repository.dart';
import 'package:eld_management_system/features/hos/presentation/cubit/hos_cubit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => sl<AuthRepository>());
final eldRepositoryProvider =
    Provider<EldRepository>((ref) => sl<EldRepository>());
final hosRepositoryProvider =
    Provider<HosRepository>((ref) => sl<HosRepository>());

final authBlocProvider = Provider<AuthBloc>((ref) {
  final bloc = AuthBloc(ref.watch(authRepositoryProvider));
  ref.onDispose(bloc.close);
  return bloc;
});

final eldBlocProvider = Provider<EldBloc>((ref) {
  final bloc = EldBloc(ref.watch(eldRepositoryProvider));
  ref.onDispose(bloc.close);
  return bloc;
});

final hosCubitProvider = Provider.family<HosCubit, String>((ref, driverId) {
  final cubit = HosCubit(ref.watch(hosRepositoryProvider));
  ref.onDispose(cubit.close);
  return cubit;
});

final themeModeProvider =
    StateProvider<AppThemeMode>((ref) => AppThemeMode.system);

enum AppThemeMode { system, light, dark }
