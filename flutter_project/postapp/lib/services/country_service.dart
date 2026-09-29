import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/country.dart';

/// Service responsible for fetching country data from the REST Countries API.
class CountryService {
  static const String _baseUrl = 'https://restcountries.com/v3.1';

  final http.Client _client;

  CountryService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetches the full list of countries (name + ISO code only).
  Future<List<Country>> fetchCountries() async {
    final uri = Uri.parse('$_baseUrl/all?fields=name,cca2');

    final response = await _client.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Request timed out. Please check your connection.'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load countries (HTTP ${response.statusCode}).');
    }

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((json) => Country.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
