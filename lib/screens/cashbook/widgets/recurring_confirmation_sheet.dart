import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../features/cashbook/cashbook_providers.dart';
import '../../../infrastructure/models/db_models.dart';

class RecurringConfirmationSheet extends ConsumerStatefulWidget {
  final List<DbTransaction> dueTransactions;

  const RecurringConfirmationSheet({
    super.key,
    required this.dueTransactions,
  });

  @override
  ConsumerState<RecurringConfirmationSheet> createState() => _RecurringConfirmationSheetState();
}

class _RecurringConfirmationSheetState extends ConsumerState<RecurringConfirmationSheet> {
  final Map<String, bool> _selected = {};

  @override
  void initState() {
    super.initState();
    for (final tx in widget.dueTransactions) {
      _selected[tx.id] = true; // Selected by default
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '₱', decimalDigits: 2);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B2D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade400.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.alarm_on_rounded,
                  color: Colors.amber.shade400,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recurring Transactions Due',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'We found recurring items due/overdue for this month.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: widget.dueTransactions.map((tx) {
                  final isIncome = tx.type == 'income';
                  final isSelected = _selected[tx.id] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.green.shade400.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                      ),
                    ),
                    child: CheckboxListTile(
                      value: isSelected,
                      activeColor: Colors.green.shade400,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selected[tx.id] = val ?? false;
                        });
                      },
                      title: Text(
                        tx.note ?? 'Recurring item',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (isIncome ? Colors.green : Colors.red).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isIncome ? 'Income' : 'Bill',
                                  style: TextStyle(
                                    color: isIncome ? Colors.green.shade300 : Colors.red.shade300,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Due Day: ${tx.recurringDay}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      secondary: Text(
                        formatter.format(tx.amount),
                        style: TextStyle(
                          color: isIncome ? Colors.green.shade400 : Colors.red.shade400,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () async {
                    final selectedTemplates = widget.dueTransactions
                        .where((tx) => _selected[tx.id] == true)
                        .toList();

                    if (selectedTemplates.isNotEmpty) {
                      final service = ref.read(cashbookServiceProvider);
                      for (final template in selectedTemplates) {
                        await service.skipRecurringTransaction(template);
                      }
                      invalidateCashbookProviders(ref);
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Skipped ${selectedTemplates.length} recurring item(s) for this month.'),
                            backgroundColor: Colors.amber.shade700,
                          ),
                        );
                      }
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    widget.dueTransactions.any((tx) => _selected[tx.id] == true)
                        ? 'Skip Selected'
                        : 'Close',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.dueTransactions.any((tx) => _selected[tx.id] == true)
                      ? () async {
                          final selectedTemplates = widget.dueTransactions
                              .where((tx) => _selected[tx.id] == true)
                              .toList();

                          if (selectedTemplates.isNotEmpty) {
                            final service = ref.read(cashbookServiceProvider);
                            for (final template in selectedTemplates) {
                              await service.logRecurringTransaction(template);
                            }
                            invalidateCashbookProviders(ref);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Successfully logged ${selectedTemplates.length} recurring transaction(s)!',
                                ),
                                backgroundColor: Colors.green.shade600,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade500,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withOpacity(0.05),
                    disabledForegroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Log Selected',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
