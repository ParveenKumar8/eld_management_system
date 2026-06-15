import 'package:dartz/dartz.dart';
import 'package:eld_management_system/core/errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
typedef ResultStream<T> = Stream<Either<Failure, T>>;
typedef ResultVoid = ResultFuture<void>;