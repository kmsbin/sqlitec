import 'package:sqlparser/sqlparser.dart';

class ParserSqlCmdException implements Exception {
  final List<ParsingError> errors;

  const ParserSqlCmdException(this.errors);
}
