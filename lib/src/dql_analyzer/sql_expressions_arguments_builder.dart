import 'package:code_builder/code_builder.dart' as builder;
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';

final class SqlExpressionsArgumentsBuilder {
  final AnalysisContext context;

  const SqlExpressionsArgumentsBuilder(this.context);

  List<ExpressionField> _getFields(Iterable<AstNode> nodes) {
    final fields = <ExpressionField>[];

    for (final descendant in nodes) {
      final field = switch (descendant) {
        BinaryExpression field => [_getBinaryExpression(field)],
        InExpression field => _getInExpression(field),
        BetweenExpression field => [_getBetweenExpression(field)],
        CaseExpression field => [_getCaseExpression(field)],
        SingleColumnSetComponent field => [_getSetComponentExpression(field)],
        StringComparisonExpression field => [
            _getStringComparisonExpression(field)
          ],
        _ => null,
      };

      if (field != null) {
        fields.addAll(field.whereType());
      }
    }
    return fields;
  }

  ArgsParameters getMethodParameters(Iterable<AstNode> nodes) {
    final fields = _getFields(nodes);
    final args = ArgsParameters();

    for (final (i, arg) in fields.indexed) {
      final paramType = builder.refer(getDartTypeByBasicType(arg.type));
      final argName = arg.name ?? '\$arg${i + 1}';

      if (arg.name case final paramName?) {
        final parameter = builder.Parameter(
          (builder) => builder
            ..name = paramName
            ..named = true
            ..type = paramType
            ..required = true,
        );

        args.named.add(parameter);
      } else {
        final parameter = builder.Parameter(
          (builder) => builder
            ..name = '\$arg${i + 1}'
            ..named = false
            ..required = false
            ..type = paramType,
        );

        args.positional.add(parameter);
      }
      args.args.add(argName);
    }

    return args;
  }

  bool isExpressionValid(Expression exp) =>
      (exp is NumberedVariable && exp.span?.text == '?') ||
      exp is ColonNamedVariable;

  String? getNameFromSpan(Expression argExp) {
    if (argExp is ColonNamedVariable) {
      return argExp.name.substring(1);
    }
    return null;
  }

  List<ExpressionField?>? _getInExpression(InExpression exp) {
    if (exp.inside case Tuple tuple) {
      return [
        for (final argExp in tuple.expressions)
          if (isExpressionValid(argExp))
            ExpressionField(
              name: getNameFromSpan(argExp),
              type: context.typeOf(exp.left).type?.type ?? BasicType.any,
            )
      ];
    }
    return null;
  }

  ExpressionField? _getBetweenExpression(BetweenExpression exp) {
    if (isExpressionValid(exp.upper)) {
      return ExpressionField(
        name: getNameFromSpan(exp.upper),
        type: context.typeOf(exp.lower).type?.type ?? BasicType.any,
      );
    }
    if (isExpressionValid(exp.lower)) {
      return ExpressionField(
        name: getNameFromSpan(exp.lower),
        type: context.typeOf(exp.upper).type?.type ?? BasicType.any,
      );
    }
    return null;
  }

  ExpressionField? _getStringComparisonExpression(
      StringComparisonExpression exp) {
    if (isExpressionValid(exp.left)) {
      return ExpressionField(
        name: getNameFromSpan(exp.left),
        type: context.typeOf(exp.right).type?.type ?? BasicType.any,
      );
    }
    if (isExpressionValid(exp.right)) {
      final right = exp.right;
      exp.right = NumberedVariable(null);
      return ExpressionField(
        name: getNameFromSpan(right),
        type: context.typeOf(exp.left).type?.type ?? BasicType.any,
      );
    }
    return null;
  }

  ExpressionField? _getBinaryExpression(BinaryExpression exp) {
    if (isExpressionValid(exp.left)) {
      return ExpressionField(
        name: getNameFromSpan(exp.left),
        type: context.typeOf(exp.right).type?.type ?? BasicType.any,
      );
    }
    if (isExpressionValid(exp.right)) {
      final right = exp.right;
      exp.right = NumberedVariable(null);
      return ExpressionField(
        name: getNameFromSpan(right),
        type: context.typeOf(exp.left).type?.type ?? BasicType.any,
      );
    }
    return null;
  }

  ExpressionField? _getCaseExpression(CaseExpression field) {
    return null;
  }

  ExpressionField? _getSetComponentExpression(SingleColumnSetComponent field) {
    if (isExpressionValid(field.expression)) {
      final exp = field.expression;
      field.expression = NumberedVariable(null);
      return ExpressionField(
        name: getNameFromSpan(exp),
        type: context.typeOf(exp).type?.type ?? BasicType.any,
      );
    }

    return null;
  }
}

class ExpressionField {
  final String? name;
  final BasicType type;
  final bool isList;

  ExpressionField({
    required this.name,
    required this.type,
    this.isList = false,
  });

  @override
  String toString() {
    return '({name: $name, type: $type, isList: $isList})';
  }
}

class ArgsParameters {
  final List<builder.Parameter> positional;
  final List<builder.Parameter> named;
  final List<String> args;

  ArgsParameters()
      : args = [],
        positional = [],
        named = [];

  String get dbArgs => args.join(', ');
}
