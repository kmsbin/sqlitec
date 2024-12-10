import 'class_builder.dart';

class ClassFieldBuilder implements ClassChildBuilder {
  bool isFinal;
  bool isConst;
  bool isStatic;
  bool isNullable;
  String dartType;
  String name;
  String? defaultValue;

  ClassFieldBuilder({
    required this.name,
    this.isFinal = false,
    this.isConst = false,
    this.dartType = 'dynamic',
    this.isNullable = false,
    this.isStatic = false,
    this.defaultValue,
  }) {
    assert(!(isConst && isFinal));
    if (dartType.trim().endsWith('?')) {
      isNullable = true;
    }
    dartType = dartType.trim();
  }

  @override
  String build(clazz) {
    final buffer = StringBuffer();
    if (isStatic) {
      buffer.write('static ');
    }
    if (isFinal) {
      buffer.write('final ');
    } else if (isConst) {
      buffer.write('const ');
    }
    buffer.write(dartType);
    if (isNullable && dartType != 'dynamic' && !dartType.endsWith('?')) {
      buffer.write('?');
    }
    buffer.write(' $name');
    if (defaultValue != null) {
      buffer.write(' = $defaultValue');
    }
    buffer.write(';');

    return buffer.toString();
  }

  String constructorBuild() {
    final buffer = StringBuffer();
    if (!isNullable) {
      buffer.write('required ');
    }
    buffer
      ..write('this.')
      ..write(name)
      ..write(',');
    return buffer.toString();
  }

  String constructAsArg() => '$dartType $name';
}
