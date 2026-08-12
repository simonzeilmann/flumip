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
import 'package:serverpod/serverpod.dart' as _i1;
import 'package:flumip_server/src/generated/genome.dart' as _i2;
import 'package:flumip_server/src/generated/project.dart' as _i3;
import 'package:flumip_server/src/generated/snp.dart' as _i4;
import 'dart:async' as _i5;
import '../future_calls/check_index_progress_future_call.dart' as _i6;
import '../future_calls/check_mipgen_progress_future_call.dart' as _i7;
import '../future_calls/demo_mode_cleanup_future_call.dart' as _i8;
import '../future_calls/import_snp_future_call.dart' as _i9;

/// Invokes a future call.
typedef _InvokeFutureCall =
    Future<void> Function(String name, _i1.SerializableModel? object);

extension ServerpodFutureCallsGetter on _i1.Serverpod {
  /// Generated future calls.
  FutureCalls get futureCalls => FutureCalls();
}

class FutureCalls extends _i1.FutureCallDispatch<_FutureCallRef> {
  FutureCalls._();

  factory FutureCalls() {
    return _instance;
  }

  static final FutureCalls _instance = FutureCalls._();

  _i1.FutureCallManager? _futureCallManager;

  String? _serverId;

  String get _effectiveServerId {
    if (_serverId == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _serverId!;
  }

  _i1.FutureCallManager get _effectiveFutureCallManager {
    if (_futureCallManager == null) {
      throw StateError('FutureCalls is not initialized.');
    }
    return _futureCallManager!;
  }

  @override
  void initialize(
    _i1.FutureCallManager futureCallManager,
    String serverId,
  ) {
    var registeredFutureCalls = <String, _i1.FutureCall>{
      'CheckIndexProgressRunFutureCall': CheckIndexProgressRunFutureCall(),
      'CheckMipgenProgressRunFutureCall': CheckMipgenProgressRunFutureCall(),
      'DemoModeCleanupRunFutureCall': DemoModeCleanupRunFutureCall(),
      'ImportSnpRunFutureCall': ImportSnpRunFutureCall(),
    };
    _futureCallManager = futureCallManager;
    _serverId = serverId;
    for (final entry in registeredFutureCalls.entries) {
      _futureCallManager?.registerFutureCall(entry.value, entry.key);
    }
  }

  @override
  _FutureCallRef callAtTime(
    DateTime time, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          time,
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  _FutureCallRef callWithDelay(
    Duration delay, {
    String? identifier,
  }) {
    return _FutureCallRef(
      (name, object) {
        return _effectiveFutureCallManager.scheduleFutureCall(
          name,
          object,
          DateTime.now().toUtc().add(delay),
          _effectiveServerId,
          identifier,
        );
      },
    );
  }

  @override
  Future<void> cancel(String identifier) async {
    await _effectiveFutureCallManager.cancelFutureCall(identifier);
  }
}

class _FutureCallRef {
  _FutureCallRef(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  late final checkIndexProgress = _CheckIndexProgressFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final checkMipgenProgress = _CheckMipgenProgressFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final demoModeCleanup = _DemoModeCleanupFutureCallDispatcher(
    _invokeFutureCall,
  );

  late final importSnp = _ImportSnpFutureCallDispatcher(_invokeFutureCall);
}

class _CheckIndexProgressFutureCallDispatcher {
  _CheckIndexProgressFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(_i2.Genome object) {
    return _invokeFutureCall(
      'CheckIndexProgressRunFutureCall',
      object,
    );
  }
}

class _CheckMipgenProgressFutureCallDispatcher {
  _CheckMipgenProgressFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(_i3.Project object) {
    return _invokeFutureCall(
      'CheckMipgenProgressRunFutureCall',
      object,
    );
  }
}

class _DemoModeCleanupFutureCallDispatcher {
  _DemoModeCleanupFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(_i3.Project object) {
    return _invokeFutureCall(
      'DemoModeCleanupRunFutureCall',
      object,
    );
  }
}

class _ImportSnpFutureCallDispatcher {
  _ImportSnpFutureCallDispatcher(this._invokeFutureCall);

  final _InvokeFutureCall _invokeFutureCall;

  Future<void> run(_i4.Snp object) {
    return _invokeFutureCall(
      'ImportSnpRunFutureCall',
      object,
    );
  }
}

class CheckIndexProgressRunFutureCall extends _i1.FutureCall<_i2.Genome> {
  @override
  _i5.Future<void> invoke(
    _i1.Session session,
    _i2.Genome? object,
  ) async {
    await _i6.CheckIndexProgressFutureCall().run(
      session,
      object!,
    );
  }
}

class CheckMipgenProgressRunFutureCall extends _i1.FutureCall<_i3.Project> {
  @override
  _i5.Future<void> invoke(
    _i1.Session session,
    _i3.Project? object,
  ) async {
    await _i7.CheckMipgenProgressFutureCall().run(
      session,
      object!,
    );
  }
}

class DemoModeCleanupRunFutureCall extends _i1.FutureCall<_i3.Project> {
  @override
  _i5.Future<void> invoke(
    _i1.Session session,
    _i3.Project? object,
  ) async {
    await _i8.DemoModeCleanupFutureCall().run(
      session,
      object!,
    );
  }
}

class ImportSnpRunFutureCall extends _i1.FutureCall<_i4.Snp> {
  @override
  _i5.Future<void> invoke(
    _i1.Session session,
    _i4.Snp? object,
  ) async {
    await _i9.ImportSnpFutureCall().run(
      session,
      object!,
    );
  }
}
