import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/loyalty_program_config.dart';
import '../domain/entities/merchant.dart';
import '../domain/merchant_failure.dart';
import '../domain/repositories/merchant_repository.dart';
import '../../../../core/domain/core/either.dart';
import '../../../../core/domain/core/result.dart';
import '../../../../core/infrastructure/firestore_user_rules_patch.dart';
import '../../../../core/infrastructure/logger_service.dart';
import '../../../../core/utils/city_input.dart';
import 'dto/merchant_dto.dart';
import 'loyalty_program_firestore_mapper.dart';
import 'merchant_city_resolution.dart';

part 'firestore_merchant_repository.core.part.dart';
part 'firestore_merchant_repository.writes.part.dart';
part 'firestore_merchant_repository.queries.part.dart';

abstract class _FirestoreMerchantRepositoryBase {
  _FirestoreMerchantRepositoryBase(this._firestore);

  final FirebaseFirestore _firestore;
}

/// Firebase Firestore implementation of MerchantRepository.
class FirestoreMerchantRepository extends _FirestoreMerchantRepositoryBase
    with
        _FirestoreMerchantRepositoryCore,
        _FirestoreMerchantRepositoryWrites,
        _FirestoreMerchantRepositoryQueries
    implements MerchantRepository {
  FirestoreMerchantRepository({required FirebaseFirestore firestore})
      : super(firestore);
}
