/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'exceptions.dart' as _i2;
import 'exceptions/GenomeExceptions/bed_creation_exception.dart' as _i3;
import 'exceptions/argument_exception.dart' as _i4;
import 'exceptions/flumip_file_not_found_exception.dart' as _i5;
import 'genome.dart' as _i6;
import 'project.dart' as _i7;
import 'project_options.dart' as _i8;
import 'score_method.dart' as _i9;
import 'settings.dart' as _i10;
import 'snp.dart' as _i11;
import 'package:flumip_client/src/protocol/genome.dart' as _i12;
import 'package:flumip_client/src/protocol/snp.dart' as _i13;
import 'package:flumip_client/src/protocol/project.dart' as _i14;
export 'exceptions.dart';
export 'exceptions/GenomeExceptions/bed_creation_exception.dart';
export 'exceptions/argument_exception.dart';
export 'exceptions/flumip_file_not_found_exception.dart';
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

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.GeneExtractionException) {
      return _i2.GeneExtractionException.fromJson(data) as T;
    }
    if (t == _i3.BedCreationException) {
      return _i3.BedCreationException.fromJson(data) as T;
    }
    if (t == _i4.ArgumentException) {
      return _i4.ArgumentException.fromJson(data) as T;
    }
    if (t == _i5.FlumipFileNotFoundException) {
      return _i5.FlumipFileNotFoundException.fromJson(data) as T;
    }
    if (t == _i6.Genome) {
      return _i6.Genome.fromJson(data) as T;
    }
    if (t == _i7.Project) {
      return _i7.Project.fromJson(data) as T;
    }
    if (t == _i8.ProjectOptions) {
      return _i8.ProjectOptions.fromJson(data) as T;
    }
    if (t == _i9.ScoreMethod) {
      return _i9.ScoreMethod.fromJson(data) as T;
    }
    if (t == _i10.Settings) {
      return _i10.Settings.fromJson(data) as T;
    }
    if (t == _i11.Snp) {
      return _i11.Snp.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.GeneExtractionException?>()) {
      return (data != null ? _i2.GeneExtractionException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i3.BedCreationException?>()) {
      return (data != null ? _i3.BedCreationException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i4.ArgumentException?>()) {
      return (data != null ? _i4.ArgumentException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.FlumipFileNotFoundException?>()) {
      return (data != null
              ? _i5.FlumipFileNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i6.Genome?>()) {
      return (data != null ? _i6.Genome.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Project?>()) {
      return (data != null ? _i7.Project.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.ProjectOptions?>()) {
      return (data != null ? _i8.ProjectOptions.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.ScoreMethod?>()) {
      return (data != null ? _i9.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Settings?>()) {
      return (data != null ? _i10.Settings.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Snp?>()) {
      return (data != null ? _i11.Snp.fromJson(data) : null) as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == _i1.getType<List<int>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<int>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i12.Genome>) {
      return (data as List).map((e) => deserialize<_i12.Genome>(e)).toList()
          as T;
    }
    if (t == List<_i13.Snp>) {
      return (data as List).map((e) => deserialize<_i13.Snp>(e)).toList() as T;
    }
    if (t == List<_i14.Project>) {
      return (data as List).map((e) => deserialize<_i14.Project>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.GeneExtractionException => 'GeneExtractionException',
      _i3.BedCreationException => 'BedCreationException',
      _i4.ArgumentException => 'ArgumentException',
      _i5.FlumipFileNotFoundException => 'FlumipFileNotFoundException',
      _i6.Genome => 'Genome',
      _i7.Project => 'Project',
      _i8.ProjectOptions => 'ProjectOptions',
      _i9.ScoreMethod => 'ScoreMethod',
      _i10.Settings => 'Settings',
      _i11.Snp => 'Snp',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('flumip.', '');
    }

    switch (data) {
      case _i2.GeneExtractionException():
        return 'GeneExtractionException';
      case _i3.BedCreationException():
        return 'BedCreationException';
      case _i4.ArgumentException():
        return 'ArgumentException';
      case _i5.FlumipFileNotFoundException():
        return 'FlumipFileNotFoundException';
      case _i6.Genome():
        return 'Genome';
      case _i7.Project():
        return 'Project';
      case _i8.ProjectOptions():
        return 'ProjectOptions';
      case _i9.ScoreMethod():
        return 'ScoreMethod';
      case _i10.Settings():
        return 'Settings';
      case _i11.Snp():
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
    if (dataClassName == 'BedCreationException') {
      return deserialize<_i3.BedCreationException>(data['data']);
    }
    if (dataClassName == 'ArgumentException') {
      return deserialize<_i4.ArgumentException>(data['data']);
    }
    if (dataClassName == 'FlumipFileNotFoundException') {
      return deserialize<_i5.FlumipFileNotFoundException>(data['data']);
    }
    if (dataClassName == 'Genome') {
      return deserialize<_i6.Genome>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_i7.Project>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i8.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_i9.ScoreMethod>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_i10.Settings>(data['data']);
    }
    if (dataClassName == 'Snp') {
      return deserialize<_i11.Snp>(data['data']);
    }
    return super.deserializeByClassName(data);
  }
}
