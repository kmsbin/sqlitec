import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:sqlitec/src/code_builders/class_builder.dart';
import 'package:sqlitec/src/dql_analizer/comment_analizer.dart';
import 'package:sqlitec/src/registers/create_table_register.dart';
import 'package:sqlitec/src/registers/delete_register.dart';
import 'package:sqlitec/src/registers/update_register.dart';
import 'package:sqlparser/sqlparser.dart';

import 'code_builders/class_field_builder.dart';
import 'dql_analizer/table_analizer.dart';
import 'registers/insert_register.dart';
import 'registers/select_register.dart';

class SqliteBuilder extends Builder {
  final BuilderOptions options;

  SqliteBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions => {
    '.sql': ['.sqlitec.json'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final id = buildStep.inputId;
    final copy = id.changeExtension('.sqlitec.json');
    final content = await buildStep.readAsString(id);
    final jsonContent = {
      "nameField": Random().nextInt(100).toString(),
      "content": content,
    };
    await buildStep.writeAsString(copy, jsonEncode(jsonContent));
  }
}

class SqliteGenerator extends Builder {
  final cmdAnalizer = CmdAnalizer();

  @override
  Future<void> build(BuildStep buildStep) async {
    try {
      final engine = SqlEngine();
      final cmds = await _getContents(buildStep, engine);

      final schemasBuffer = _writeDdlStmts(cmds, engine);
      final queriesBuffer = _writeDqlStmts(cmds, engine);

      if (queriesBuffer.isNotEmpty) {
        final import = "import 'package:sqflite_common/sqlite_api.dart';\n"
            "import 'schemas.sqlitec.dart';\n\n";

        await _writeInQueriesFile(buildStep, import+queriesBuffer);
      }
      if (schemasBuffer.isNotEmpty) {
        await _writeInSchemasFile(buildStep, schemasBuffer);
      }
    } on ErrorParsingSqlCmd catch(e) {
      for (final error in e.errors) {
        print(error.message);
      }
    } on ErrorAnalysisSqlCmd catch(e) {
      for (final error in e.errors) {
        print(error.message);
      }
    }
  }

  Future<List<ParseResult>> _getContents(BuildStep buildStep, SqlEngine engine) async {
    final injectableConfigFiles = Glob("lib/**.sqlitec.json");

    final contents = <String>[];
    await for (final id in buildStep.findAssets(injectableConfigFiles)) {
      final json = jsonDecode(await buildStep.readAsString(id));

      contents.add(json['content']);
    }

    if (contents.isEmpty) return [];
    final regexToRemoveAllCommentedSemicolon = RegExp(r'(.*--.*);');
    return contents
      .expand((e) => e
        .replaceAll(regexToRemoveAllCommentedSemicolon, '')
        .split(';'),
      )
      .where((e) => e.trim().isNotEmpty)
      .map(engine.parse)
      .toList();
  }

  String _writeDdlStmts(List<ParseResult> cmds, SqlEngine engine) {
    final buffer = StringBuffer();
    for (final stmt in cmds.where((e) => e.rootNode is CreateTableStatement)) {
      if (stmt.errors.isNotEmpty) {
        throw ErrorParsingSqlCmd(stmt.errors);
      }
      final registeredTable = CreateTableRegister(engine, cmdAnalizer).register(stmt.rootNode as CreateTableStatement);
      buffer.write(registeredTable);
    }
    return buffer.toString();
  }

  String _writeDqlStmts(List<ParseResult> cmds, SqlEngine engine) {
    final rawMethods = <String>[];

    for (final stmt in cmds) {
      if (stmt.errors.isNotEmpty) {
        throw ErrorParsingSqlCmd(stmt.errors);
      }
      final comment = CommentAnalysis.getCommentAnalize(stmt.sql);

      if (comment != null) {
        if (switch(stmt.rootNode) {
          SelectStatement stmt => SelectRegister(engine, comment, cmdAnalizer).register(stmt),
          InsertStatement stmt => InsertRegister(engine, comment, cmdAnalizer).register(stmt),
          UpdateStatement stmt => UpdateRegister(engine, comment, cmdAnalizer).register(stmt),
          DeleteStatement stmt => DeleteRegister(engine, comment, cmdAnalizer).register(stmt),
          _ => null,
        } case final generatedCode?) {
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

class ErrorParsingSqlCmd implements Exception {
  final List<ParsingError> errors;

  const ErrorParsingSqlCmd(this.errors);
}

class ErrorAnalysisSqlCmd implements Exception {
  final List<AnalysisError> errors;

  const ErrorAnalysisSqlCmd(this.errors);
}
