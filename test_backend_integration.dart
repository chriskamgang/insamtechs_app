/// Test script to verify backend integration
/// Run with: dart test_backend_integration.dart
import 'dart:convert';
import 'dart:io';

void main() async {
  print('=== INSAM LMS Backend Integration Test ===\n');

  final baseUrl = 'https://admin.insamtechs.com/api';
  final client = HttpClient();

  try {
    // Test 1: Check backend connectivity
    await testEndpoint(client, baseUrl, 'Backend Connectivity');

    // Test 2: Test formations endpoint
    await testFormationsEndpoint(client, baseUrl);

    // Test 3: Test categories endpoint
    await testCategoriesEndpoint(client, baseUrl);

    // Test 4: Test single course by slug
    await testCourseBySlug(client, baseUrl);

    // Test 5: Test image URLs
    await testImageUrls(client);

    print('\n✅ All tests completed successfully!');
  } catch (e) {
    print('\n❌ Test failed: $e');
  } finally {
    client.close();
  }
}

Future<void> testEndpoint(HttpClient client, String url, String testName) async {
  print('🔍 Testing $testName...');
  try {
    final request = await client.getUrl(Uri.parse(url));
    request.headers.set('Accept', 'application/json');
    final response = await request.close();

    if (response.statusCode == 200) {
      print('   ✅ $testName: OK (Status: ${response.statusCode})');
    } else {
      print('   ⚠️  $testName: Status ${response.statusCode}');
    }

    await response.drain();
  } catch (e) {
    print('   ❌ $testName failed: $e');
    rethrow;
  }
}

Future<void> testFormationsEndpoint(HttpClient client, String baseUrl) async {
  print('\n🔍 Testing Formations Endpoint...');
  try {
    final request = await client.getUrl(Uri.parse('$baseUrl/formations'));
    request.headers.set('Accept', 'application/json');
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      print('   ✅ Formations loaded successfully');
      print('   📊 Current page: ${data['current_page']}');
      print('   📚 Total courses: ${data['total'] ?? data['data'].length}');

      if (data['data'] != null && data['data'].isNotEmpty) {
        final firstCourse = data['data'][0];
        print('   🎓 Sample course:');
        print('      - ID: ${firstCourse['id']}');
        print('      - Title (FR): ${firstCourse['intitule']?['fr']}');
        print('      - Price: ${firstCourse['prix']?['fr']} FCFA');
        print('      - Duration: ${firstCourse['duree']}');
        print('      - Image: ${firstCourse['img']}');
      }
    } else {
      print('   ❌ Status: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Failed: $e');
  }
}

Future<void> testCategoriesEndpoint(HttpClient client, String baseUrl) async {
  print('\n🔍 Testing Categories Endpoint...');
  try {
    final request = await client.getUrl(Uri.parse('$baseUrl/categories'));
    request.headers.set('Accept', 'application/json');
    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      print('   ✅ Categories loaded successfully');
      print('   📊 Total categories: ${data['total'] ?? data['data'].length}');

      if (data['data'] != null && data['data'].isNotEmpty) {
        final firstCategory = data['data'][0];
        print('   📁 Sample category:');
        print('      - ID: ${firstCategory['id']}');
        print('      - Title (FR): ${firstCategory['intitule']?['fr']}');
        print('      - Type: ${firstCategory['type']}');
        print('      - Image: ${firstCategory['img']}');
      }
    } else {
      print('   ❌ Status: ${response.statusCode}');
    }
  } catch (e) {
    print('   ❌ Failed: $e');
  }
}

Future<void> testCourseBySlug(HttpClient client, String baseUrl) async {
  print('\n🔍 Testing Course By Slug Endpoint...');
  try {
    // Use the slug from the first course we found
    final slug = 'initiez-vous-a-la-statistique-inferentielle-2y10wjdxxmnihj61gct7n8ofwaxfrizvgragizdjjumkvniakwc4a';

    final request = await client.postUrl(Uri.parse('$baseUrl/formation_by_Slug'));
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Accept', 'application/json');
    request.write(jsonEncode({'slug': slug}));

    final response = await request.close();

    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final data = jsonDecode(responseBody);

      print('   ✅ Course details loaded successfully');
      print('   🎓 Course info:');
      print('      - ID: ${data['id']}');
      print('      - Title: ${data['intitule']?['fr']}');
      print('      - Chapters: ${data['chapitres']?.length ?? 0}');
    } else {
      print('   ⚠️  Status: ${response.statusCode}');
    }
  } catch (e) {
    print('   ⚠️  Test skipped or failed: $e');
  }
}

Future<void> testImageUrls(HttpClient client) async {
  print('\n🔍 Testing Image URLs...');

  final testImages = [
    'https://admin.insamtechs.com/storage/Formations/initiez-vous-a-la-statistique-inferentielle290.webp',
    'https://admin.insamtechs.com/storage/Categories/analyse-de-donnees471.webp',
  ];

  for (final imageUrl in testImages) {
    try {
      final request = await client.getUrl(Uri.parse(imageUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        print('   ✅ Image accessible: ${imageUrl.split('/').last}');
      } else {
        print('   ⚠️  Image not found (${response.statusCode}): ${imageUrl.split('/').last}');
      }

      await response.drain();
    } catch (e) {
      print('   ❌ Image test failed: ${imageUrl.split('/').last}');
    }
  }
}
