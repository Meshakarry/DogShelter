package com.dogshelter.dogshelter_mobile

import io.flutter.embedding.android.FlutterFragmentActivity

// flutter_stripe requires a FlutterFragmentActivity (not the default FlutterActivity) - its
// native Android SDK needs Fragment support for 3D Secure/Google Pay UI.
class MainActivity : FlutterFragmentActivity()
