import 'package:sqlparser/sqlparser.dart';

class AnalysisSqlCmdException implements Exception {
  final List<AnalysisError> errors;

  const AnalysisSqlCmdException(this.errors);
}
