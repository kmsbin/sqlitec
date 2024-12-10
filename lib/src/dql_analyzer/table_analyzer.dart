import 'package:change_case/change_case.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:collection/collection.dart';

class TableAnalyzer {
  final String name;
  final List<ColumnTableAnalyzer> columns;

  const TableAnalyzer({
    required this.name,
    required this.columns,
  });
}

class ColumnTableAnalyzer {
  final String name;
  final DartTypeGenerator generator;

  const ColumnTableAnalyzer({required this.name, required this.generator});
}

class CmdAnalyzer {
  final List<TableAnalyzer> tables;

  CmdAnalyzer({List<TableAnalyzer>? tables}) : tables = tables ?? [];

  void addTable(TableAnalyzer table) {
    if (tables.any((e) => e.name == table.name)) {
      throw Exception('2 tables with same name');
    }
    tables.add(table);
  }

  TableAnalyzer? findTableByName(String name) {
    name = name.toPascalCase();
    return tables.firstWhereOrNull((table) => table.name == name);
  }
}
