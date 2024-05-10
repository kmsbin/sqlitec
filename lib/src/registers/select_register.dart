import 'package:sqlitec/src/builder.dart';
import 'package:sqlitec/src/dql_analizer/comment_analizer.dart';
import 'package:sqlitec/src/dql_analizer/sql_expressions_arguments_builder.dart';
import 'package:sqlitec/src/dql_analizer/table_analizer.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:sqlparser/utils/node_to_text.dart';

import '../code_builders/named_record_builder.dart';
import 'registers.dart';

class SelectRegister implements Register<SelectStatement> {
  @override
  final SqlEngine engine;
  final CmdAnalizer cmdAnalizer;
  final AnalyzedComment comment;

  SelectRegister(this.engine, this.comment, this.cmdAnalizer);

  @override
  String register(stmt) {
    final context = engine.analyze(stmt.toSql());

    if (context.errors.isNotEmpty) {
      throw ErrorAnalysisSqlCmd(context.errors);
    }
    final sqlStmt = context.root as SelectStatement;

    return generateMethod(sqlStmt, context);
  }

  ReturnBuilder getReturnTypeBySelectStatement(SelectStatement stmt, AnalysisContext analizer) {
    if (stmt.resolvedColumns?.length == 1) {
      final column = stmt.resolvedColumns!.first;
      return SingleColumnBuilder(
        column.name,
        getDartGeneratorFromBasicType(analizer.typeOf(column).type),
      );
    }
    if (stmt.columns.length == 1 && stmt.columns.first is StarResultColumn) {
      final startTable = (stmt.columns.first as StarResultColumn).tableName;
      if (startTable != null) {
        final table = cmdAnalizer.findTableByName(startTable);
        if (table != null) {
          return SingleTableBuilder(table);
        }
      }
      if (stmt.from case TableReference ref) {
        final table = cmdAnalizer.findTableByName(ref.tableName);
        if (table != null) {
          return SingleTableBuilder(table);
        }
      }
    }
    final resultTypes = <({String name, DartTypeGenerator generator})>[
      for (final column in stmt.resolvedColumns ?? <Column>[])
        (
          name: column.name,
          generator: getDartGeneratorFromBasicType(analizer.typeOf(column).type),
        ),
    ];
    return NamedRecordBuilder(resultTypes);
  }

  ({String name, String type})? getReturnType(Column column, AnalysisContext analizer) {
    return (
      name: column.name,
      type: getDartTypeByBasicType(analizer.typeOf(column).type?.type)
    );
  }

  String generateMethod(
    SelectStatement stmt,
    AnalysisContext analizer,
  ) {
    final buffer = StringBuffer();
    final (methodArgs, dbArgs) = SqlExpressionsArgumentsBuilder(analizer)
      .generateFunctionArgs(stmt.selfAndDescendants);
    final paramReturnBuilder = getReturnTypeBySelectStatement(stmt, analizer);
    buffer.write('''
  ${paramReturnBuilder.getGenerateReturn(comment)} ${comment.name}($methodArgs) async { 
    final result = await db.rawQuery(
      '${stmt.toSql().replaceAll("'", r"\'")}', 
      [${dbArgs.join(', ')}],
    );

    ${paramReturnBuilder.getReturnByMode(comment.mode)}
  }
    ''');
    return buffer.toString();
  }

}

class InterrogationColonNamed extends ColonNamedVariable {

  InterrogationColonNamed.synthetic(super.name) : super.synthetic();

}
