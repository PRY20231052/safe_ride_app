import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:safe_ride_app/models/favorite_location_model.dart';
import 'package:safe_ride_app/models/user_model.dart';
import 'package:safe_ride_app/services/safe_ride_api.dart';

class UserProvider with ChangeNotifier{
  final _safeRideApi = SafeRideApi();

  UserModel? _user;
  UserModel? get user => _user;
  set user(UserModel? user){_user = user; notifyListeners();}

  Future<void> initialize() async {
    // _user = await _safeRideApi.fetchUserById(id: '1');
  }

  Future<bool> login({required String email, required String password}) async {
    _user = await _safeRideApi.authenticateUser(email: email, password: password);
    notifyListeners();
    if(_user == null){
      return false;
    }
    notifyListeners();
    return true;
  }
  Future<bool> register({
    required String email,
    required String password,
    required String username,
    required String fullName
  }) async {

    _user = await _safeRideApi.registerUser(
      user: UserModel(
        id: '0',
        userName: username,
        fullName: fullName,
        email: email,
        phoneNumber: '',
        favoriteLocations: [],
      ),
      password: password
    );
    
    notifyListeners();
    return _user == null ? false : true;
  }
  void addFavoriteLocation(FavoriteLocationModel favoriteLocation){
    favoriteLocation.id = _user!.favoriteLocations.isNotEmpty ? '${int.parse(_user!.favoriteLocations.last.id!) + 1}' : '0'; // last id + 1
    _user!.favoriteLocations.add(favoriteLocation);
    notifyListeners();
  }
  void modifyFavoriteLocation(String id, FavoriteLocationModel updatedFavoriteLocation){
    int index = _user!.favoriteLocations.indexWhere((favoriteLocation) => favoriteLocation.id == id);
    updatedFavoriteLocation.id = id;
    _user!.favoriteLocations[index] = updatedFavoriteLocation;
    notifyListeners();
  }
  void deleteFavoriteLocation(String id){
    _user!.favoriteLocations.removeWhere((favoriteLocation) => favoriteLocation.id == id);
    notifyListeners();
  }
}