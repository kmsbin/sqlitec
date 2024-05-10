import 'package:change_case/change_case.dart';
import 'package:sqlitec/src/builder.dart';
import 'package:sqlitec/src/dql_analizer/comment_analizer.dart';
import 'package:sqlitec/src/dql_analizer/sql_expressions_arguments_builder.dart';
import 'package:sqlitec/src/dql_analizer/table_analizer.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import 'registers.dart';

class UpdateRegister implements Register<UpdateStatement> {
  @override
  final SqlEngine engine;
  final CmdAnalizer cmdAnalizer;
  final AnalyzedComment comment;

  const UpdateRegister(this.engine, this.comment, this.cmdAnalizer);

  @override
  String register(stmt) {
    final context = engine.analyze(stmt.toSql());

    if (context.errors.isNotEmpty) {
      throw ErrorAnalysisSqlCmd(context.errors);
    }
    final sqlStmt = context.root as UpdateStatement;

    return generateMethodColumns(sqlStmt, context);
  }


  ({String name, String type})? getReturnType(Column column, AnalysisContext analizer) {
    return (
      name: column.name,
      type: getDartTypeByBasicType(analizer.typeOf(column).type?.type)
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
      '${args.map((e) => "$padding  ${e.fieldName},\n").join('')
    }$padding]';
  }

  String generateMethodColumns(
    UpdateStatement stmt,
    AnalysisContext context,
  ) {
    final (args, fields) = SqlExpressionsArgumentsBuilder(context).generateFunctionArgs(stmt.selfAndDescendants);;
    return '''
  Future<int> ${comment.name}($args) async { 
    final result = await db.rawUpdate(
      '${stmt.toSql().replaceAll("'", r"\'")}', 
      [\n${fields.map((e) => '        $e').join(', \n')}
      ],
    );
    
    return result;
  }\n''';
  }
}

typedef ColumnMethodArgs = ({
  String sqlName,
  String fieldName,
  String dartType,
});