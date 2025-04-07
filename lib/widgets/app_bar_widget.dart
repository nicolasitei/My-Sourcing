
import 'package:flutter/material.dart';

PreferredSizeWidget customAppBar({List<Widget>? actions}) {
  return AppBar(
    title: const Text(
      'My Sourcing',
      style: TextStyle(color: Color(0xFF0085AF),  // Appliquer la couleur bleue personnalisée
            fontSize: 30,  // Taille doublée de la police
            fontWeight: FontWeight.w500, ),
    ),
    centerTitle: true,
    elevation: 0,
    actions: actions,
  );
}
