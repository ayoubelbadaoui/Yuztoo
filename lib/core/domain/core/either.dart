/// Minimal Either implementation to keep async results type-safe.
sealed class Either<L, R> {
  const Either();

  T fold<T>(T Function(L value) left, T Function(R value) right);

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  L? get leftOrNull => this is Left<L, R> ? (this as Left<L, R>).value : null;
  R? get rightOrNull => this is Right<L, R> ? (this as Right<L, R>).value : null;
}

class Left<L, R> extends Either<L, R> {
  const Left(this.value);
  final L value;

  @override
  T fold<T>(T Function(L value) left, T Function(R value) right) => left(value);
}

class Right<L, R> extends Either<L, R> {
  const Right(this.value);
  final R value;

  @override
  T fold<T>(T Function(L value) left, T Function(R value) right) => right(value);
}
