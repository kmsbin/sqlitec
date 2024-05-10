import 'package:sqlitec/src/dql_analizer/comment_analizer.dart';
import 'package:sqlitec/src/dql_analizer/table_analizer.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';

abstract class ReturnBuilder {
  String buildType();
  String buildReturnFromJson(String jsonMapName, {required String padding});

  String getReturnByMode(ReturnMode mode, {int leftSpaceCount = 4}) {
    final spaces = ' ' * leftSpaceCount;
    return switch (mode) {
      ReturnMode.one => 'if (result.isEmpty) return null;\n'
          '${spaces}final resultFirst = result.first;\n'
          '${spaces}return ${buildReturnFromJson('resultFirst', padding: spaces)};',
      ReturnMode.many => 'return result.map((e) => ${buildReturnFromJson('e', padding: spaces)}).toList();',
      _ => '',
    };
  }

  String getGenerateReturn(AnalyzedComment comment) {
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

  String buildType() {
    final padding = ' ' * 4;
    final fields = params
      .map((e) => '$padding${e.generator.type} ${e.name},')
      .join('\n');
    return '({\n'
        '$fields\n'
        '  })?';
  }

  String buildReturnFromJson(String jsonMapName, {required String padding}) {
    return '''(
${params.map((e) => '$padding  ${e.name}: ${e.generator.fromJson("$jsonMapName['${e.name}']")},').join('\n')}    
    )''';
  }
}

class SingleTableBuilder extends ReturnBuilder {
  final TableAnalizer table;

  SingleTableBuilder(this.table);

  String buildType() => '${table.name}?';

  String buildReturnFromJson(String jsonMapName, {required String padding}) {
    return '${table.name}.fromJson($jsonMapName)';
  }
}

class SingleColumnBuilder extends ReturnBuilder {
  final String name;
  final DartTypeGenerator generator;

  SingleColumnBuilder(this.name, this.generator);

  String buildType() => '${generator.type}?';

  String buildReturnFromJson(String jsonMapName, {required String padding}) {
    return '''${generator.fromJson("$jsonMapName['$name']")}''';
  }
}