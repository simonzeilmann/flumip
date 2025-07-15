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
import 'exceptions.dart' as _i2;
import 'genome.dart' as _i3;
import 'project.dart' as _i4;
import 'project_options.dart' as _i5;
import 'score_method.dart' as _i6;
import 'settings.dart' as _i7;
import 'snp.dart' as _i8;
import 'package:flumip_client/src/protocol/genome.dart' as _i9;
import 'package:flumip_client/src/protocol/snp.dart' as _i10;
import 'package:flumip_client/src/protocol/project.dart' as _i11;
export 'exceptions.dart';
export 'genome.dart';
export 'project.dart';
export 'project_options.dart';
export 'score_method.dart';
export 'settings.dart';
export 'snp.dart';
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
    if (t == _i2.GeneExtractionException) {
      return _i2.GeneExtractionException.fromJson(data) as T;
    }
    if (t == _i3.Genome) {
      return _i3.Genome.fromJson(data) as T;
    }
    if (t == _i4.Project) {
      return _i4.Project.fromJson(data) as T;
    }
    if (t == _i5.ProjectOptions) {
      return _i5.ProjectOptions.fromJson(data) as T;
    }
    if (t == _i6.ScoreMethod) {
      return _i6.ScoreMethod.fromJson(data) as T;
    }
    if (t == _i7.Settings) {
      return _i7.Settings.fromJson(data) as T;
    }
    if (t == _i8.Snp) {
      return _i8.Snp.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.GeneExtractionException?>()) {
      return (data != null ? _i2.GeneExtractionException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.Genome?>()) {
      return (data != null ? _i3.Genome.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Project?>()) {
      return (data != null ? _i4.Project.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ProjectOptions?>()) {
      return (data != null ? _i5.ProjectOptions.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ScoreMethod?>()) {
      return (data != null ? _i6.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Settings?>()) {
      return (data != null ? _i7.Settings.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Snp?>()) {
      return (data != null ? _i8.Snp.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
          ? (data as List).map((e) => deserialize<int>(e)).toList()
          : null) as T;
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
    if (t == List<_i9.Genome>) {
      return (data as List).map((e) => deserialize<_i9.Genome>(e)).toList()
          as T;
    }
    if (t == List<_i10.Snp>) {
      return (data as List).map((e) => deserialize<_i10.Snp>(e)).toList() as T;
    }
    if (t == List<_i11.Project>) {
      return (data as List).map((e) => deserialize<_i11.Project>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;
    if (data is _i2.GeneExtractionException) {
      return 'GeneExtractionException';
    }
    if (data is _i3.Genome) {
      return 'Genome';
    }
    if (data is _i4.Project) {
      return 'Project';
    }
    if (data is _i5.ProjectOptions) {
      return 'ProjectOptions';
    }
    if (data is _i6.ScoreMethod) {
      return 'ScoreMethod';
    }
    if (data is _i7.Settings) {
      return 'Settings';
    }
    if (data is _i8.Snp) {
      return 'Snp';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'GeneExtractionException') {
      return deserialize<_i2.GeneExtractionException>(data['data']);
    }
    if (dataClassName == 'Genome') {
      return deserialize<_i3.Genome>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_i4.Project>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i5.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_i6.ScoreMethod>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_i7.Settings>(data['data']);
    }
    if (dataClassName == 'Snp') {
      return deserialize<_i8.Snp>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
