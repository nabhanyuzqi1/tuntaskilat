import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

final osrmRouteProvider = FutureProvider.autoDispose.family<List<LatLng>, ({LatLng start, LatLng end})>((ref, args) async {
  final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/driving/${args.start.longitude},${args.start.latitude};${args.end.longitude},${args.end.latitude}?geometries=geojson');
  final response = await http.get(url).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final routes = data['routes'] as List<dynamic>;
    if (routes.isNotEmpty) {
      final geometry = routes[0]['geometry']['coordinates'] as List<dynamic>;
      return geometry.map((coord) => LatLng(coord[1] as double, coord[0] as double)).toList();
    }
  }
  return [];
});
