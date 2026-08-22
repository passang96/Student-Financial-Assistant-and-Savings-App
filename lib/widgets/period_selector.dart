import 'package:flutter/material.dart';

import '../utils/date_period.dart';

class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.customStartDate,
    required this.customEndDate,
    required this.onCustomRangeRequested,
  });

  final DatePeriod selectedPeriod;
  final ValueChanged<DatePeriod> onPeriodChanged;

  final DateTime? customStartDate;
  final DateTime? customEndDate;

  final VoidCallback onCustomRangeRequested;

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '--/--/----';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isCustom = selectedPeriod == DatePeriod.custom;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Choose the period you want to analyse.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 14),

          DropdownButtonFormField<DatePeriod>(
            initialValue: selectedPeriod,
            decoration: const InputDecoration(
              labelText: 'Period',
              prefixIcon: Icon(Icons.date_range_outlined),
              border: OutlineInputBorder(),
            ),
            items: DatePeriod.values.map((period) {
              return DropdownMenuItem<DatePeriod>(
                value: period,
                child: Text(period.label),
              );
            }).toList(),
            onChanged: (period) {
              if (period != null) {
                onPeriodChanged(period);
              }
            },
          ),

          if (isCustom) ...[
            const SizedBox(height: 14),

            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onCustomRangeRequested,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFF0E9F99),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Custom Date Range',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            customStartDate == null || customEndDate == null
                                ? 'Tap to choose start and end dates'
                                : '${_formatDate(customStartDate)}'
                                      '  →  '
                                      '${_formatDate(customEndDate)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
