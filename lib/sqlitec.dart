library sqlitec;

import 'package:build/build.dart';
import 'src/builder.dart';

Builder sqlToDartBuilder(BuilderOptions options) => SqliteBuilder(options);

Builder sqlToDartGenerator(BuilderOptions options) => SqliteGenerator();