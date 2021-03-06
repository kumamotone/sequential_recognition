import 'package:flutter/material.dart';

final theme = ThemeData(
  primarySwatch: Colors.amber,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
);

const boldTextStyle = TextStyle(fontWeight: FontWeight.bold);
