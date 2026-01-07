import 'package:code_builder/code_builder.dart' as code_builder;
import 'package:sqlitec/src/type_converters/string_to_basic_type.dart';
import 'package:sqlparser/sqlparser.dart';

final class SqlExpressionsArgumentsBuilder {
  final AnalysisContext context;

  const SqlExpressionsArgumentsBuilder(this.context);

  List<SqlExpressionParameter> _getSqlExpressionParameters(
      Iterable<AstNode> nodes) {
    final fields = <SqlExpressionParameter>[];

    for (final descendant in nodes) {
      final field = switch (descendant) {
        BinaryExpression field => [_getBinaryExpression(field)],
        InExpression field => _getInExpression(field),
        BetweenExpression field => [_getBetweenExpression(field)],
        CaseExpression field => [_getCaseExpression(field)],
        SingleColumnSetComponent field => [_getSetComponentExpression(field)],
        Limit field => _getLimitExpression(field),
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
    final fields = _getSqlExpressionParameters(nodes);
    final args = ArgsParameters();

    for (final (i, arg) in fields.indexed) {
      final paramType = code_builder.refer(getDartTypeByBasicType(arg.type));
      final argName = arg.name ?? '\$arg${i + 1}';

      if (arg.name case final paramName?) {
        final parameter = code_builder.Parameter(
          (builder) => builder
            ..name = paramName
            ..named = true
            ..type = paramType
            ..required = true,
        );

        args.named.add(parameter);
      } else {
        final parameter = code_builder.Parameter(
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

  bool _isValidExpression(Expression exp) =>
      (exp is NumberedVariable && exp.span?.text == '?') ||
      exp is NamedVariable;

  String? getNameFromSpan(Expression argExp) {
    if (argExp is NamedVariable) {
      if (argExp.name.startsWith(':')) {
        return argExp.name.substring(1);
      }

      return argExp.name;
    }

    return null;
  }

  List<SqlExpressionParameter>? _getLimitExpression(Limit exp) {
    final offsetExp = exp.offset;
    final countExp = exp.count;

    final isCountExpressionValid = _isValidExpression(countExp);
    final isOffsetExpressionValid =
        offsetExp != null && _isValidExpression(offsetExp);

    final hasValidExpressions =
        isCountExpressionValid || isOffsetExpressionValid;
    if (!hasValidExpressions) {
      return null;
    }

    return [
      if (isCountExpressionValid)
        SqlExpressionParameter(
          name: getNameFromSpan(countExp),
          type: BasicType.int,
        ),
      if (isOffsetExpressionValid)
        SqlExpressionParameter(
          name: getNameFromSpan(offsetExp),
          type: BasicType.int,
        ),
    ];
  }

  List<SqlExpressionParameter?>? _getInExpression(InExpression exp) {
    if (exp.inside case Tuple tuple) {
      return [
        for (final argExp in tuple.expressions)
          if (_isValidExpression(argExp))
            SqlExpressionParameter(
              name: getNameFromSpan(argExp),
              type: context.typeOf(exp.left).type?.type ?? BasicType.any,
            )
      ];
    }

    return null;
  }

  SqlExpressionParameter? _getBetweenExpression(BetweenExpression exp) {
    if (_isValidExpression(exp.upper)) {
      return SqlExpressionParameter(
        name: getNameFromSpan(exp.upper),
        type: context.typeOf(exp.lower).type?.type ?? BasicType.any,
      );
    }
    if (_isValidExpression(exp.lower)) {
      return SqlExpressionParameter(
        name: getNameFromSpan(exp.lower),
        type: context.typeOf(exp.upper).type?.type ?? BasicType.any,
      );
    }
    return null;
  }

  SqlExpressionParameter? _getStringComparisonExpression(
      StringComparisonExpression exp) {
    if (_isValidExpression(exp.left)) {
      return SqlExpressionParameter(
        name: getNameFromSpan(exp.left),
        type: context.typeOf(exp.right).type?.type ?? BasicType.any,
      );
    }
    if (_isValidExpression(exp.right)) {
      final right = exp.right;
      exp.right = NumberedVariable(null);
      return SqlExpressionParameter(
        name: getNameFromSpan(right),
        type: context.typeOf(exp.left).type?.type ?? BasicType.any,
      );
    }
    return null;
  }

  SqlExpressionParameter? _getBinaryExpression(BinaryExpression exp) {
    if (_isValidExpression(exp.left)) {
      return SqlExpressionParameter(
        name: getNameFromSpan(exp.left),
        type: context.typeOf(exp.right).type?.type ?? BasicType.any,
      );
    }
    if (!_isValidExpression(exp.right)) {
      return null;
    }

    final right = exp.right;
    exp.right = NumberedVariable(null);

    return SqlExpressionParameter(
      name: getNameFromSpan(right),
      type: context.typeOf(exp.left).type?.type ?? BasicType.any,
    );
  }

  SqlExpressionParameter? _getCaseExpression(CaseExpression field) {
    return null;
  }

  SqlExpressionParameter? _getSetComponentExpression(
      SingleColumnSetComponent field) {
    if (_isValidExpression(field.expression)) {
      final exp = field.expression;
      field.expression = NumberedVariable(null);

      return SqlExpressionParameter(
        name: getNameFromSpan(exp),
        type: context.typeOf(exp).type?.type ?? BasicType.any,
      );
    }

    return null;
  }
}

final class SqlExpressionParameter {
  final String? name;
  final BasicType type;
  final bool isList;

  SqlExpressionParameter({
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
  final List<code_builder.Parameter> positional;
  final List<code_builder.Parameter> named;
  final List<String> args;

  ArgsParameters()
      : args = [],
        positional = [],
        named = [];

  String get dbArgs => args.join(', ');
}
