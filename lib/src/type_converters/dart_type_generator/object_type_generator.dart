import 'dart_type_generator.dart';

class ObjectTypeGenerator extends DartTypeGenerator {
  const ObjectTypeGenerator();
  @override
  String fromJson(String value) {
    return '$value as Object';
  }

  @override
  String get type => 'Object';

  @override
  bool get isNullable => false;
}

class ObjectNullableTypeGenerator extends DartTypeGenerator {
  const ObjectNullableTypeGenerator();
  @override
  String fromJson(String value) => value;

  @override
  String get type => 'Object?';

  @override
  bool get isNullable => true;
}
