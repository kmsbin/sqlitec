import 'package:sqlparser/sqlparser.dart';

extension SqlToSqliteTable on SqlEngine {
  void registerRawTable(String cmd) {
    final stmt = parse(cmd).rootNode;
    if (stmt is! CreateTableStatement) {
      throw Exception('The command is not a create table statement');
    }

    final table = const SchemaFromCreateTable(driftExtensions: true).read(stmt);

    registerTable(table);
  }
}
