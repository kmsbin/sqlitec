import 'package:code_builder/code_builder.dart' as cb;
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:change_case/change_case.dart';
import 'package:sqlparser/utils/node_to_text.dart';
import 'registers.dart';
import '../type_converters/string_to_basic_type.dart';
import '../type_converters/string_to_dart_type.dart';

class CreateTableRegister implements DdlRegister<CreateTableStatement> {
  final SqlEngine engine;
  final CmdAnalyzer analyzer;

  const CreateTableRegister(
    this.engine,
    this.analyzer,
  );

  @override
  cb.Class createTable(stmt) {
    _registerTableStatement(stmt);
    _registerTableAnalysis(stmt);

    return _convertTableToClass(stmt);
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

  cb.Class _convertTableToClass(CreateTableStatement stmt) {
    final clazzName = stmt.createdName.toPascalCase();
    final columnsAndConverters =
        stmt.columns.map(SqlColumnGeneratorDto.new).toList();

    return cb.Class(
      (builder) => builder
        ..name = clazzName
        ..constructors.addAll([
          _constructor(columnsAndConverters),
          _fromJsonConstructor(clazzName, columnsAndConverters),
        ])
        ..methods.add(_toJsonMethod(columnsAndConverters))
        ..fields.addAll(
          [
            cb.Field(
              (builder) => builder
                ..name = r'$tableName'
                ..type = cb.refer('String')
                ..static = true
                ..modifier = cb.FieldModifier.constant
                ..assignment = cb.Code("'${stmt.createdName}'"),
            ),
            cb.Field(
              (builder) => builder
                ..name = r'$createTableStatement'
                ..type = cb.refer('String')
                ..static = true
                ..modifier = cb.FieldModifier.constant
                ..assignment =
                    cb.Code("'${stmt.toSql().replaceAll("'", r"\'")}'"),
            ),
            for (final converter in columnsAndConverters)
              cb.Field(
                (builder) => builder
                  ..name = converter.fieldName
                  ..modifier = cb.FieldModifier.final$
                  ..type = cb.refer(converter.generator.type),
              )
          ],
        ),
    );
  }

  void _registerTableAnalysis(CreateTableStatement stmt) {
    final columnsAndConverters =
        stmt.columns.map(SqlColumnGeneratorDto.new).toList();
        
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

  cb.Method _toJsonMethod(List<SqlColumnGeneratorDto> fields) {
    final buffer = StringBuffer('return {\n');
    for (final field in fields) {
      buffer.writeln(
          "  '${field.columnName}': ${field.generator.toJson(field.fieldName)},");
    }
    buffer.writeln('};');

    final method = cb.Method(
      (builder) => builder
        ..name = 'toJson'
        ..body = cb.Code(buffer.toString())
        ..returns = cb.refer('Map<String, dynamic>'),
    );

    return method;
  }

  cb.Constructor _constructor(List<SqlColumnGeneratorDto> fields) {
    return cb.Constructor(
      (builder) => builder
        ..optionalParameters.addAll([
          for (final converter in fields)
            cb.Parameter((builder) => builder
              ..name = converter.fieldName
              ..named = true
              ..toThis = true
              ..required = !converter.generator.isNullable)
        ]),
    );
  }

  String _getJsonMapArg(String field) => "data['$field']";

  cb.Constructor _fromJsonConstructor(
      String className, List<SqlColumnGeneratorDto> fields) {
    final data = cb.refer(className).newInstance([], {
      for (final dto in fields)
        dto.fieldName: cb.CodeExpression(
          cb.Code(
            dto.generator.fromJson(_getJsonMapArg(dto.columnName)),
          ),
        ),
    });

    return cb.Constructor(
      (builder) => builder
        ..name = 'fromJson'
        ..factory = true
        ..requiredParameters.add(
          cb.Parameter(
            (builder) => builder
              ..name = 'data'
              ..type = cb.refer(
                'Map<String, dynamic>',
              ),
          ),
        )
        ..body = data.code,
    );
  }
}

class SqlColumnGeneratorDto {
  final String columnName;
  final String fieldName;
  final DartTypeGenerator generator;

  SqlColumnGeneratorDto(ColumnDefinition definition)
      : columnName = definition.columnName,
        fieldName = definition.columnName.toCamelCase(),
        generator = columnDefinitionToGenerator(definition);
}
