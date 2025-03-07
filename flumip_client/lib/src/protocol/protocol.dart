/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'project.dart' as _i2;
import 'project_options.dart' as _i3;
import 'score_method.dart' as _i4;
import 'package:flumip_client/src/protocol/project.dart' as _i5;
export 'project.dart';
export 'project_options.dart';
export 'score_method.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;
    if (t == _i2.Project) {
      return _i2.Project.fromJson(data) as T;
    }
    if (t == _i3.ProjectOptions) {
      return _i3.ProjectOptions.fromJson(data) as T;
    }
    if (t == _i4.ScoreMethod) {
      return _i4.ScoreMethod.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Project?>()) {
      return (data != null ? _i2.Project.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.ProjectOptions?>()) {
      return (data != null ? _i3.ProjectOptions.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ScoreMethod?>()) {
      return (data != null ? _i4.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<String>(e)).toList()
          : null) as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<String>(e)).toList()
          : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i5.Project>) {
      return (data as List).map((e) => deserialize<_i5.Project>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.Project) {
      return 'Project';
    }
    if (data is _i3.ProjectOptions) {
      return 'ProjectOptions';
    }
    if (data is _i4.ScoreMethod) {
      return 'ScoreMethod';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Project') {
      return deserialize<_i2.Project>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i3.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_i4.ScoreMethod>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
