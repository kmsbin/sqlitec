import 'package:sqlitec/src/type_converters/dart_type_generator/double_generator.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/int_generator.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/string_type_generator.dart';
import 'package:sqlparser/sqlparser.dart';

import 'dart_type_generator/dart_type_generator.dart';
import 'dart_type_generator/object_type_generator.dart';

const _stringToBasicTypeMap = {
  [
    'text',
    'varchar',
    'character',
    'char',
    'date',
    'datetime',
  ]: BasicType.text,
  [
    'int',
    'integer',
    'tinyint',
    'smallint',
    'mediumint',
    'bigint',
  ]: BasicType.int,
  [
    'real',
    'double',
    'float',
  ]: BasicType.real,
  ['blob']: BasicType.blob,
};

BasicType getTypeByString(String type) {
  type = type.toLowerCase();
  if (type.contains('decimal')) return BasicType.real;
  for (final keys in _stringToBasicTypeMap.keys) {
    if (keys.contains(type)) return _stringToBasicTypeMap[keys]!;
  }
  return BasicType.any;
}

String getDartTypeByBasicType(BasicType? type) {
  return switch (type) {
    BasicType.int => 'int',
    BasicType.real => 'double',
    BasicType.text => 'String',
    BasicType.any => 'dynamic',
    BasicType.blob => 'List<int>',
    _ => 'dynamic',
  };
}

DartTypeGenerator getDartGeneratorFromBasicType(ResolvedType? type) {
  final generator = switch (type?.type) {
    BasicType.int => (const IntTypeGenerator(), const IntNullableTypeGenerator()),
    BasicType.real => (const DoubleTypeGenerator(), const DoubleNullableTypeGenerator()),
    BasicType.text => (const StringTypeGenerator(), const StringNullableTypeGenerator()),
    _ => (const ObjectTypeGenerator(), const ObjectNullableTypeGenerator()),
  };
  if (type?.nullable ?? false) {
    return generator.$2;
  }
  return generator.$1;
}

ResolvedType columnDefinitionToResolvedType(ColumnDefinition definition) {
  return ResolvedType(
    type: getTypeByString(definition.typeName ?? ''),
    nullable: !definition.constraints
        .any((e) => e is NotNull || e is PrimaryKeyColumn),
  );
}
