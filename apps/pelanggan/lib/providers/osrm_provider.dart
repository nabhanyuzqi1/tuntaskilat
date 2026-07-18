import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Rute jalan nyata OSRM (HTTPS — cleartext diblok di rilis Android).
final osrmRouteProvider = FutureProvider.autoDispose
    .family<List<LatLng>, ({LatLng start, LatLng end})>((ref, args) async {
  final url = Uri.parse('https://router.project-osrm.org/route/v1/driving/'
      '${args.start.longitude},${args.start.latitude};'
      '${args.end.longitude},${args.end.latitude}?geometries=geojson');
  final response = await http.get(url).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final routes = data['routes'] as List<dynamic>;
    if (routes.isNotEmpty) {
      final geometry =
          routes[0]['geometry']['coordinates'] as List<dynamic>;
      return geometry
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    }
  }
  return [];
});

/// Reverse-geocode OSM Nominatim — koordinat → alamat teks (gratis, tanpa key).
/// Kebijakan Nominatim wajib User-Agent identitas app; batasi ~1 req/detik
/// (panggil setelah user selesai menggeser peta / debounce di UI).
final reverseGeocodeProvider = FutureProvider.autoDispose
    .family<String, ({double lat, double lng})>((ref, args) async {
  final url = Uri.parse('https://nominatim.openstreetmap.org/reverse'
      '?format=jsonv2&lat=${args.lat}&lon=${args.lng}&zoom=18&addressdetails=1');
  final res = await http.get(url, headers: {
    'User-Agent': 'Tuntaskilat/1.0 (layanan kebersihan Sampit)'
  }).timeout(const Duration(seconds: 8));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final display = data['display_name'] as String?;
    if (display != null && display.isNotEmpty) return display;
  }
  return '';
});

/// Forward-geocode OSM Nominatim — pencarian alamat → koordinat.
final forwardGeocodeProvider = FutureProvider.autoDispose
    .family<LatLng?, String>((ref, query) async {
  if (query.isEmpty) return null;
  final url = Uri.parse('https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}&format=jsonv2&limit=1');
  final res = await http.get(url, headers: {
    'User-Agent': 'Tuntaskilat/1.0 (layanan kebersihan Sampit)'
  }).timeout(const Duration(seconds: 8));
  if (res.statusCode == 200) {
    final data = jsonDecode(res.body) as List<dynamic>;
    if (data.isNotEmpty) {
      final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
      final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
      if (lat != null && lon != null) return LatLng(lat, lon);
    }
  }
  return null;
});
