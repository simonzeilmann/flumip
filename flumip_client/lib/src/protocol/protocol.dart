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
import 'auth_admin_status_dto.dart' as _i2;
import 'auth_config_dto.dart' as _i3;
import 'auth_user_dto.dart' as _i4;
import 'custom_snp_request_dto.dart' as _i5;
import 'exceptions.dart' as _i6;
import 'exceptions/GenomeExceptions/bed_creation_exception.dart' as _i7;
import 'exceptions/argument_exception.dart' as _i8;
import 'exceptions/flumip_file_not_found_exception.dart' as _i9;
import 'exceptions/project_access_denied_exception.dart' as _i10;
import 'flumip_user_dto.dart' as _i11;
import 'genome.dart' as _i12;
import 'project.dart' as _i13;
import 'project_file_dto.dart' as _i14;
import 'project_options.dart' as _i15;
import 'score_method.dart' as _i16;
import 'settings.dart' as _i17;
import 'snp.dart' as _i18;
import 'snp_import_status.dart' as _i19;
import 'snp_usage_dto.dart' as _i20;
import 'user_settings_dto.dart' as _i21;
import 'package:flumip_client/src/protocol/project_file_dto.dart' as _i22;
import 'package:flumip_client/src/protocol/genome.dart' as _i23;
import 'package:flumip_client/src/protocol/snp.dart' as _i24;
import 'package:flumip_client/src/protocol/project.dart' as _i25;
import 'package:flumip_client/src/protocol/flumip_user_dto.dart' as _i26;
import 'package:flumip_client/src/protocol/snp_usage_dto.dart' as _i27;
export 'auth_admin_status_dto.dart';
export 'auth_config_dto.dart';
export 'auth_user_dto.dart';
export 'custom_snp_request_dto.dart';
export 'exceptions.dart';
export 'exceptions/GenomeExceptions/bed_creation_exception.dart';
export 'exceptions/argument_exception.dart';
export 'exceptions/flumip_file_not_found_exception.dart';
export 'exceptions/project_access_denied_exception.dart';
export 'flumip_user_dto.dart';
export 'genome.dart';
export 'project.dart';
export 'project_file_dto.dart';
export 'project_options.dart';
export 'score_method.dart';
export 'settings.dart';
export 'snp.dart';
export 'snp_import_status.dart';
export 'snp_usage_dto.dart';
export 'user_settings_dto.dart';
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

    if (t == _i2.AuthAdminStatusDto) {
      return _i2.AuthAdminStatusDto.fromJson(data) as T;
    }
    if (t == _i3.AuthConfigDto) {
      return _i3.AuthConfigDto.fromJson(data) as T;
    }
    if (t == _i4.AuthUserDto) {
      return _i4.AuthUserDto.fromJson(data) as T;
    }
    if (t == _i5.CustomSnpRequestDto) {
      return _i5.CustomSnpRequestDto.fromJson(data) as T;
    }
    if (t == _i6.GeneExtractionException) {
      return _i6.GeneExtractionException.fromJson(data) as T;
    }
    if (t == _i7.BedCreationException) {
      return _i7.BedCreationException.fromJson(data) as T;
    }
    if (t == _i8.ArgumentException) {
      return _i8.ArgumentException.fromJson(data) as T;
    }
    if (t == _i9.FlumipFileNotFoundException) {
      return _i9.FlumipFileNotFoundException.fromJson(data) as T;
    }
    if (t == _i10.ProjectAccessDeniedException) {
      return _i10.ProjectAccessDeniedException.fromJson(data) as T;
    }
    if (t == _i11.FlumipUserDto) {
      return _i11.FlumipUserDto.fromJson(data) as T;
    }
    if (t == _i12.Genome) {
      return _i12.Genome.fromJson(data) as T;
    }
    if (t == _i13.Project) {
      return _i13.Project.fromJson(data) as T;
    }
    if (t == _i14.ProjectFileDto) {
      return _i14.ProjectFileDto.fromJson(data) as T;
    }
    if (t == _i15.ProjectOptions) {
      return _i15.ProjectOptions.fromJson(data) as T;
    }
    if (t == _i16.ScoreMethod) {
      return _i16.ScoreMethod.fromJson(data) as T;
    }
    if (t == _i17.Settings) {
      return _i17.Settings.fromJson(data) as T;
    }
    if (t == _i18.Snp) {
      return _i18.Snp.fromJson(data) as T;
    }
    if (t == _i19.SnpImportStatus) {
      return _i19.SnpImportStatus.fromJson(data) as T;
    }
    if (t == _i20.SnpUsageDto) {
      return _i20.SnpUsageDto.fromJson(data) as T;
    }
    if (t == _i21.UserSettingsDto) {
      return _i21.UserSettingsDto.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AuthAdminStatusDto?>()) {
      return (data != null ? _i2.AuthAdminStatusDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AuthConfigDto?>()) {
      return (data != null ? _i3.AuthConfigDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AuthUserDto?>()) {
      return (data != null ? _i4.AuthUserDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.CustomSnpRequestDto?>()) {
      return (data != null ? _i5.CustomSnpRequestDto.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.GeneExtractionException?>()) {
      return (data != null ? _i6.GeneExtractionException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.BedCreationException?>()) {
      return (data != null ? _i7.BedCreationException.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ArgumentException?>()) {
      return (data != null ? _i8.ArgumentException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.FlumipFileNotFoundException?>()) {
      return (data != null
              ? _i9.FlumipFileNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i10.ProjectAccessDeniedException?>()) {
      return (data != null
              ? _i10.ProjectAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _i1.getType<_i11.FlumipUserDto?>()) {
      return (data != null ? _i11.FlumipUserDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Genome?>()) {
      return (data != null ? _i12.Genome.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Project?>()) {
      return (data != null ? _i13.Project.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ProjectFileDto?>()) {
      return (data != null ? _i14.ProjectFileDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.ProjectOptions?>()) {
      return (data != null ? _i15.ProjectOptions.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.ScoreMethod?>()) {
      return (data != null ? _i16.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.Settings?>()) {
      return (data != null ? _i17.Settings.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.Snp?>()) {
      return (data != null ? _i18.Snp.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.SnpImportStatus?>()) {
      return (data != null ? _i19.SnpImportStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.SnpUsageDto?>()) {
      return (data != null ? _i20.SnpUsageDto.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.UserSettingsDto?>()) {
      return (data != null ? _i21.UserSettingsDto.fromJson(data) : null) as T;
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
    if (t == List<_i22.ProjectFileDto>) {
      return (data as List)
              .map((e) => deserialize<_i22.ProjectFileDto>(e))
              .toList()
          as T;
    }
    if (t == List<_i23.Genome>) {
      return (data as List).map((e) => deserialize<_i23.Genome>(e)).toList()
          as T;
    }
    if (t == List<_i24.Snp>) {
      return (data as List).map((e) => deserialize<_i24.Snp>(e)).toList() as T;
    }
    if (t == List<_i25.Project>) {
      return (data as List).map((e) => deserialize<_i25.Project>(e)).toList()
          as T;
    }
    if (t == List<_i26.FlumipUserDto>) {
      return (data as List)
              .map((e) => deserialize<_i26.FlumipUserDto>(e))
              .toList()
          as T;
    }
    if (t == List<_i27.SnpUsageDto>) {
      return (data as List)
              .map((e) => deserialize<_i27.SnpUsageDto>(e))
              .toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AuthAdminStatusDto => 'AuthAdminStatusDto',
      _i3.AuthConfigDto => 'AuthConfigDto',
      _i4.AuthUserDto => 'AuthUserDto',
      _i5.CustomSnpRequestDto => 'CustomSnpRequestDto',
      _i6.GeneExtractionException => 'GeneExtractionException',
      _i7.BedCreationException => 'BedCreationException',
      _i8.ArgumentException => 'ArgumentException',
      _i9.FlumipFileNotFoundException => 'FlumipFileNotFoundException',
      _i10.ProjectAccessDeniedException => 'ProjectAccessDeniedException',
      _i11.FlumipUserDto => 'FlumipUserDto',
      _i12.Genome => 'Genome',
      _i13.Project => 'Project',
      _i14.ProjectFileDto => 'ProjectFileDto',
      _i15.ProjectOptions => 'ProjectOptions',
      _i16.ScoreMethod => 'ScoreMethod',
      _i17.Settings => 'Settings',
      _i18.Snp => 'Snp',
      _i19.SnpImportStatus => 'SnpImportStatus',
      _i20.SnpUsageDto => 'SnpUsageDto',
      _i21.UserSettingsDto => 'UserSettingsDto',
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
      case _i2.AuthAdminStatusDto():
        return 'AuthAdminStatusDto';
      case _i3.AuthConfigDto():
        return 'AuthConfigDto';
      case _i4.AuthUserDto():
        return 'AuthUserDto';
      case _i5.CustomSnpRequestDto():
        return 'CustomSnpRequestDto';
      case _i6.GeneExtractionException():
        return 'GeneExtractionException';
      case _i7.BedCreationException():
        return 'BedCreationException';
      case _i8.ArgumentException():
        return 'ArgumentException';
      case _i9.FlumipFileNotFoundException():
        return 'FlumipFileNotFoundException';
      case _i10.ProjectAccessDeniedException():
        return 'ProjectAccessDeniedException';
      case _i11.FlumipUserDto():
        return 'FlumipUserDto';
      case _i12.Genome():
        return 'Genome';
      case _i13.Project():
        return 'Project';
      case _i14.ProjectFileDto():
        return 'ProjectFileDto';
      case _i15.ProjectOptions():
        return 'ProjectOptions';
      case _i16.ScoreMethod():
        return 'ScoreMethod';
      case _i17.Settings():
        return 'Settings';
      case _i18.Snp():
        return 'Snp';
      case _i19.SnpImportStatus():
        return 'SnpImportStatus';
      case _i20.SnpUsageDto():
        return 'SnpUsageDto';
      case _i21.UserSettingsDto():
        return 'UserSettingsDto';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AuthAdminStatusDto') {
      return deserialize<_i2.AuthAdminStatusDto>(data['data']);
    }
    if (dataClassName == 'AuthConfigDto') {
      return deserialize<_i3.AuthConfigDto>(data['data']);
    }
    if (dataClassName == 'AuthUserDto') {
      return deserialize<_i4.AuthUserDto>(data['data']);
    }
    if (dataClassName == 'CustomSnpRequestDto') {
      return deserialize<_i5.CustomSnpRequestDto>(data['data']);
    }
    if (dataClassName == 'GeneExtractionException') {
      return deserialize<_i6.GeneExtractionException>(data['data']);
    }
    if (dataClassName == 'BedCreationException') {
      return deserialize<_i7.BedCreationException>(data['data']);
    }
    if (dataClassName == 'ArgumentException') {
      return deserialize<_i8.ArgumentException>(data['data']);
    }
    if (dataClassName == 'FlumipFileNotFoundException') {
      return deserialize<_i9.FlumipFileNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProjectAccessDeniedException') {
      return deserialize<_i10.ProjectAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'FlumipUserDto') {
      return deserialize<_i11.FlumipUserDto>(data['data']);
    }
    if (dataClassName == 'Genome') {
      return deserialize<_i12.Genome>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_i13.Project>(data['data']);
    }
    if (dataClassName == 'ProjectFileDto') {
      return deserialize<_i14.ProjectFileDto>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i15.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_i16.ScoreMethod>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_i17.Settings>(data['data']);
    }
    if (dataClassName == 'Snp') {
      return deserialize<_i18.Snp>(data['data']);
    }
    if (dataClassName == 'SnpImportStatus') {
      return deserialize<_i19.SnpImportStatus>(data['data']);
    }
    if (dataClassName == 'SnpUsageDto') {
      return deserialize<_i20.SnpUsageDto>(data['data']);
    }
    if (dataClassName == 'UserSettingsDto') {
      return deserialize<_i21.UserSettingsDto>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
