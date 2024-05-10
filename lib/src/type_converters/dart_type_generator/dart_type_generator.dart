


abstract class DartTypeGenerator {
  abstract final String type;

  String fromJson(String value);
  String toJson(String fieldName) => fieldName;

  bool get isNullable;

  const DartTypeGenerator();
}