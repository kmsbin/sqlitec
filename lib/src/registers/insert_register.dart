import 'package:change_case/change_case.dart';
import 'package:sqlitec/src/builder.dart';
import 'package:sqlitec/src/dql_analizer/comment_analizer.dart';
import 'package:sqlitec/src/dql_analizer/table_analizer.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import 'registers.dart';
// Todo: validate arg count with column count
class InsertRegister implements Register<InsertStatement> {
  @override
  final SqlEngine engine;
  final CmdAnalizer cmdAnalizer;
  final AnalyzedComment comment;

  InsertRegister(this.engine, this.comment, this.cmdAnalizer);

  @override
  String register(stmt) {
    final context = engine.analyze(stmt.toSql());

    if (context.errors.isNotEmpty) {
      throw ErrorAnalysisSqlCmd(context.errors);
    }
    final sqlStmt = context.root as InsertStatement;

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
    InsertStatement stmt,
    AnalysisContext analizer,
  ) {
    final args = getFields(analizer, stmt.resolvedTargetColumns ?? <Column>[]);
    return '''
  Future<int> ${comment.name}(${getMethodArgs(args)}) async { 
    final result = await db.rawInsert(
      '${stmt.toSql().replaceAll("'", r"\'")}', 
      ${getArgsAsMap(args)},
    );
    
    return result;
  }\n''';
  }

  List<ColumnMethodArgs> getFields(AnalysisContext context, List<Column?> columns) {
    final nameAndArg = <ColumnMethodArgs>[];
    for (final column in columns.whereType<Column>()) {
      nameAndArg.add((
        sqlName: column.name,
        fieldName: column.name.toCamelCase(),
        dartType: getDartTypeByBasicType(context.typeOf(column).type?.type),
      ));

    }
    return nameAndArg;
  }

}

typedef ColumnMethodArgs = ({
  String sqlName,
  String fieldName,
  String dartType,
});