
import 'package:sqlitec/src/code_builders/class_factory_builder.dart';

import 'class_field_builder.dart';

abstract class ClassSyntaxBuilder {
  String build();
}

class ClassBuilder implements ClassSyntaxBuilder {
  final String name;
  final List<ClassChildBuilder> fields;
  final List<ClassChildBuilder> methods;
  final List<String> rawMethods;

  ClassBuilder({
    required this.name,
    this.fields = const [],
    this.methods = const [],
    this.rawMethods = const [],
  });

  @override
  String build() {
    final buffer = StringBuffer()
      ..writeln('class $name {');
    for (final column in fields) {
      buffer.writeln('  ${column.build(this)}');
    }
    buffer.write(generateConstructor());
    for (final fac in methods) {
      buffer
        ..write('\n')
        ..write(fac.build(this));
    }
    for (final method in rawMethods) {
      buffer
        ..write('\n')
        ..write(method);
    }
    buffer.writeln('\n}');
    return buffer.toString();
  }

  String generateConstructor() {
    final buffer = StringBuffer('\n')
      ..writeln('  $name({');
    for (final child in fields.whereType<ClassFieldBuilder>()) {
      if (!child.isStatic) {
        buffer.writeln('    ${child.constructorBuild()}');
      }
    }
    buffer.writeln('  });');
    return buffer.toString();
  }
}

abstract interface class ClassChildBuilder {
  String build(ClassBuilder clazz);
}



