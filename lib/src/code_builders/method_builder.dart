import 'class_builder.dart';

class MethodBuilder implements ClassChildBuilder {
  final String name;
  final List<FunctionArgument> arguments;
  final String? returnType;
  final String body;
  final bool isAsync;
  final int indentationSpaces;

  const MethodBuilder({
    required this.name,
    required this.body,
    this.isAsync = false,
    this.arguments = const [],
    this.returnType,
    this.indentationSpaces = 0,
  });

  @override
  String build([ClassBuilder? clazz]) {
    final spaces = clazz?.indentationSpaces ?? indentationSpaces;
    final buffer = StringBuffer(' ' * spaces);
    if (returnType != null) {
      buffer.write('${returnType!} ');
    }

    buffer
      ..write(name)
      ..write('(');
    final positionalArgs =
        arguments.whereType<PositionalArgument>().map((it) => it.build());

    if (positionalArgs.length < 3) {
      buffer.write(positionalArgs.join(', '));
    } else {
      buffer.write('\n');
      buffer.write(' ' * (spaces * 2) + positionalArgs.join(', \n'));
    }

    final namedArgs =
        arguments.whereType<NamedArgument>().map((it) => it.build());
    if (namedArgs.isNotEmpty) {
      if (positionalArgs.isNotEmpty) {
        buffer.write(', ');
      }
      buffer.write('{\n');

      buffer.write(' ' * (spaces * 2) + namedArgs.join(', \n'));
      buffer.write(',\n${' ' * spaces}}');
    }
    buffer.write(')');
    if (isAsync) buffer.write(' async');
    buffer.write(' {\n');
    buffer
        .writeAll(body.split('\n').map((it) => '${' ' * (spaces * 2)}$it\n'));
    buffer.write('${' ' * spaces}}');
    return buffer.toString();
  }
}

abstract interface class FunctionArgument {
  final String type;
  final String name;

  const FunctionArgument({
    required this.type,
    required this.name,
  });

  String build();
}

final class NamedArgument extends FunctionArgument {
  const NamedArgument(
      {required super.type, required super.name, this.isRequired = false});

  const NamedArgument.required({
    required super.type,
    required super.name,
  }) : isRequired = true;

  final bool isRequired;

  @override
  String build() {
    final buffer = StringBuffer();
    if (isRequired) {
      buffer.write('required ');
    }
    buffer.write('$type $name');
    return buffer.toString();
  }
}

final class PositionalArgument extends FunctionArgument {
  const PositionalArgument({
    required super.type,
    required super.name,
  });

  @override
  String build() {
    final buffer = StringBuffer();
    buffer.write('$type $name');
    return buffer.toString();
  }
}
