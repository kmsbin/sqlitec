import 'dart_type_generator.dart';

class DoubleTypeGenerator extends DartTypeGenerator {
  const DoubleTypeGenerator();

  @override
  String fromJson(String value) {
    return '($value as num).toDouble()';
  }

  @override
  String get type => 'double';

  @override
  bool get isNullable => false;
}

class DoubleNullableTypeGenerator extends DartTypeGenerator {
  const DoubleNullableTypeGenerator();

  @override
  String fromJson(String value) {
    return '($value as num?)?.toDouble()';
  }

  @override
  String get type => 'double?';

  @override
  bool get isNullable => true;
}
