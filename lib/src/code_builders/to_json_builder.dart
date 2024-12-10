import 'package:sqlitec/src/registers/create_table_register.dart';

import 'method_builder.dart';

class ToJsonBuilder extends MethodBuilder {
  ToJsonBuilder(List<SqlColumnGeneratorDto> fields)
      : super(
          returnType: 'Map<String, dynamic>',
          name: 'toJson',
          body: _getMethodReturn(fields),
        );

  static String _getMethodReturn(List<SqlColumnGeneratorDto> fields) {
    final buffer = StringBuffer('return {\n');
    for (final field in fields) {
      buffer.writeln(
          "  '${field.columnName}': ${field.generator.toJson(field.fieldName)},");
    }
    buffer.writeln('};');
    return buffer.toString();
  }
}
