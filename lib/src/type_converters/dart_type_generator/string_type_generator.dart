import 'dart_type_generator.dart';

class StringTypeGenerator extends DartTypeGenerator {
  const StringTypeGenerator();
  @override
  String fromJson(String value) {
    return '$value as String';
  }

  @override
  String get type => 'String';

  @override
  bool get isNullable => false;
}

class StringNullableTypeGenerator extends DartTypeGenerator {
  const StringNullableTypeGenerator();
  @override
  String fromJson(String value) {
    return '$value as String?';
  }

  @override
  String get type => 'String?';

  @override
  bool get isNullable => true;
}
