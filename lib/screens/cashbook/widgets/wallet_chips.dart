import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../infrastructure/models/db_models.dart';
import '../../wallet/wallet_detail_screen.dart';

class WalletChips extends StatelessWidget {
  final List<DbWallet> wallets;
  final Map<String, double> balances;

  const WalletChips({
    super.key,
    required this.wallets,
    required this.balances,
  });

  Color _parseColor(String hex) {
    try {
      final cleaned = hex.replaceAll('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return Colors.green.shade400;
    }
  }

  IconData _walletIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gcash') || lower.contains('maya')) return Icons.phone_android_rounded;
    if (lower.contains('bdo') || lower.contains('bpi') || lower.contains('east') || lower.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('cash')) return Icons.payments_rounded;
    return Icons.wallet_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    if (wallets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withOpacity(0.04),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade400.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add_card_rounded, color: Colors.green.shade400, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No Active Wallets',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to add your first wallet',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 165,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: wallets.length,
        itemBuilder: (context, index) {
          final wallet = wallets[index];
          final balance = balances[wallet.id] ?? 0.0;
          final cardColor = _parseColor(wallet.color);

          // Get wallet subtext category
          final nameLower = wallet.name.toLowerCase();
          final cardType = (nameLower.contains('gcash') || nameLower.contains('maya'))
              ? 'DIGITAL WALLET'
              : (nameLower.contains('cash') && !nameLower.contains('gcash'))
                  ? 'PHYSICAL CASH'
                  : 'BANK ACCOUNT';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WalletDetailScreen(walletId: wallet.id),
                ),
              );
            },
            child: Container(
              width: 275,
              margin: EdgeInsets.only(
                left: index == 0 ? 20 : 8,
                right: index == wallets.length - 1 ? 20 : 8,
                top: 4,
                bottom: 8,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  children: [
                    // Gradient Background
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            cardColor.withOpacity(0.85),
                            cardColor.withOpacity(0.45),
                            const Color(0xFF0F1B2D).withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: cardColor.withOpacity(0.25)),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    
                    // Glassmorphic Shiny Circle Highlights
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),

                    // Card Details Layout
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Top row: Logo, icon and Type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _walletIcon(wallet.name),
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    wallet.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              Text(
                                cardType,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),

                          // NFC/Chip Icon row
                          Icon(
                            Icons.nfc_rounded,
                            color: Colors.white.withOpacity(0.35),
                            size: 24,
                          ),

                          // Bottom Row: Balance & card branding circle overlay
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BALANCE',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    formatter.format(balance),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                              // Decorative Mastercard style overlapping circles
                              Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(-8, 0),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
