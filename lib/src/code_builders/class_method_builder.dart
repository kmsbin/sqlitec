import 'class_builder.dart';

abstract class ClassMethodBuilder implements ClassChildBuilder {
  String returnType;
  String name;

  ClassMethodBuilder({
    required this.returnType,
    required this.name,
  });

  @override
  String build(ClassBuilder clazz) {
    final buffer = StringBuffer('  $returnType $name() {\n');
    buffer
      ..write('    return ${getMethodReturn(clazz)}')
      ..writeln('  }')
    ;
    return buffer.toString();
  }

  String getMethodReturn(ClassBuilder clazz);
}