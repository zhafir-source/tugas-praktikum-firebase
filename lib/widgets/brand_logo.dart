import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.account_balance_wallet_rounded,
          color: cs.onPrimary, size: size * 0.5),
    );
  }
}
