import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';

final class SqlExpressionsArgumentsBuilder {
  final AnalysisContext context;

  const SqlExpressionsArgumentsBuilder(this.context);

  List<ExpressionField> getFields(Iterable<AstNode> nodes) {
    final fields = <ExpressionField>[];

    for (final descendant in nodes) {
      final field = switch(descendant) {
        BinaryExpression field => [_getBinaryExpression(field)],
        InExpression field => _getInExpression(field),
        BetweenExpression field => [_getBetweenExpression(field)],
        CaseExpression field => [_getCaseExpression(field)],
        SingleColumnSetComponent field => [_getSetComponentExpression(field)],
        _ => null,
      };

      if (field != null) {
        fields.addAll(field.whereType());
      }
    }
    return fields;
  }

  (String, List<String>) generateFunctionArgs(Iterable<AstNode> nodes) {
    final fields = getFields(nodes);
    final positionalBuffer = <String>[];
    final namedBuffer = <String>[];
    final args = <String>[];
    for (final (i, arg) in fields.indexed) {
      if (arg.name != null) {
        namedBuffer.add('    required ${getDartTypeByBasicType(arg.type)} ${arg.name}, \n');
        args.add(arg.name!);
      } else {
        final argName = '\$arg${i+1}';
        positionalBuffer.add('${getDartTypeByBasicType(arg.type)} $argName');
        args.add(argName);
      }
    }
    var argReturns = positionalBuffer.join(', ');

    if (namedBuffer.isNotEmpty) {
      if (argReturns.isNotEmpty) {
        argReturns += ', ';
      }
      argReturns += '{\n${namedBuffer.join()}  }';
    }
    return (argReturns, args);
  }

  bool isExpressionValid(Expression exp) => (exp is NumberedVariable && exp.span?.text == '?') || exp is ColonNamedVariable;

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