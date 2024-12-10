import 'package:sqlitec/src/registers/create_table_register.dart';

import 'method_builder.dart';

class ToStringBuilder extends MethodBuilder {
  ToStringBuilder(List<SqlColumnGeneratorDto> fields, String clazzName)
      : super(
          returnType: 'String',
          name: 'toString',
          body: _buildMethodBody(fields, clazzName),
        );

  static String _buildMethodBody(
      List<SqlColumnGeneratorDto> fields, String clazzName) {
    final buffer = StringBuffer('$clazzName(\n');
    for (final field in fields) {
      buffer.writeln("  ${field.fieldName}: \$${field.fieldName},");
    }
    buffer.write(')');
    return "return ''' ${buffer.toString()}''';";
  }
}
