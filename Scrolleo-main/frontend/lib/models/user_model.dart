import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final bool isDirector;
  final String? phoneNumber;
  final String? address;
  final DateTime? subscriptionEndDate;
  final String? paymentMethod;
  final DateTime? createdAt;
  final bool emailNotifications;
  final bool pushNotifications;
  final String? subscriptionPlan;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    this.isDirector = false,
    this.phoneNumber,
    this.address,
    this.subscriptionEndDate,
    this.paymentMethod,
    this.createdAt,
    this.emailNotifications = false,
    this.pushNotifications = false,
    this.subscriptionPlan,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      email: json['email'],
      name: json['name'],
      photoUrl: json['photoUrl'],
      isDirector: json['isDirector'] ?? false,
      phoneNumber: json['phoneNumber'],
      address: json['address'],
      subscriptionEndDate: json['subscriptionEndDate'] != null 
          ? DateTime.parse(json['subscriptionEndDate']) 
          : null,
      paymentMethod: json['paymentMethod'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
      emailNotifications: json['emailNotifications'] ?? false,
      pushNotifications: json['pushNotifications'] ?? false,
      subscriptionPlan: json['subscriptionPlan'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photoUrl': photoUrl,
      'isDirector': isDirector,
      'phoneNumber': phoneNumber,
      'address': address,
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'createdAt': createdAt?.toIso8601String(),
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'subscriptionPlan': subscriptionPlan,
    };
  }
} 