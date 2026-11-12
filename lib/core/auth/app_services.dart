import 'package:dio/dio.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/shipment_repository.dart';
import '../network/api_client.dart';
import '../storage/token_storage.dart';
import 'session.dart';

class AppServices {
  AppServices._(
    this.storage,
    this.api,
    this.auth,
    this.shipments,
    this.session,
  );

  final TokenStorage storage;
  final ApiClient api;
  final AuthRepository auth;
  final ShipmentRepository shipments;
  final Session session;

  static AppServices? _instance;

  static AppServices get I {
    final instance = _instance;
    if (instance == null) {
      throw StateError(
        'AppServices belum diinisialisasi (panggil AppServices.use di main).',
      );
    }
    return instance;
  }

  static void use(AppServices services) => _instance = services;

  factory AppServices.create({TokenStorage? storage, Dio? dio}) {
    final store = storage ?? SecureTokenStorage();
    late final Session session;

    final api = ApiClient(
      storage: store,
      dio: dio,
      onUnauthorized: () => session.handleUnauthorized(),
    );
    final authRepository = AuthRepository(api, store);
    final shipmentRepository = ShipmentRepository(api);
    session = Session(repository: authRepository, storage: store);

    return AppServices._(
      store,
      api,
      authRepository,
      shipmentRepository,
      session,
    );
  }
}
