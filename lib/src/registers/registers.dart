import 'package:sqlparser/sqlparser.dart';

abstract interface class Register<T extends Statement> {
  String register(T stmt);
}
