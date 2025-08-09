import 'package:flutter/material.dart';
import 'package:splitzy/utils/formatters.dart';

enum ExpenseCategory {
  food,
  transportation,
  accommodation,
  entertainment,
  shopping,
  utilities,
  healthcare,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant;
      case ExpenseCategory.transportation:
        return Icons.directions_car;
      case ExpenseCategory.accommodation:
        return Icons.hotel;
      case ExpenseCategory.entertainment:
        return Icons.movie;
      case ExpenseCategory.shopping:
        return Icons.shopping_bag;
      case ExpenseCategory.utilities:
        return Icons.electrical_services;
      case ExpenseCategory.healthcare:
        return Icons.local_hospital;
      case ExpenseCategory.other:
        return Icons.receipt_long;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return Colors.orange;
      case ExpenseCategory.transportation:
        return Colors.blue;
      case ExpenseCategory.accommodation:
        return Colors.purple;
      case ExpenseCategory.entertainment:
        return Colors.red;
      case ExpenseCategory.shopping:
        return Colors.green;
      case ExpenseCategory.utilities:
        return Colors.amber;
      case ExpenseCategory.healthcare:
        return Colors.teal;
      case ExpenseCategory.other:
        return Colors.grey;
    }
  }

  String get name {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.healthcare:
        return 'Healthcare';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}

class ExpenseTile extends StatelessWidget {
  final String id;
  final String description;
  final double amount;
  final String paidBy;
  final DateTime date;
  final ExpenseCategory category;
  final List<String> participants;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool showActions;

  const ExpenseTile({
    super.key,
    required this.id,
    required this.description,
    required this.amount,
    required this.paidBy,
    required this.date,
    this.category = ExpenseCategory.other,
    this.participants = const [],
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isSelected ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: _buildCategoryIcon(),
          title: _buildTitle(theme),
          subtitle: _buildSubtitle(theme),
          trailing: _buildTrailing(context),
          onTap: onTap,
          onLongPress: showActions ? () => _showActionBottomSheet(context) : null,
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        category.icon,
        color: category.color,
        size: 24,
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      description,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildSubtitle(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.person,
              size: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Paid by $paidBy',
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              Formatters.formatDate(date),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (participants.isNotEmpty) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.group,
                size: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '${participants.length} participants',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          Formatters.formatCurrency(amount),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            category.name,
            style: theme.textTheme.bodySmall?.copyWith(
              color: category.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _showActionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        Formatters.formatCurrency(amount),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            if (onEdit != null)
              _buildActionButton(
                context,
                'Edit Expense',
                Icons.edit,
                Colors.blue,
                () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
            
            if (onEdit != null && onDelete != null)
              const SizedBox(height: 12),
            
            if (onDelete != null)
              _buildActionButton(
                context,
                'Delete Expense',
                Icons.delete,
                Colors.red,
                () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(context);
                },
              ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Are you sure you want to delete "$description"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}