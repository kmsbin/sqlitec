import 'dart:async';
import 'dart:convert';

import 'package:build/build.dart';
import 'package:code_builder/code_builder.dart' as cb;
import 'package:glob/glob.dart';
import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/exceptions/analysis_sql_cmd_exception.dart';
import 'package:sqlitec/src/exceptions/parser_sql_cmd_exeception.dart';
import 'package:sqlitec/src/registers/create_table_register.dart';
import 'package:sqlitec/src/registers/delete_register.dart';
import 'package:sqlitec/src/registers/update_register.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:dart_style/dart_style.dart';
import '../dql_analyzer/table_analyzer.dart';
import '../registers/insert_register.dart';
import '../registers/select_register.dart';

final _dartfmt = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

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
    BuildStep buildStep,
    SqlEngine engine,
  ) async {
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
    final classes = <cb.Class>[];
    final stmts = cmds.where((e) => e.rootNode is TableInducingStatement);

    for (final stmt in stmts) {
      if (stmt.errors.isNotEmpty) {
        throw ParserSqlCmdException(stmt.errors);
      }
      final rootNode = stmt.rootNode;
      if (rootNode is CreateTableStatement) {
        final result =
            CreateTableRegister(engine, cmdAnalyzer).createTable(rootNode);

        classes.add(result);
      }
    }

    final lib = cb.Library((builder) => builder.body.addAll(classes))
        .accept(cb.DartEmitter())
        .toString();

    return _dartfmt.format(lib);
  }

  String _writeDqlStmts(List<ParseResult> cmds, SqlEngine engine) {
    final methods = <cb.Method>[];

    for (final stmt in cmds) {
      if (stmt.errors.isNotEmpty) {
        throw ParserSqlCmdException(stmt.errors);
      }
      final comment = CommentAnalysis.getCommentAnalize(stmt.sql);

      if (comment != null) {
        final method = switch (stmt.rootNode) {
          SelectStatement stmt =>
            SelectRegister(engine, comment, cmdAnalyzer).register(stmt),
          InsertStatement stmt =>
            InsertRegister(engine, comment, cmdAnalyzer).register(stmt),
          UpdateStatement stmt =>
            UpdateRegister(engine, comment, cmdAnalyzer).register(stmt),
          DeleteStatement stmt =>
            DeleteRegister(engine, comment, cmdAnalyzer).register(stmt),
          _ => null
        };
        if (method != null) {
          methods.add(method);
        }
      }
    }

    final clazz = cb.Class(
      (builder) => builder
        ..name = 'Queries'
        ..methods.addAll(methods)
        ..constructors.add(
          cb.Constructor((builder) => builder
            ..constant = true
            ..requiredParameters.add(
              cb.Parameter((builder) => builder
                ..toThis = true
                ..name = 'db'),
            )),
        )
        ..fields.add(
          cb.Field(
            (builder) => builder
              ..modifier = cb.FieldModifier.final$
              ..name = 'db'
              ..type = cb.refer('DatabaseExecutor'),
          ),
        ),
    );

    return _dartfmt.format(clazz.accept(cb.DartEmitter()).toString());
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
