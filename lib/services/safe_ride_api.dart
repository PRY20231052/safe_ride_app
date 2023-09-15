// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import 'dart:developer';


class SafeRideApi {
  String baseURL = "http://10.0.2.2:8000/api";
  // String baseURL = "https://saferide-api.onrender.com/api";

  Future<RouteModel?> requestRoute(LatLng origin, LatLng destination) async {
    var response = await http.post(
      Uri.parse('${baseURL}/routes/'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        "origin": {
          "latitude": origin.latitude,
          "longitude": origin.longitude
        },
        "waypoints": [
          {
            "latitude": destination.latitude,
            "longitude": destination.longitude
          }
        ]
      })
    );
    if (response.statusCode == 201) {
      RouteModel? route = RouteModel.fromJson(jsonDecode(response.body));
      return route;
    }
    return null;
  }
  Future<List<RouteModel>?> requestRoutes(LatLng origin, LatLng destination) async {
    var response = await http.post(
      Uri.parse('${baseURL}/routes/'),
      headers: {
        'Content-type': 'application/json',
        'Accept': 'application/json'
      },
      body: jsonEncode({
        "origin": {
          "latitude": origin.latitude,
          "longitude": origin.longitude
        },
        "waypoints": [
          {
            "latitude": destination.latitude,
            "longitude": destination.longitude
          }
        ]
      })
    );
    if (response.statusCode == 201) {
      RouteModel? route = RouteModel.fromJson(jsonDecode(response.body));
      return [route];
    }
    return null;
  }
}
