import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/smart_bin.dart';

abstract class MapRepository {
  Future<Either<Failure, List<SmartBin>>> getAllBins();
}