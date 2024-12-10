import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/datetime_generator.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/double_generator.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/int_generator.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/object_type_generator.dart';
import 'package:sqlparser/sqlparser.dart';

import 'dart_type_generator/string_type_generator.dart';

const _stringToDartTypeMap = {
  [
    'time_stamp',
    'timestamp',
    'date',
    'datetime',
  ]: (DateTimeGenerator(), DateTimeNullableGenerator()),
  [
    'text',
    'varchar',
    'character',
    'char',
  ]: (StringTypeGenerator(), StringNullableTypeGenerator()),
  [
    'int',
    'integer',
    'tinyint',
    'smallint',
    'mediumint',
    'bigint',
  ]: (IntTypeGenerator(), IntNullableTypeGenerator()),
  [
    'real',
    'double',
    'float',
    'decimal',
  ]: (DoubleTypeGenerator(), DoubleNullableTypeGenerator()),
};

(DartTypeGenerator, DartTypeGenerator) getTypeByString(String type) {
  type = type.toLowerCase();
  for (final keys in _stringToDartTypeMap.keys) {
    if (keys.any(type.contains)) {
      return _stringToDartTypeMap[keys]!;
    }
  }
  return (const ObjectTypeGenerator(), const ObjectNullableTypeGenerator());
}

DartTypeGenerator columnDefinitionToGenerator(ColumnDefinition definition) {
  final (generator, nullableGenerator) =
      getTypeByString(definition.typeName ?? '');
  if (definition.constraints
      .any((e) => e is NotNull || e is PrimaryKeyColumn)) {
    return generator;
  }
  return nullableGenerator;
}
