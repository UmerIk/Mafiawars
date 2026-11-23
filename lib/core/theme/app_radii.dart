import 'package:flutter/material.dart';

/// Design tokens for corner radii in the Mafia-Wars design system.
class AppRadii {
  AppRadii._();

  static const double s = 6.0;
  static const double m = 10.0;
  static const double l = 16.0;
  static const double xl = 20.0;
  static const double circular = 999.0;

  static const BorderRadius radiusS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius radiusM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius radiusL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius radiusXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusCircular = BorderRadius.all(Radius.circular(circular));

  static const RoundedRectangleBorder shapeS = RoundedRectangleBorder(borderRadius: radiusS);
  static const RoundedRectangleBorder shapeM = RoundedRectangleBorder(borderRadius: radiusM);
  static const RoundedRectangleBorder shapeL = RoundedRectangleBorder(borderRadius: radiusL);
  static const RoundedRectangleBorder shapeXl = RoundedRectangleBorder(borderRadius: radiusXl);
}
