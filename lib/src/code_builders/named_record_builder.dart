import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';

abstract class ReturnBuilder {
  String buildType();
  String buildReturnFromJson(String jsonMapName, {required String padding});

  String getReturnByMode(ReturnMode mode, {int leftSpaceCount = 4}) {
    final spaces = ' ' * leftSpaceCount;
    return switch (mode) {
      ReturnMode.one => 'if (result.isEmpty) return null;\n'
          'final resultFirst = result.first;\n'
          'return ${buildReturnFromJson('resultFirst', padding: '')};',
      ReturnMode.many =>
        'return result.map((e) => ${buildReturnFromJson('e', padding: spaces)}).toList();',
      _ => '',
    };
  }

  String getReturnType(AnalyzedComment comment) {
    return switch (comment.mode) {
      ReturnMode.many => 'Future<List<${buildType()}>>',
      ReturnMode.one => 'Future<${buildType()}>',
      _ => 'Future<void>',
    };
  }
}

class NamedRecordBuilder extends ReturnBuilder {
  final List<({String name, DartTypeGenerator generator})> params;

  NamedRecordBuilder(this.params);

  @override
  String buildType() {
    final padding = ' ' * 4;
    final fields =
        params.map((e) => '$padding${e.generator.type} ${e.name},').join('\n');
    return '({\n'
        '$fields\n'
        '  })?';
  }

  @override
  String buildReturnFromJson(String jsonMapName, {required String padding}) {
    return '''(
${params.map((e) => '$padding  ${e.name}: ${e.generator.fromJson("$jsonMapName['${e.name}']")},').join('\n')}    
    )''';
  }
}

class SingleTableBuilder extends ReturnBuilder {
  final TableAnalyzer table;

  SingleTableBuilder(this.table);

  @override
  String buildType() => '${table.name}?';

  @override
  String buildReturnFromJson(String jsonMapName, {required String padding}) {
    return '${table.name}.fromJson($jsonMapName)';
  }
}

class SingleColumnBuilder extends ReturnBuilder {
  final String name;
  final DartTypeGenerator generator;

  SingleColumnBuilder(this.name, this.generator);

  @override
  String buildType() => '${generator.type}?';

  @override
  String buildReturnFromJson(String jsonMapName, {required String padding}) {
    return generator.fromJson("$jsonMapName['$name']");
  }
}
