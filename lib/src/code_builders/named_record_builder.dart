import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';

abstract class ReturnBuilder {
  const ReturnBuilder();

  String get buildType;
  String buildReturnFromJson(String jsonMapName);

  String getReturnByMode(ReturnMode mode) {
    return switch (mode) {
      ReturnMode.one => 'if (result.isEmpty) return null;\n'
          'final resultFirst = result.first;\n'
          'return ${buildReturnFromJson('resultFirst')};',
      ReturnMode.many =>
        'return result.map((e) => ${buildReturnFromJson('e')}).toList();',
      ReturnMode.exec => '',
    };
  }

  String getReturnType(AnalyzedComment comment) {
    return switch (comment.mode) {
      ReturnMode.many => 'Future<List<$buildType>>',
      ReturnMode.one => 'Future<$buildType>',
      ReturnMode.exec => 'Future<void>',
    };
  }
}

class NamedRecordReturnBuilder extends ReturnBuilder {
  const NamedRecordReturnBuilder(this.params);

  final List<({String name, DartTypeGenerator generator})> params;

  @override
  String get buildType {
    final padding = ' ' * 4;
    final fields =
        params.map((e) => '$padding${e.generator.type} ${e.name},').join('\n');
    return '({\n'
        '$fields\n'
        '  })?';
  }

  @override
  String buildReturnFromJson(String jsonMapName) {
    return '''(
${params.map((e) => '${e.name}: ${e.generator.fromJson("$jsonMapName['${e.name}']")},').join('\n')}    
    )''';
  }
}

class TableReturnBuilder extends ReturnBuilder {
  final TableAnalyzer table;

  const TableReturnBuilder(this.table);

  @override
  String get buildType => '${table.name}?';

  @override
  String buildReturnFromJson(String jsonMapName) {
    return '${table.name}.fromJson($jsonMapName)';
  }
}

class ColumnReturnBuilder extends ReturnBuilder {
  final String name;
  final DartTypeGenerator generator;

  const ColumnReturnBuilder(this.name, this.generator);

  @override
  String get buildType => '${generator.type}?';

  @override
  String buildReturnFromJson(String jsonMapName) {
    return generator.fromJson("$jsonMapName['$name']");
  }
}
