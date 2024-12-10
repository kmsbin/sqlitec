import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:sqlitec/src/code_builders/class_builder.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/exceptions/parser_sql_cmd_exeception.dart';
import 'package:sqlitec/src/registers/create_table_register.dart';
import 'package:sqlitec/src/registers/delete_register.dart';
import 'package:sqlitec/src/registers/update_register.dart';
import 'package:sqlparser/sqlparser.dart';

import '../code_builders/class_field_builder.dart';
import '../dql_analyzer/table_analyzer.dart';
import '../registers/insert_register.dart';
import '../registers/select_register.dart';

class SqliteGenerator extends Builder {
  final cmdAnalyzer = CmdAnalyzer();

  @override
  Future<void> build(BuildStep buildStep) async {
    try {
      final engine = SqlEngine();
      final cmds = await _getContents(buildStep, engine);

      final schemasBuffer = _writeDdlStmts(cmds, engine);
      final queriesBuffer = _writeDqlStmts(cmds, engine);

      if (queriesBuffer.isNotEmpty) {
        const import = "import 'package:sqflite_common/sqlite_api.dart';\n"
            "import 'schemas.sqlitec.dart';\n\n";

        await _writeInQueriesFile(buildStep, import + queriesBuffer);
      }
      if (schemasBuffer.isNotEmpty) {
        await _writeInSchemasFile(buildStep, schemasBuffer);
      }
    } on ParserSqlCmdException catch (e) {
      for (final error in e.errors) {
        log.shout(error.message);
      }
    } on AnalysisSqlCmdException catch (e) {
      for (final error in e.errors) {
        log.shout(error.message);
      }
    }
  }

  Future<List<ParseResult>> _getContents(
      BuildStep buildStep, SqlEngine engine) async {
    final injectableConfigFiles = Glob("lib/**.sqlitec.json");

    final contents = <String>[];
    await for (final id in buildStep.findAssets(injectableConfigFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));

      contents.add(json['content']);
    }

    if (contents.isEmpty) return [];
    final regexToRemoveAllCommentedSemicolon = RegExp(r'(.*--.*);');
    return contents
        .expand(
          (e) =>
              e.replaceAll(regexToRemoveAllCommentedSemicolon, '').split(';'),
        )
        .where((e) => e.trim().isNotEmpty)
        .map(engine.parse)
        .toList();
  }

  String _writeDdlStmts(List<ParseResult> cmds, SqlEngine engine) {
    final buffer = StringBuffer();
    for (final stmt
        in cmds.where((e) => e.rootNode is TableInducingStatement)) {
      if (stmt.errors.isNotEmpty) {
        throw ParserSqlCmdException(stmt.errors);
      }
      final result = switch (stmt.rootNode) {
        CreateTableStatement stmt =>
          CreateTableRegister(engine, cmdAnalyzer).register(stmt),
        _ => null,
      };
      if (result != null) {
        buffer.write(result);
      }
    }
    return buffer.toString();
  }

  String _writeDqlStmts(List<ParseResult> cmds, SqlEngine engine) {
    final rawMethods = <String>[];

    for (final stmt in cmds) {
      if (stmt.errors.isNotEmpty) {
        throw ParserSqlCmdException(stmt.errors);
      }
      final comment = CommentAnalysis.getCommentAnalize(stmt.sql);

      if (comment != null) {
        if (switch (stmt.rootNode) {
          SelectStatement stmt =>
            SelectRegister(engine, comment, cmdAnalyzer).register(stmt),
          InsertStatement stmt =>
            InsertRegister(engine, comment, cmdAnalyzer).register(stmt),
          UpdateStatement stmt =>
            UpdateRegister(engine, comment, cmdAnalyzer).register(stmt),
          DeleteStatement stmt =>
            DeleteRegister(engine, comment, cmdAnalyzer).register(stmt),
          _ => null,
        }
            case final generatedCode?) {
          rawMethods.add(generatedCode);
        }
      }
    }
    return ClassBuilder(
      name: 'Queries',
      fields: [ClassFieldBuilder(name: 'db', dartType: 'DatabaseExecutor')],
      rawMethods: rawMethods,
    ).build();
  }

  Future<void> _writeInQueriesFile(BuildStep buildStep, data) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/sqlitec/queries.sqlitec.dart'),
      (data),
    );
  }

  Future<void> _writeInSchemasFile(BuildStep buildStep, data) async {
    await buildStep.writeAsString(
      AssetId(buildStep.inputId.package, 'lib/sqlitec/schemas.sqlitec.dart'),
      data,
    );
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': [
          'sqlitec/queries.sqlitec.dart',
          'sqlitec/schemas.sqlitec.dart',
        ]
      };
}
