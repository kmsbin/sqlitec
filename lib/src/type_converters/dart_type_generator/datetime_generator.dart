import 'dart_type_generator.dart';

class DateTimeGenerator implements DartTypeGenerator {

  const DateTimeGenerator();

  @override
  String fromJson(String? field) {
    return 'DateTime.parse($field)';
  }

  @override
  String toJson(fieldName) {
    return '$fieldName.toIso8601String()';
  }

  @override
  String get type => 'DateTime';

  @override
  bool get isNullable => false;
}

class DateTimeNullableGenerator implements DartTypeGenerator {
  const DateTimeNullableGenerator();

  @override
  String fromJson(String field) {
    return '$field == null ? null : DateTime.parse($field)';
  }

  @override
  String toJson(fieldName) {
    return '$fieldName?.toIso8601String()';
  }

  @override
  String get type => 'DateTime?';

  @override
  bool get isNullable => true;
}