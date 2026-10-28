import 'package:flutter/material.dart';
import 'package:kalkulator_kpr/core/theme.dart';

/// Tab bergradasi untuk ikon premium di AppBar: membulat di sisi kiri saja dan
/// menempel ke tepi kanan layar (actions AppBar Material 2 tidak punya padding
/// kanan, jadi tab ini harus jadi item terakhir di `actions`).
///
/// Gradasi ungu + lencana garis untuk user gratis (ajakan upgrade), gradasi
/// emas + lencana terisi untuk user premium.
class PremiumTab extends StatelessWidget {
  const PremiumTab({
    super.key,
    required this.isPremium,
    required this.onTap,
  });

  final bool isPremium;
  final VoidCallback onTap;

  static const BorderRadius _radius =
      BorderRadius.horizontal(left: Radius.circular(20));

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Tooltip(
        message: isPremium ? 'Premium aktif' : 'Upgrade ke Premium',
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: _radius,
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: isPremium
                    ? AppColors.premiumGradient
                    : AppColors.upgradeGradient,
              ),
            ),
            child: InkWell(
              borderRadius: _radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 7, 12, 7),
                child: Icon(
                  isPremium
                      ? Icons.workspace_premium
                      : Icons.workspace_premium_outlined,
                  color: AppColors.onPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
