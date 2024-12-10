import 'package:sqlitec/src/code_builders/method_builder.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/sql_expressions_arguments_builder.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import '../code_builders/named_record_builder.dart';
import 'registers.dart';

class SelectRegister implements Register<SelectStatement> {
  final SqlEngine engine;
  final CmdAnalyzer cmdAnalyzer;
  final AnalyzedComment comment;

  SelectRegister(this.engine, this.comment, this.cmdAnalyzer);

  @override
  String register(stmt) {
    final context = engine.analyze(stmt.toSql());

    if (context.errors.isNotEmpty) {
      throw AnalysisSqlCmdException(context.errors);
    }
    final sqlStmt = context.root as SelectStatement;

    return generateMethod(sqlStmt, context);
  }

  ReturnBuilder getReturnTypeBySelectStatement(
      SelectStatement stmt, AnalysisContext analyzer) {
    if (stmt.resolvedColumns?.length == 1) {
      final column = stmt.resolvedColumns!.first;
      return SingleColumnBuilder(
        column.name,
        getDartGeneratorFromBasicType(analyzer.typeOf(column).type),
      );
    }
    if (stmt.columns.length == 1 && stmt.columns.first is StarResultColumn) {
      final startTable = (stmt.columns.first as StarResultColumn).tableName;
      if (startTable != null) {
        final table = cmdAnalyzer.findTableByName(startTable);
        if (table != null) {
          return SingleTableBuilder(table);
        }
      }
      if (stmt.from case TableReference ref) {
        final table = cmdAnalyzer.findTableByName(ref.tableName);
        if (table != null) {
          return SingleTableBuilder(table);
        }
      }
    }
    final resultTypes = <({String name, DartTypeGenerator generator})>[
      for (final column in stmt.resolvedColumns ?? <Column>[])
        (
          name: column.name,
          generator:
              getDartGeneratorFromBasicType(analyzer.typeOf(column).type),
        ),
    ];
    return NamedRecordBuilder(resultTypes);
  }

  ({String name, String type})? getReturnType(
      Column column, AnalysisContext analyzer) {
    return (
      name: column.name,
      type: getDartTypeByBasicType(analyzer.typeOf(column).type?.type)
    );
  }

  String generateMethod(
    SelectStatement stmt,
    AnalysisContext analyzer,
  ) {
    final methodArgs = SqlExpressionsArgumentsBuilder(analyzer)
        .generateFunctionArgs(stmt.selfAndDescendants);
    final paramReturnBuilder = getReturnTypeBySelectStatement(stmt, analyzer);
    final dbArgs = methodArgs.map((it) => it.name).join(', ');
    final buffer = StringBuffer()
      ..writeln('final result = await db.rawQuery(')
      ..writeln("  '${stmt.toSql().replaceAll("'", r"\'")}',")
      ..writeln("  [$dbArgs],")
      ..writeln(');\n')
      ..write(paramReturnBuilder.getReturnByMode(comment.mode));

    final methodBuilder = MethodBuilder(
      name: comment.name,
      returnType: paramReturnBuilder.getReturnType(comment),
      arguments: methodArgs,
      isAsync: true,
      indentationSpaces: 2,
      body: buffer.toString(),
    );

    return methodBuilder.build();
  }
}
