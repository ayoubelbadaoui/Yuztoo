/// Base class for immutable value objects.
abstract class ValueObject<T> {
  const ValueObject(this.value);
  final T value;

  @override
  String toString() => value.toString();
}
