// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/route_model.dart';
import 'dart:developer';


class SafeRideApi {
  final String baseURL = "http://10.0.2.2:8000/api";
  // final String baseURL = 'https://aldair98.pythonanywhere.com/api';

  Future<RouteModel?> requestRoute(LatLng origin, List<LatLng> waypoints) async {
    try {
      var response = await http.post(
      Uri.parse('${baseURL}/routes/'),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "origin": {
            "coordinates": {
              "latitude": origin.latitude, 
              "longitude": origin.longitude
            }
          },
          "waypoints": [
            for (var waypoint in waypoints)
              {
                "coordinates": {
                  "latitude": waypoint.latitude,
                  "longitude": waypoint.longitude
                }
              }
          ]
        })
      );
      // log(response.body);
      if (response.statusCode == 201) {
        RouteModel? route = RouteModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
        return route;
      }
      return null;
      
    } on Exception catch (e) {
      rethrow;
    }
  }
}
