import 'dart_type_generator.dart';

class IntTypeGenerator extends DartTypeGenerator {
  const IntTypeGenerator();
  @override
  String fromJson(String value) {
    return '($value as num).toInt()';
  }

  @override
  String get type => 'int';

  @override
  bool get isNullable => false;
}

class IntNullableTypeGenerator extends DartTypeGenerator {
  const IntNullableTypeGenerator();
  @override
  String fromJson(String value) {
    return '($value as num?)?.toInt()';
  }

  @override
  String get type => 'int?';

  @override
  bool get isNullable => true;
}
