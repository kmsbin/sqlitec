import 'package:sqlitec/src/code_builders/class_builder.dart';
import 'package:sqlitec/src/registers/create_table_register.dart';

import 'class_factory_builder.dart';
import 'class_field_builder.dart';

class FromJsonBuilder extends ClassFactoryBuilder {
  final List<SqlColumnGeneratorDto> fields;

  FromJsonBuilder(this.fields)
      : super(
          name: 'fromJson',
          args: [
            ClassFieldBuilder(
                name: 'jsonMap', dartType: 'Map<String, dynamic>'),
          ],
        );

  String _getJsonMapArg(String field) => "jsonMap['$field']";

  @override
  String getArguments(ClassBuilder clazz) {
    final buffer = StringBuffer();
    for (final dto in fields) {
      buffer
        ..write('      ${dto.fieldName}: ')
        ..write(dto.generator.fromJson(_getJsonMapArg(dto.columnName)))
        ..writeln(',');
    }
    return buffer.toString();
  }
}
