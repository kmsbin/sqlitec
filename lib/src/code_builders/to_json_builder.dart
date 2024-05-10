import 'package:sqlitec/src/code_builders/class_builder.dart';
import 'package:sqlitec/src/code_builders/class_method_builder.dart';
import 'package:sqlitec/src/registers/create_table_register.dart';

class ToJsonBuilder extends ClassMethodBuilder {
  final List<SqlColumnGeneratorDto> fields;

  ToJsonBuilder(this.fields) : super(
    returnType: 'Map<String, dynamic>',
    name: 'toJson',
  );

  @override
  String getMethodReturn(ClassBuilder clazz) {
    final buffer = StringBuffer('{\n');
    for (final field in fields) {
      buffer.writeln("      '${field.columnName}': ${field.generator.toJson(field.fieldName)},");
    }
    buffer.writeln('    };');
    return buffer.toString();
  }

}