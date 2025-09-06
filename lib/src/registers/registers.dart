import 'package:code_builder/code_builder.dart';
import 'package:sqlparser/sqlparser.dart';

abstract interface class ActionRegister<T extends Statement> {
  Method register(T stmt);
}

abstract interface class DdlRegister<T extends Statement> {
  Class createTable(T stmt);
}
