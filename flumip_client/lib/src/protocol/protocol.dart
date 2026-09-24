/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:flumip_client/src/protocol/flumip_user_dto.dart' as _i15z9m0g;
import 'package:flumip_client/src/protocol/genome.dart' as _ixuye8o9;
import 'package:flumip_client/src/protocol/project.dart' as _iqi8mkqf;
import 'package:flumip_client/src/protocol/project_file_dto.dart' as _i5l1g0eo;
import 'package:flumip_client/src/protocol/search_hit_dto.dart' as _i8y6t52d;
import 'package:flumip_client/src/protocol/snp.dart' as _iumnx4id;
import 'package:flumip_client/src/protocol/snp_usage_dto.dart' as _idqeum9a;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'auth_admin_status_dto.dart' as _ilu62sh8;
import 'auth_config_dto.dart' as _i3pxz8st;
import 'auth_user_dto.dart' as _i9fqmmja;
import 'custom_snp_request_dto.dart' as _i50r13ns;
import 'exceptions/argument_exception.dart' as _ix5u8j9t;
import 'exceptions/flumip_file_not_found_exception.dart' as _iua77lfj;
import 'exceptions/GenomeExceptions/bed_creation_exception.dart' as _il9ya82w;
import 'exceptions/project_access_denied_exception.dart' as _iq9wx7jy;
import 'flumip_user_dto.dart' as _im3lr0ct;
import 'genome.dart' as _ik3s3pjn;
import 'project.dart' as _ifiazq2p;
import 'project_file_dto.dart' as _ip1wvjxo;
import 'project_options.dart' as _i4kq7s26;
import 'score_method.dart' as _iootg8bv;
import 'search_hit_dto.dart' as _iy8r37ur;
import 'search_hit_kind.dart' as _ia4xis23;
import 'settings.dart' as _ibmr8d9c;
import 'snp.dart' as _ip0fcn2o;
import 'snp_import_status.dart' as _iq9n7xnd;
import 'snp_usage_dto.dart' as _i8stnodc;
import 'user_settings_dto.dart' as _igo562ik;
export 'auth_admin_status_dto.dart';
export 'auth_config_dto.dart';
export 'auth_user_dto.dart';
export 'custom_snp_request_dto.dart';
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
export 'search_hit_dto.dart';
export 'search_hit_kind.dart';
export 'settings.dart';
export 'snp.dart';
export 'snp_import_status.dart';
export 'snp_usage_dto.dart';
export 'user_settings_dto.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(dynamic data, [Type? t]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ilu62sh8.AuthAdminStatusDto) {
      return _ilu62sh8.AuthAdminStatusDto.fromJson(data) as T;
    }
    if (t == _i3pxz8st.AuthConfigDto) {
      return _i3pxz8st.AuthConfigDto.fromJson(data) as T;
    }
    if (t == _i9fqmmja.AuthUserDto) {
      return _i9fqmmja.AuthUserDto.fromJson(data) as T;
    }
    if (t == _i50r13ns.CustomSnpRequestDto) {
      return _i50r13ns.CustomSnpRequestDto.fromJson(data) as T;
    }
    if (t == _il9ya82w.BedCreationException) {
      return _il9ya82w.BedCreationException.fromJson(data) as T;
    }
    if (t == _ix5u8j9t.ArgumentException) {
      return _ix5u8j9t.ArgumentException.fromJson(data) as T;
    }
    if (t == _iua77lfj.FlumipFileNotFoundException) {
      return _iua77lfj.FlumipFileNotFoundException.fromJson(data) as T;
    }
    if (t == _iq9wx7jy.ProjectAccessDeniedException) {
      return _iq9wx7jy.ProjectAccessDeniedException.fromJson(data) as T;
    }
    if (t == _im3lr0ct.FlumipUserDto) {
      return _im3lr0ct.FlumipUserDto.fromJson(data) as T;
    }
    if (t == _ik3s3pjn.Genome) {
      return _ik3s3pjn.Genome.fromJson(data) as T;
    }
    if (t == _ifiazq2p.Project) {
      return _ifiazq2p.Project.fromJson(data) as T;
    }
    if (t == _ip1wvjxo.ProjectFileDto) {
      return _ip1wvjxo.ProjectFileDto.fromJson(data) as T;
    }
    if (t == _i4kq7s26.ProjectOptions) {
      return _i4kq7s26.ProjectOptions.fromJson(data) as T;
    }
    if (t == _iootg8bv.ScoreMethod) {
      return _iootg8bv.ScoreMethod.fromJson(data) as T;
    }
    if (t == _iy8r37ur.SearchHitDto) {
      return _iy8r37ur.SearchHitDto.fromJson(data) as T;
    }
    if (t == _ia4xis23.SearchHitKind) {
      return _ia4xis23.SearchHitKind.fromJson(data) as T;
    }
    if (t == _ibmr8d9c.Settings) {
      return _ibmr8d9c.Settings.fromJson(data) as T;
    }
    if (t == _ip0fcn2o.Snp) {
      return _ip0fcn2o.Snp.fromJson(data) as T;
    }
    if (t == _iq9n7xnd.SnpImportStatus) {
      return _iq9n7xnd.SnpImportStatus.fromJson(data) as T;
    }
    if (t == _i8stnodc.SnpUsageDto) {
      return _i8stnodc.SnpUsageDto.fromJson(data) as T;
    }
    if (t == _igo562ik.UserSettingsDto) {
      return _igo562ik.UserSettingsDto.fromJson(data) as T;
    }
    if (t == _isc.getType<_ilu62sh8.AuthAdminStatusDto?>()) {
      return (data != null ? _ilu62sh8.AuthAdminStatusDto.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i3pxz8st.AuthConfigDto?>()) {
      return (data != null ? _i3pxz8st.AuthConfigDto.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i9fqmmja.AuthUserDto?>()) {
      return (data != null ? _i9fqmmja.AuthUserDto.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i50r13ns.CustomSnpRequestDto?>()) {
      return (data != null
              ? _i50r13ns.CustomSnpRequestDto.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_il9ya82w.BedCreationException?>()) {
      return (data != null
              ? _il9ya82w.BedCreationException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ix5u8j9t.ArgumentException?>()) {
      return (data != null ? _ix5u8j9t.ArgumentException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iua77lfj.FlumipFileNotFoundException?>()) {
      return (data != null
              ? _iua77lfj.FlumipFileNotFoundException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_iq9wx7jy.ProjectAccessDeniedException?>()) {
      return (data != null
              ? _iq9wx7jy.ProjectAccessDeniedException.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_im3lr0ct.FlumipUserDto?>()) {
      return (data != null ? _im3lr0ct.FlumipUserDto.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ik3s3pjn.Genome?>()) {
      return (data != null ? _ik3s3pjn.Genome.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ifiazq2p.Project?>()) {
      return (data != null ? _ifiazq2p.Project.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ip1wvjxo.ProjectFileDto?>()) {
      return (data != null ? _ip1wvjxo.ProjectFileDto.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i4kq7s26.ProjectOptions?>()) {
      return (data != null ? _i4kq7s26.ProjectOptions.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iootg8bv.ScoreMethod?>()) {
      return (data != null ? _iootg8bv.ScoreMethod.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iy8r37ur.SearchHitDto?>()) {
      return (data != null ? _iy8r37ur.SearchHitDto.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ia4xis23.SearchHitKind?>()) {
      return (data != null ? _ia4xis23.SearchHitKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ibmr8d9c.Settings?>()) {
      return (data != null ? _ibmr8d9c.Settings.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ip0fcn2o.Snp?>()) {
      return (data != null ? _ip0fcn2o.Snp.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iq9n7xnd.SnpImportStatus?>()) {
      return (data != null ? _iq9n7xnd.SnpImportStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i8stnodc.SnpUsageDto?>()) {
      return (data != null ? _i8stnodc.SnpUsageDto.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_igo562ik.UserSettingsDto?>()) {
      return (data != null ? _igo562ik.UserSettingsDto.fromJson(data) : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_i5l1g0eo.ProjectFileDto>) {
      return (data as List)
              .map((e) => deserialize<_i5l1g0eo.ProjectFileDto>(e))
              .toList()
          as T;
    }
    if (t == List<_ixuye8o9.Genome>) {
      return (data as List)
              .map((e) => deserialize<_ixuye8o9.Genome>(e))
              .toList()
          as T;
    }
    if (t == List<_iumnx4id.Snp>) {
      return (data as List).map((e) => deserialize<_iumnx4id.Snp>(e)).toList()
          as T;
    }
    if (t == List<_iqi8mkqf.Project>) {
      return (data as List)
              .map((e) => deserialize<_iqi8mkqf.Project>(e))
              .toList()
          as T;
    }
    if (t == List<_i15z9m0g.FlumipUserDto>) {
      return (data as List)
              .map((e) => deserialize<_i15z9m0g.FlumipUserDto>(e))
              .toList()
          as T;
    }
    if (t == List<_i8y6t52d.SearchHitDto>) {
      return (data as List)
              .map((e) => deserialize<_i8y6t52d.SearchHitDto>(e))
              .toList()
          as T;
    }
    if (t == List<_idqeum9a.SnpUsageDto>) {
      return (data as List)
              .map((e) => deserialize<_idqeum9a.SnpUsageDto>(e))
              .toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ilu62sh8.AuthAdminStatusDto => 'AuthAdminStatusDto',
      _i3pxz8st.AuthConfigDto => 'AuthConfigDto',
      _i9fqmmja.AuthUserDto => 'AuthUserDto',
      _i50r13ns.CustomSnpRequestDto => 'CustomSnpRequestDto',
      _il9ya82w.BedCreationException => 'BedCreationException',
      _ix5u8j9t.ArgumentException => 'ArgumentException',
      _iua77lfj.FlumipFileNotFoundException => 'FlumipFileNotFoundException',
      _iq9wx7jy.ProjectAccessDeniedException => 'ProjectAccessDeniedException',
      _im3lr0ct.FlumipUserDto => 'FlumipUserDto',
      _ik3s3pjn.Genome => 'Genome',
      _ifiazq2p.Project => 'Project',
      _ip1wvjxo.ProjectFileDto => 'ProjectFileDto',
      _i4kq7s26.ProjectOptions => 'ProjectOptions',
      _iootg8bv.ScoreMethod => 'ScoreMethod',
      _iy8r37ur.SearchHitDto => 'SearchHitDto',
      _ia4xis23.SearchHitKind => 'SearchHitKind',
      _ibmr8d9c.Settings => 'Settings',
      _ip0fcn2o.Snp => 'Snp',
      _iq9n7xnd.SnpImportStatus => 'SnpImportStatus',
      _i8stnodc.SnpUsageDto => 'SnpUsageDto',
      _igo562ik.UserSettingsDto => 'UserSettingsDto',
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
      case _ilu62sh8.AuthAdminStatusDto():
        return 'AuthAdminStatusDto';
      case _i3pxz8st.AuthConfigDto():
        return 'AuthConfigDto';
      case _i9fqmmja.AuthUserDto():
        return 'AuthUserDto';
      case _i50r13ns.CustomSnpRequestDto():
        return 'CustomSnpRequestDto';
      case _il9ya82w.BedCreationException():
        return 'BedCreationException';
      case _ix5u8j9t.ArgumentException():
        return 'ArgumentException';
      case _iua77lfj.FlumipFileNotFoundException():
        return 'FlumipFileNotFoundException';
      case _iq9wx7jy.ProjectAccessDeniedException():
        return 'ProjectAccessDeniedException';
      case _im3lr0ct.FlumipUserDto():
        return 'FlumipUserDto';
      case _ik3s3pjn.Genome():
        return 'Genome';
      case _ifiazq2p.Project():
        return 'Project';
      case _ip1wvjxo.ProjectFileDto():
        return 'ProjectFileDto';
      case _i4kq7s26.ProjectOptions():
        return 'ProjectOptions';
      case _iootg8bv.ScoreMethod():
        return 'ScoreMethod';
      case _iy8r37ur.SearchHitDto():
        return 'SearchHitDto';
      case _ia4xis23.SearchHitKind():
        return 'SearchHitKind';
      case _ibmr8d9c.Settings():
        return 'Settings';
      case _ip0fcn2o.Snp():
        return 'Snp';
      case _iq9n7xnd.SnpImportStatus():
        return 'SnpImportStatus';
      case _i8stnodc.SnpUsageDto():
        return 'SnpUsageDto';
      case _igo562ik.UserSettingsDto():
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
      return deserialize<_ilu62sh8.AuthAdminStatusDto>(data['data']);
    }
    if (dataClassName == 'AuthConfigDto') {
      return deserialize<_i3pxz8st.AuthConfigDto>(data['data']);
    }
    if (dataClassName == 'AuthUserDto') {
      return deserialize<_i9fqmmja.AuthUserDto>(data['data']);
    }
    if (dataClassName == 'CustomSnpRequestDto') {
      return deserialize<_i50r13ns.CustomSnpRequestDto>(data['data']);
    }
    if (dataClassName == 'BedCreationException') {
      return deserialize<_il9ya82w.BedCreationException>(data['data']);
    }
    if (dataClassName == 'ArgumentException') {
      return deserialize<_ix5u8j9t.ArgumentException>(data['data']);
    }
    if (dataClassName == 'FlumipFileNotFoundException') {
      return deserialize<_iua77lfj.FlumipFileNotFoundException>(data['data']);
    }
    if (dataClassName == 'ProjectAccessDeniedException') {
      return deserialize<_iq9wx7jy.ProjectAccessDeniedException>(data['data']);
    }
    if (dataClassName == 'FlumipUserDto') {
      return deserialize<_im3lr0ct.FlumipUserDto>(data['data']);
    }
    if (dataClassName == 'Genome') {
      return deserialize<_ik3s3pjn.Genome>(data['data']);
    }
    if (dataClassName == 'Project') {
      return deserialize<_ifiazq2p.Project>(data['data']);
    }
    if (dataClassName == 'ProjectFileDto') {
      return deserialize<_ip1wvjxo.ProjectFileDto>(data['data']);
    }
    if (dataClassName == 'ProjectOptions') {
      return deserialize<_i4kq7s26.ProjectOptions>(data['data']);
    }
    if (dataClassName == 'ScoreMethod') {
      return deserialize<_iootg8bv.ScoreMethod>(data['data']);
    }
    if (dataClassName == 'SearchHitDto') {
      return deserialize<_iy8r37ur.SearchHitDto>(data['data']);
    }
    if (dataClassName == 'SearchHitKind') {
      return deserialize<_ia4xis23.SearchHitKind>(data['data']);
    }
    if (dataClassName == 'Settings') {
      return deserialize<_ibmr8d9c.Settings>(data['data']);
    }
    if (dataClassName == 'Snp') {
      return deserialize<_ip0fcn2o.Snp>(data['data']);
    }
    if (dataClassName == 'SnpImportStatus') {
      return deserialize<_iq9n7xnd.SnpImportStatus>(data['data']);
    }
    if (dataClassName == 'SnpUsageDto') {
      return deserialize<_i8stnodc.SnpUsageDto>(data['data']);
    }
    if (dataClassName == 'UserSettingsDto') {
      return deserialize<_igo562ik.UserSettingsDto>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  @override
  String getModuleName() => 'flumip';

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
