import 'package:sqlitec/src/code_builders/from_json_builder.dart';
import 'package:sqlitec/src/code_builders/to_json_builder.dart';
import 'package:sqlitec/src/code_builders/to_string_builder.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:change_case/change_case.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import '../code_builders/class_builder.dart';
import '../code_builders/class_field_builder.dart';
import 'registers.dart';
import '../type_converters/string_to_basic_type.dart';
import '../type_converters/string_to_dart_type.dart';

class CreateTableRegister implements Register<CreateTableStatement> {
  final SqlEngine engine;
  final CmdAnalyzer analyzer;

  CreateTableRegister(this.engine, this.analyzer);

  @override
  String register(stmt) {
    _registerTableStatement(stmt);
    _registerTableAnalysis(stmt);

    return _convertTableToDartClass(stmt);
  }

  void _registerTableStatement(CreateTableStatement stmt) {
    final table = Table(
      name: stmt.createdName,
      resolvedColumns: [
        for (final column in stmt.columns)
          TableColumn(
            column.columnName,
            columnDefinitionToResolvedType(column),
          ),
      ],
    );
    engine.registerTable(table);
  }

  String _convertTableToDartClass(CreateTableStatement stmt) {
    final columnsAndConverters =
        stmt.columns.map(SqlColumnGeneratorDto.fromColumn).toList();
    final clazzName = stmt.createdName.toPascalCase();
    final clazz = ClassBuilder(name: clazzName, methods: [
      FromJsonBuilder(columnsAndConverters),
      ToJsonBuilder(columnsAndConverters),
      ToStringBuilder(columnsAndConverters, clazzName),
    ], fields: [
      ClassFieldBuilder(
        name: '\$tableName',
        dartType: 'String',
        defaultValue: "'${stmt.createdName}'",
        isStatic: true,
        isConst: true,
      ),
      ClassFieldBuilder(
        name: '\$createTableStatement',
        dartType: 'String',
        defaultValue: "'${stmt.toSql().replaceAll("'", r"\'")}'",
        isConst: true,
        isStatic: true,
      ),
      for (final converter in columnsAndConverters)
        ClassFieldBuilder(
          name: converter.fieldName,
          dartType: converter.generator.type,
          isNullable: converter.generator.isNullable,
        ),
    ]);

    return clazz.build();
  }

  void _registerTableAnalysis(CreateTableStatement stmt) {
    final columnsAndConverters =
        stmt.columns.map(SqlColumnGeneratorDto.fromColumn).toList();
    final tableAnalisis = TableAnalyzer(
      name: stmt.createdName.toPascalCase(),
      columns: [
        for (final column in columnsAndConverters)
          ColumnTableAnalyzer(
            name: column.fieldName,
            generator: column.generator,
          ),
      ],
    );
    analyzer.addTable(tableAnalisis);
  }
}

class SqlColumnGeneratorDto {
  final String columnName;
  final String fieldName;
  final DartTypeGenerator generator;

  SqlColumnGeneratorDto(
      {required this.columnName,
      required this.fieldName,
      required this.generator});

  factory SqlColumnGeneratorDto.fromColumn(ColumnDefinition definition) {
    return SqlColumnGeneratorDto(
      columnName: definition.columnName,
      fieldName: definition.columnName.toCamelCase(),
      generator: columnDefinitionToGenerator(definition),
    );
  }
}
