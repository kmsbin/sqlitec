import 'package:change_case/change_case.dart';
import 'package:sqlitec/src/type_converters/dart_type_generator/dart_type_generator.dart';
import 'package:collection/collection.dart';

class TableAnalizer {
  final String name;
  final List<ColumnTableAnalizer> columns;

  TableAnalizer({
    required this.name,
    required this.columns,
  });
}

class ColumnTableAnalizer {
  final String name;
  final DartTypeGenerator generator;

  ColumnTableAnalizer({required this.name, required this.generator});
}

class CmdAnalizer {
  final List<TableAnalizer> tables;

  CmdAnalizer({List<TableAnalizer>? tables}) : tables = [];

  void addTable(TableAnalizer table) {
    if (tables.any((e) => e.name == table.name)) {
      throw Exception('2 tables with same name');
    }
    tables.add(table);
  }

  TableAnalizer? findTableByName(String name) {
    name = name.toPascalCase();
    return tables.firstWhereOrNull((table) => table.name == name);
  }

}