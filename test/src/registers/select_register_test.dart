import 'package:sqlitec/src/dql_analyzer/comment_analyzer.dart';
import 'package:sqlitec/src/dql_analyzer/table_analyzer.dart';
import 'package:sqlitec/src/registers/select_register.dart';
import 'package:sqlparser/sqlparser.dart';
import 'package:test/test.dart';

import '../utils/transform_utils.dart';

const userTable = '''
create table users (
  id int primary key,
  name varchar(255) not null,
  birthday date not null,
  email varchar(255) not null unique,
  bio text,
  role_id int default null
);
''';

const roleTable = '''
create table roles (
  id int primary key,
  title varchar(255) not null,
  is_active boolean not null default 1
);
''';

void main() {
  final engine = SqlEngine()
    ..registerRawTable(userTable)
    ..registerRawTable(roleTable);

  final cmdAnalyzer = CmdAnalyzer();

  group('Ensure all string comparisons are generated parameters correctly', () {
    test('Generate params to like exp', () {
      const methodName = 'methodTestName';
      final register = SelectRegister(
        engine,
        AnalyzedComment(name: 'methodTestName', mode: ReturnMode.one),
        cmdAnalyzer,
      );

      const selectCommand = r"select * from users where name like :name";
      final result = engine.parse(selectCommand).rootNode as SelectStatement;

      final selectMethod = register.register(result);

      expect(selectMethod.name, equals(methodName));

      final params = selectMethod.optionalParameters;

      expect(params, hasLength(1));

      final param = params.first;

      expect(param.name, 'name');
      expect(param.named, true);
      expect(param.required, true);

      expect(param.type!.symbol, 'String');
    });

    test('Generate params to glob exp', () {
      const methodName = 'methodTestName';
      final register = SelectRegister(
        engine,
        AnalyzedComment(name: 'methodTestName', mode: ReturnMode.one),
        cmdAnalyzer,
      );

      const selectCommand = r"select * from users where bio glob :bio";
      final result = engine.parse(selectCommand).rootNode as SelectStatement;

      final selectMethod = register.register(result);

      expect(selectMethod.name, equals(methodName));

      final params = selectMethod.optionalParameters;

      expect(params, hasLength(1));

      final param = params.first;

      expect(param.name, 'bio');
      expect(param.named, true);
      expect(param.required, true);
      expect(param.type?.symbol, 'String');
    });

    test('Generate params to match exp', () {
      const methodName = 'methodTestName';
      final register = SelectRegister(
        engine,
        AnalyzedComment(name: 'methodTestName', mode: ReturnMode.one),
        cmdAnalyzer,
      );

      const selectCommand = r"select * from users where email match ?";
      final result = engine.parse(selectCommand).rootNode as SelectStatement;

      final selectMethod = register.register(result);

      expect(selectMethod.name, equals(methodName));

      final params = selectMethod.requiredParameters;

      expect(params, hasLength(1));

      final param = params.first;

      expect(param.name, r'$arg1');
      expect(param.named, false);
      expect(param.required, false);

      expect(param.type?.symbol, 'String');
    });

    test('Generate params to regexp exp', () {
      const methodName = 'methodTestName';
      final register = SelectRegister(
        engine,
        AnalyzedComment(name: 'methodTestName', mode: ReturnMode.one),
        cmdAnalyzer,
      );

      const selectCommand = r"select * from users where email regexp ?";
      final result = engine.parse(selectCommand).rootNode as SelectStatement;

      final selectMethod = register.register(result);

      expect(selectMethod.name, equals(methodName));

      final params = selectMethod.requiredParameters;

      expect(params, hasLength(1));

      final param = params.first;

      expect(param.name, r'$arg1');
      expect(param.named, false);
      expect(param.required, false);

      expect(param.type?.symbol, 'String');
    });
  });

  group('Ensure "in" expressions are generated parameters correctly', () {
    test('Generate args for each option on in expression', () {
      const methodName = 'methodTestName';
      final register = SelectRegister(
        engine,
        AnalyzedComment(name: 'methodTestName', mode: ReturnMode.one),
        cmdAnalyzer,
      );

      const selectCommand = r"select * from users where name in (?, ?, ?)";
      final result = engine.parse(selectCommand).rootNode as SelectStatement;

      final selectMethod = register.register(result);

      expect(selectMethod.name, equals(methodName));

      final params = selectMethod.requiredParameters;

      expect(params, hasLength(3));

      for (final (index, param) in params.indexed) {
        expect(param.name, '\$arg${index + 1}');
        expect(param.named, false);
        expect(param.required, false);

        expect(param.type?.symbol, 'String');
      }
    });

    test('Generate args for subquery', () {
      const methodName = 'methodTestName';
      final register = SelectRegister(
        engine,
        AnalyzedComment(name: 'methodTestName', mode: ReturnMode.one),
        cmdAnalyzer,
      );

      const selectCommand =
          r"select * from users where role_id in (select title from roles where title = :roleTitle)";
      final result = engine.parse(selectCommand).rootNode as SelectStatement;

      final selectMethod = register.register(result);

      expect(selectMethod.name, equals(methodName));

      final params = selectMethod.optionalParameters;

      expect(params, hasLength(1));

      final param = params.first;
      expect(param.name, 'roleTitle');
      expect(param.named, true);
      expect(param.required, true);

      expect(param.type?.symbol, 'String');
    });
  });
}
