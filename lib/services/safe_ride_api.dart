// ignore_for_file: unnecessary_brace_in_string_interps, prefer_const_constructors

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safe_ride_app/models/favorite_location_model.dart';
import 'package:safe_ride_app/models/user_model.dart';
import '../models/route_model.dart';
import 'dart:developer';


class SafeRideApi {
  final String baseURL = "http://10.0.2.2:8000/api";
  // final String baseURL = 'https://aldair98.pythonanywhere.com/api';

  //TEMP
  UserModel? sampleUser;
  String samplePassword = '';

  Future<UserModel?> registerUser({required UserModel user, required String password}) async {
    user.id = '0';
    sampleUser = user;
    samplePassword = password;
    return sampleUser;
  }

  Future<UserModel?> authenticateUser({required String email, required String password}) async {
    try {
      if(email == sampleUser!.email || password == samplePassword){
        return sampleUser;
      }

      // var response = await http.post(
      // Uri.parse('${baseURL}/users/'),
      //   headers: {
      //     'Content-type': 'application/json',
      //     'Accept': 'application/json',
      //   },
      //   body: jsonEncode({
      //     "id": 1,
      //   })
      // );
      // if (response.statusCode == 201) {
      //   UserModel? user = UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      //   return user;
      // }

      return null;

    } on Exception catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> fetchUserById({required String id}) async {
    try {
      
      return UserModel(
        id: id,
        userName: 'aldor98',
        fullName: 'Aldair Cuarez',
        email: 'aldaircuarez98@gmail.com',
        phoneNumber: '999999999',
        favoriteLocations: [
          FavoriteLocationModel(
            id: '0',
            alias: 'Casa',
            coordinates: LatLng(-12.089739276201591, -76.99413771816357),
            name: 'Las Artes 1166',
            address: 'Las Artes 1166, Lima 15037',
          ),
        ],
      );

      // var response = await http.post(
      // Uri.parse('${baseURL}/users/'),
      //   headers: {
      //     'Content-type': 'application/json',
      //     'Accept': 'application/json',
      //   },
      //   body: jsonEncode({
      //     "id": 1,
      //   })
      // );
      // if (response.statusCode == 201) {
      //   UserModel? user = UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      //   return user;
      // }

      return null;

    } on Exception catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> updateUser({required String id, required UserModel user}) async {
    try {
      
      return UserModel(
        id: id,
        userName: 'aldor98',
        fullName: 'Aldair Cuarez',
        email: 'aldaircuarez98@gmail.com',
        phoneNumber: '999999999',
        favoriteLocations: [
          FavoriteLocationModel(
            id: '0',
            alias: 'Casa',
            coordinates: LatLng(-12.089739276201591, -76.99413771816357),
            name: 'Las Artes 1166',
            address: 'Las Artes 1166, Lima 15037',
          ),
        ],
      );

      // var response = await http.post(
      // Uri.parse('${baseURL}/users/'),
      //   headers: {
      //     'Content-type': 'application/json',
      //     'Accept': 'application/json',
      //   },
      //   body: jsonEncode({
      //     "id": 1,
      //   })
      // );
      // if (response.statusCode == 201) {
      //   UserModel? user = UserModel.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
      //   return user;
      // }

      return null;

    } on Exception catch (e) {
      rethrow;
    }
  }

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
      log(response.body);
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
