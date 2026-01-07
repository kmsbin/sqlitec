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
  if (type.contains('decimal')) {
    return BasicType.real;
  }
  
  for (final keys in _stringToBasicTypeMap.keys) {
    if (keys.contains(type)) {
      return _stringToBasicTypeMap[keys]!;
    }
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
  final isNullable = type?.nullable ?? false;

  if (isNullable) {
    return switch (type?.type) {
      BasicType.int => const IntNullableTypeGenerator(),
      BasicType.real => const DoubleNullableTypeGenerator(),
      BasicType.text => const StringNullableTypeGenerator(),
      _ => const ObjectNullableTypeGenerator(),
    };
  }

  return switch (type?.type) {
    BasicType.int => const IntTypeGenerator(),
    BasicType.real => const DoubleTypeGenerator(),
    BasicType.text => const StringTypeGenerator(),
    _ => const ObjectTypeGenerator(),
  };
}

ResolvedType columnDefinitionToResolvedType(ColumnDefinition definition) {
  final isNullable =
      !definition.constraints.any((e) => e is NotNull || e is PrimaryKeyColumn);

  return ResolvedType(
    type: getTypeByString(definition.typeName ?? ''),
    nullable: isNullable,
  );
}
