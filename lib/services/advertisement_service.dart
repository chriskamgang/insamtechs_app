import '../models/advertisement.dart';
import '../config/api_config.dart';
import 'api_service.dart';

class AdvertisementService {
  static final AdvertisementService _instance = AdvertisementService._internal();
  factory AdvertisementService() => _instance;
  AdvertisementService._internal();

  final ApiService _apiService = ApiService();

  /// Get all active advertisements
  Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      final response = await _apiService.get('/advertisements');

      if (response.data != null && response.data['advertisements'] != null) {
        final List<dynamic> adsJson = response.data['advertisements'];
        return adsJson.map((json) => Advertisement.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error loading advertisements: $e');
      return [];
    }
  }

  /// Get advertisement by ID
  Future<Advertisement?> getAdvertisementById(int id) async {
    try {
      final response = await _apiService.get('/advertisements/$id');

      if (response.data != null && response.data['advertisement'] != null) {
        return Advertisement.fromJson(response.data['advertisement']);
      }

      return null;
    } catch (e) {
      print('Error loading advertisement: $e');
      return null;
    }
  }
}
