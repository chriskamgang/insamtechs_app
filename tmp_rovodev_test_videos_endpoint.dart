import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseURL: 'http://192.168.1.180:8001/api',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  try {
    print('🔍 Testing /api/chapitres/526/videos endpoint...');
    final response = await dio.get('/chapitres/526/videos');
    
    print('✅ Success! Status: ${response.statusCode}');
    print('📊 Response data type: ${response.data.runtimeType}');
    
    if (response.data is Map) {
      final data = response.data as Map<String, dynamic>;
      print('📋 Keys in response: ${data.keys.toList()}');
      
      if (data['videos'] != null && data['videos'] is List) {
        final videos = data['videos'] as List;
        print('🎥 Number of videos: ${videos.length}');
        
        if (videos.isNotEmpty) {
          print('\n📹 First video:');
          final firstVideo = videos[0] as Map<String, dynamic>;
          firstVideo.forEach((key, value) {
            print('   $key: $value');
          });
        }
      }
    }
  } catch (e) {
    print('❌ Error: $e');
    if (e is DioException) {
      print('   Status Code: ${e.response?.statusCode}');
      print('   Response: ${e.response?.data}');
    }
  }
}
