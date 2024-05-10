import 'class_builder.dart';
import 'class_field_builder.dart';

abstract class ClassFactoryBuilder implements ClassChildBuilder {
  String name;
  List<ClassFieldBuilder> args;

  ClassFactoryBuilder({
    required this.name,
    required this.args,
  });

  @override
  String build(ClassBuilder clazz) {
    final buffer = StringBuffer();
    buffer
      ..write(('  factory ${clazz.name}.$name('))
      ..write(args.map((e) => e.constructAsArg()).join(', '))
      ..writeln(') {')
      ..writeln('    return ${clazz.name}(')
      ..write(getArguments(clazz))
      ..writeln('    );')
      ..write('  }')
    ;
    return buffer.toString();
  }

  String getArguments(ClassBuilder clazz);
}