import 'package:code_builder/code_builder.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/sql_expressions_arguments_builder.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import '../code_builders/named_record_builder.dart';
import 'registers.dart';

class SelectRegister implements ActionRegister<SelectStatement> {
  final SqlEngine engine;
  final CmdAnalyzer cmdAnalyzer;
  final AnalyzedComment comment;

  const SelectRegister(
    this.engine,
    this.comment,
    this.cmdAnalyzer,
  );

  @override
  Method register(stmt) {
    final context = engine.analyze(stmt.toSql());

    if (context.errors.isNotEmpty) {
      throw AnalysisSqlCmdException(context.errors);
    }
    final sqlStmt = context.root as SelectStatement;

    return _generateMethod(sqlStmt, context);
  }

  ReturnBuilder _getReturnTypeBySelectStatement(
    SelectStatement stmt,
    AnalysisContext analyzer,
  ) {
    if (stmt.resolvedColumns?.singleOrNull case final column?) {
      return ColumnReturnBuilder(
        column.name,
        getDartGeneratorFromBasicType(analyzer.typeOf(column).type),
      );
    }
    if (stmt.columns.singleOrNull case final StarResultColumn column) {
      final startTable = column.tableName;
      if (startTable != null) {
        final table = cmdAnalyzer.findTableByName(startTable);
        if (table != null) {
          return TableReturnBuilder(table);
        }
      }
      if (stmt.from case TableReference ref) {
        final table = cmdAnalyzer.findTableByName(ref.tableName);
        if (table != null) {
          return TableReturnBuilder(table);
        }
      }
    }
    final resultTypes = [
      for (final column in stmt.resolvedColumns ?? <Column>[])
        (
          name: column.name,
          generator:
              getDartGeneratorFromBasicType(analyzer.typeOf(column).type),
        ),
    ];

    return NamedRecordReturnBuilder(resultTypes);
  }

  Method _generateMethod(
    SelectStatement stmt,
    AnalysisContext analyzer,
  ) {
    final args = SqlExpressionsArgumentsBuilder(analyzer)
        .getMethodParameters(stmt.selfAndDescendants);
    final params = _getReturnTypeBySelectStatement(stmt, analyzer);
    final sqlCmd = stmt.toSql().replaceAll("'", r"\'");

    final buffer = StringBuffer()
      ..writeln('final result = await db.rawQuery(')
      ..writeln("  '$sqlCmd',")
      ..writeln("  [${args.dbArgs}],")
      ..writeln(');\n')
      ..write(params.getReturnByMode(comment.mode));

    final returns = refer(params.getReturnType(comment));
    final code = Code(buffer.toString());

    print(args.positional);
    print(args.named);

    return Method(
      (builder) => builder
        ..name = comment.name
        ..returns = returns
        ..modifier = MethodModifier.async
        ..requiredParameters.addAll(args.positional)
        ..optionalParameters.addAll(args.named) // there is a bug on code builder: https://github.com/dart-lang/tools/issues/1126
        ..modifier = MethodModifier.async
        ..body = code,
    );
  }
}
