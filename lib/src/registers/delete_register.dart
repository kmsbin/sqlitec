import 'package:change_case/change_case.dart';
import 'package:sqlitec/src/code_builders/method_builder.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/sql_expressions_arguments_builder.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import 'registers.dart';

class DeleteRegister implements Register<DeleteStatement> {
  final SqlEngine engine;
  final CmdAnalyzer cmdAnalyzer;
  final AnalyzedComment comment;

  const DeleteRegister(this.engine, this.comment, this.cmdAnalyzer);

  @override
  String register(stmt) {
    final context = engine.analyze(stmt.toSql());

    if (context.errors.isNotEmpty) {
      throw AnalysisSqlCmdException(context.errors);
    }
    final sqlStmt = context.root as DeleteStatement;

    return generateMethodColumns(sqlStmt, context);
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

  String generateMethodColumns(
    DeleteStatement stmt,
    AnalysisContext context,
  ) {
    final args = SqlExpressionsArgumentsBuilder(context)
        .generateFunctionArgs(stmt.selfAndDescendants);

    final body = '''
final result = await db.rawDelete(
  '${stmt.toSql().replaceAll("'", r"\'")}',  
  [\n${args.map((e) => '    ${e.name}').join(', \n')}
  ],
);

return result;''';

    return MethodBuilder(
      name: comment.name,
      returnType: 'Future<int>',
      isAsync: true,
      arguments: args,
      indentationSpaces: 2,
      body: body,
    ).build();
  }
}

typedef ColumnMethodArgs = ({
  String sqlName,
  String fieldName,
  String dartType,
});
