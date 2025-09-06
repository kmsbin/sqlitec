import 'package:change_case/change_case.dart';
import 'package:code_builder/code_builder.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import 'registers.dart';

// Todo: validate arg count with column count
class InsertRegister implements ActionRegister<InsertStatement> {
  final SqlEngine engine;
  final CmdAnalyzer cmdAnalyzer;
  final AnalyzedComment comment;

  const InsertRegister(
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
    final sqlStmt = context.root as InsertStatement;

    return generateMethodColumns(sqlStmt, context);
  }

  ({String name, String type})? getReturnType(
      Column column, AnalysisContext analyzer) {
    return (
      name: column.name,
      type: getDartTypeByBasicType(analyzer.typeOf(column).type?.type)
    );
  }

  Method generateMethodColumns(
    InsertStatement stmt,
    AnalysisContext analyzer,
  ) {
    final args = _getFields(analyzer, stmt.resolvedTargetColumns ?? <Column>[]);

    final sqlCmd = stmt.toSql().replaceAll("'", r"\'");
    final sqlCmdArgs = args.map((e) => e.fieldName).join(',');
    final code = '''
  return await db.rawInsert(
    '$sqlCmd', 
    [$sqlCmdArgs,],
  );''';

    return Method(
      (builder) => builder
        ..name = comment.name
        ..returns = refer('Future<int>')
        ..modifier = MethodModifier.async
        ..body = Code(code)
        ..optionalParameters.addAll([
          for (final arg in args)
            Parameter((builder) => builder
              ..required = true
              ..type = refer(arg.dartType)
              ..name = arg.sqlName.toCamelCase()
              ..named = true)
        ]),
    );
  }

  List<ColumnMethodArgs> _getFields(
    AnalysisContext context,
    List<Column?> columns,
  ) =>
      [
        for (final column in columns.whereType<Column>())
          (
            sqlName: column.name,
            fieldName: column.name.toCamelCase(),
            dartType: getDartTypeByBasicType(context.typeOf(column).type?.type),
          ),
      ];
}

typedef ColumnMethodArgs = ({
  String sqlName,
  String fieldName,
  String dartType,
});
