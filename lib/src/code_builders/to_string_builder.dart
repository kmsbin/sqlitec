import 'package:sqlitec/src/code_builders/class_builder.dart';
import 'package:sqlitec/src/code_builders/class_method_builder.dart';
import 'package:sqlitec/src/registers/create_table_register.dart';

class ToStringBuilder extends ClassMethodBuilder {
  final List<SqlColumnGeneratorDto> fields;

  ToStringBuilder(this.fields) : super(
    returnType: 'String',
    name: 'toString',
  );

  @override
  String getMethodReturn(ClassBuilder clazz) {
    final buffer = StringBuffer('${clazz.name}(\n');
    for (final field in fields) {
      buffer.writeln("  ${field.fieldName}: \$${field.fieldName},");
    }
    buffer.write(')');
    return "'''${buffer.toString()}''';";
  }

}