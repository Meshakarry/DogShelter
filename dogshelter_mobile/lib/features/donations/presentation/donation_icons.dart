import 'package:flutter/material.dart';

/// Maps a KategorijaDonacije/PotrebaAzila IkonaKljuc (a real, server-sourced key - never guessed
/// from the display name) to a Material icon. Shared between category selection cards and the
/// shelter-needs board since both entities use the same key space.
IconData donationIconFor(String ikonaKljuc) {
  switch (ikonaKljuc) {
    case 'hrana_psi':
      return Icons.restaurant;
    case 'hrana_stenad':
      return Icons.cookie_outlined;
    case 'deke':
      return Icons.bed_outlined;
    case 'igracke':
      return Icons.toys_outlined;
    case 'povodci':
      return Icons.link;
    case 'posude':
      return Icons.ramen_dining_outlined;
    case 'lijekovi':
      return Icons.medical_services_outlined;
    case 'cistoca':
      return Icons.cleaning_services_outlined;
    case 'ostalo':
      return Icons.category_outlined;
    default:
      return Icons.pets_outlined;
  }
}
