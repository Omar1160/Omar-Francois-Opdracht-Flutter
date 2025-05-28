import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String baseUrl = 'https://nominatim.openstreetmap.org';

  Future<List<Map<String, dynamic>>> searchLocation(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search?format=json&q=$query&limit=5&addressdetails=1'),
        headers: {'Accept-Language': 'en-US,en;q=0.9'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) {
          String name = '';
          String type = 'Location';

          // Build the location name from address components
          if (item['address'] != null) {
            final address = item['address'] as Map<String, dynamic>;
            List<String> components = [];

            // Add house number and road if available
            if (address['house_number'] != null && address['road'] != null) {
              components.add('${address['house_number']} ${address['road']}');
              type = 'Address';
            } else if (address['road'] != null) {
              components.add(address['road']);
              type = 'Address';
            }

            // Add city/town/village
            if (address['city'] != null) {
              components.add(address['city']);
              type = components.isEmpty ? 'City' : type;
            } else if (address['town'] != null) {
              components.add(address['town']);
              type = components.isEmpty ? 'City' : type;
            } else if (address['village'] != null) {
              components.add(address['village']);
              type = components.isEmpty ? 'City' : type;
            }

            // Add state/province if different from city
            if (address['state'] != null && 
                !components.contains(address['state'])) {
              components.add(address['state']);
              type = components.isEmpty ? 'Region' : type;
            }

            // Add country
            if (address['country'] != null) {
              components.add(address['country']);
            }

            name = components.join(', ');
          }

          // If no structured address, use display name
          if (name.isEmpty) {
            name = item['display_name'] ?? '';
          }

          return {
            'name': name,
            'type': type,
            'lat': double.parse(item['lat']),
            'lng': double.parse(item['lon']),
          };
        }).toList();
      }
    } catch (e) {
      print('Error searching locations: $e');
    }
    return [];
  }
} 