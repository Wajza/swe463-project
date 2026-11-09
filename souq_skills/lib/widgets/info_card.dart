import 'package:flutter/material.dart';

import 'info_tile.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({required this.tiles, super.key});

  final List<InfoTile> tiles;

  @override
  Widget build(BuildContext context) => Card(child: Column(children: tiles));
}
