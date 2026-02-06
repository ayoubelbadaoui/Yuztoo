import 'either.dart';
import 'failure.dart';

typedef Result<T> = Either<AppFailure, T>;

/// Simple unit type for operations that do not return a value.
class Unit {
  const Unit();
}

const unit = Unit();

extension ResultX<T> on Result<T> {
  T? get successOrNull => fold((_) => null, (value) => value);
}
