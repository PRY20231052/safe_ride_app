import 'package:safe_ride_app/models/favorite_location_model.dart';

class UserModel{
  String id;
  String userName;
  String fullName;
  String email;
  String phoneNumber;
  List<FavoriteLocationModel> favoriteLocations;

  UserModel({
    required this.id,
    required this.userName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.favoriteLocations,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      userName: json['username'],
      fullName: json['full_name'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      favoriteLocations: (json['favorite_locations'] as List).map((favoriteLocationJson) => FavoriteLocationModel.fromJson(favoriteLocationJson)).toList(),
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'userName': userName,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'favoriteLocations': favoriteLocations.map((favoriteLocation) => favoriteLocation.toJson()).toList(),
    };
  }
}