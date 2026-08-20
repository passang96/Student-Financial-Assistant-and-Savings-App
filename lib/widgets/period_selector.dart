import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/date_period.dart';

/// Horizontal scrollable row of period filter chips (This Week, Last Week,
/// This Fortnight, Last Fortnight, This Month, Last Month, Custom Range).
///
/// Selecting "Custom Range" opens a From -> To -> Apply bottom sheet before
/// calling [onPeriodChanged].
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.customRange,
    required this.onPeriodChanged,
  });

  final DatePeriod selectedPeriod;
  final DateRange? customRange;
  final void Function(DatePeriod period, {DateTime? start, DateTime? end})
      onPeriodChanged;

  Future<void> _openCustomRangePicker(BuildContext context) async {
    DateTime? fromDate = customRange?.start;
    DateTime? toDate = customRange?.end;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            String formatDate(DateTime? date) {
              if (date == null) return 'Select date';
              const months = [
                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
              ];
              return '${months[date.month - 1]} ${date.day}, ${date.year}';
            }

            Future<void> pickDate(bool isFrom) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: (isFrom ? fromDate : toDate) ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryTeal,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setSheetState(() {
                  if (isFrom) {
                    fromDate = picked;
                  } else {
                    toDate = picked;
                  }
                });
              }
            }

            final bool canApply = fromDate != null &&
                toDate != null &&
                !fromDate!.isAfter(toDate!);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Custom Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DateFieldButton(
                      label: 'From',
                      value: formatDate(fromDate),
                      onTap: () => pickDate(true),
                    ),
                    const SizedBox(height: 12),
                    _DateFieldButton(
                      label: 'To',
                      value: formatDate(toDate),
                      onTap: () => pickDate(false),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: canApply
                            ? () {
                                Navigator.of(context).pop();
                                onPeriodChanged(
                                  DatePeriod.custom,
                                  start: fromDate,
                                  end: toDate,
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          disabledBackgroundColor:
                              AppColors.primaryTeal.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final presets = DatePeriod.values.where((p) => p != DatePeriod.custom);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final period in presets) ...[
            _PeriodChip(
              label: period.label,
              selected: selectedPeriod == period,
              onTap: () => onPeriodChanged(period),
            ),
            const SizedBox(width: 8),
          ],
          _PeriodChip(
            label: selectedPeriod == DatePeriod.custom && customRange != null
                ? 'Custom Range'
                : 'Custom Range',
            icon: Icons.calendar_today_outlined,
            selected: selectedPeriod == DatePeriod.custom,
            onTap: () => _openCustomRangePicker(context),
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryTeal : AppColors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateFieldButton extends StatelessWidget {
  const _DateFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: AppColors.primaryTeal,
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
