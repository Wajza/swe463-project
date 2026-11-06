import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'providers/listing_provider.dart';
import 'providers/profile_provider.dart';

class SouqSkillsProviders extends StatelessWidget {
  const SouqSkillsProviders({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
      ],
      child: child,
    );
  }
}
