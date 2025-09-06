import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/sql_expressions_arguments_builder.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import 'registers.dart';

class UpdateRegister implements ActionRegister<UpdateStatement> {
  final SqlEngine engine;
  final CmdAnalyzer cmdAnalyzer;
  final AnalyzedComment comment;

  const UpdateRegister(
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
    final sqlStmt = context.root as UpdateStatement;

    return _generateMethodColumns(sqlStmt, context);
  }

  ({String name, String type})? getReturnType(
      Column column, AnalysisContext analyzer) {
    return (
      name: column.name,
      type: getDartTypeByBasicType(analyzer.typeOf(column).type?.type)
    );
  }

  String getMethodArgs(List<ColumnMethodArgs> args) {
    final namedArgs = args
        .map((e) => '    required ${e.dartType} ${e.sqlName.toCamelCase()}, \n')
        .join();
    return '{\n$namedArgs  }';
  }

  String getArgsAsMap(List<ColumnMethodArgs> args) {
    final padding = ' ' * 6;
    return '[\n'
        '${args.map((e) => "$padding  ${e.fieldName},\n").join('')}$padding]';
  }

  Method _generateMethodColumns(
    UpdateStatement stmt,
    AnalysisContext context,
  ) {
    final args = SqlExpressionsArgumentsBuilder(context)
        .getMethodParameters(stmt.selfAndDescendants);
    final dbArgs = args.args.join(',');
    final sqlCmd = stmt.toSql().replaceAll("'", r"\'");

    final code = '''
final result = await db.rawUpdate(
  '$sqlCmd', 
  [$dbArgs],
);

return result;''';

    return Method(
      (builder) => builder
        ..name = comment.name
        ..requiredParameters.addAll(args.positional)
        ..modifier = MethodModifier.async
        ..optionalParameters.addAll(args.named)
        ..returns = refer('Future<int>')
        ..body = Code(code),
    );
  }
}

typedef ColumnMethodArgs = ({
  String sqlName,
  String fieldName,
  String dartType,
});
