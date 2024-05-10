import 'package:collection/collection.dart';

enum ReturnMode {
  one(':one'),
  many(':many'),
  exec(':exec');

  const ReturnMode(this.value);

  final String value;

  factory ReturnMode.fromString(String value) {
    return values.firstWhereOrNull((e) => e.value == value) ?? ReturnMode.exec;
  }
}

class CommentAnalysis {

  static final rawRegex = r'--\s*name:\s+(?<name>\w+)\s+(?<mode>:one|:many|:exec)\n+\s*(update|insert|select|delete)';

  static final _regexComment = RegExp(rawRegex);

  static bool isACommentValid(String comment) {
    return _regexComment.hasMatch(comment.trim());
  }
  
  static AnalyzedComment? getCommentAnalize(String comment) {
    if (!isACommentValid(comment)) return null;

    final match = _regexComment.firstMatch(comment);
    if (match == null) return null;

    return AnalyzedComment(
      name: match.namedGroup('name') ?? '',
      mode: ReturnMode.fromString(match.namedGroup('mode') ?? '')
    );
  }
}

class AnalyzedComment {
  final String name;
  final ReturnMode mode;

  AnalyzedComment({required this.name, required this.mode});


  @override
  String toString() {
    return '({$name, $mode})';
  }
}