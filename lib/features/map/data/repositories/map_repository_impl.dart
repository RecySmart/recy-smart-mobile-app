import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/smart_bin.dart';
import '../../domain/repositories/map_repository.dart';
import '../datasources/map_remote_datasource.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource _remote;
  MapRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, List<SmartBin>>> getAllBins() async {
    try {
      final bins = await _remote.getAllBins();
      return Right(bins);
    } on Failure catch (f) {
      return Left(f);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}