import 'package:sqlparser/sqlparser.dart';

abstract interface class Register<T extends Statement> {
  SqlEngine get engine;

  String register(T stmt);
}