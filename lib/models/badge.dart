import 'package:flutter/material.dart'; // For IconData

class Badge {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final int milestoneDays; // The streak length required to unlock this badge

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.milestoneDays,
  });

  // Factory constructor to create a Badge from a JSON map
  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: IconData(json['iconCodePoint'], fontFamily: json['iconFontFamily']),
      milestoneDays: json['milestoneDays'],
    );
  }

  // Method to convert a Badge to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'milestoneDays': milestoneDays,
    };
  }
}
