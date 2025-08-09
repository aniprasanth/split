import 'package:flutter/material.dart';
import 'package:splitzy/utils/formatters.dart';

enum SettlementStatus {
  pending,
  completed,
  cancelled,
}

extension SettlementStatusExtension on SettlementStatus {
  String get name {
    switch (this) {
      case SettlementStatus.pending:
        return 'Pending';
      case SettlementStatus.completed:
        return 'Completed';
      case SettlementStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color get color {
    switch (this) {
      case SettlementStatus.pending:
        return Colors.orange;
      case SettlementStatus.completed:
        return Colors.green;
      case SettlementStatus.cancelled:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case SettlementStatus.pending:
        return Icons.schedule;
      case SettlementStatus.completed:
        return Icons.check_circle;
      case SettlementStatus.cancelled:
        return Icons.cancel;
    }
  }
}

class SettlementTile extends StatelessWidget {
  final String id;
  final String from;
  final String to;
  final double amount;
  final DateTime date;
  final SettlementStatus status;
  final String? groupName;
  final String? paymentMethod;
  final String? transactionId;
  final VoidCallback? onTap;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onCancel;
  final bool isCurrentUser;
  final bool showActions;

  const SettlementTile({
    super.key,
    required this.id,
    required this.from,
    required this.to,
    required this.amount,
    required this.date,
    this.status = SettlementStatus.pending,
    this.groupName,
    this.paymentMethod,
    this.transactionId,
    this.onTap,
    this.onMarkComplete,
    this.onCancel,
    this.isCurrentUser = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildAvatarStack(),
        title: _buildTitle(theme),
        subtitle: _buildSubtitle(theme),
        trailing: _buildTrailing(context),
        onTap: onTap ?? () => _showDetailsBottomSheet(context),
      ),
    );
  }

  Widget _buildAvatarStack() {
    return SizedBox(
      width: 50,
      height: 50,
      child: Stack(
        children: [
          // From avatar (background)
          Positioned(
            left: 0,
            top: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.blue.withValues(alpha: 0.2),
              child: Text(
                from[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // To avatar (foreground)
          Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.green.withValues(alpha: 0.2),
              child: Text(
                to[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          // Arrow icon in the middle
          Positioned(
            left: 15,
            top: 15,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                size: 12,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    String title;
    if (isCurrentUser) {
      title = status == SettlementStatus.completed
          ? 'You paid $to'
          : 'You owe $to';
    } else {
      title = status == SettlementStatus.completed
          ? '$from paid $to'
          : '$from owes $to';
    }

    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
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
        if (groupName != null) ...[
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
                  'From $groupName',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
        ],
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: theme.textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 4),
            Text(
              status == SettlementStatus.completed
                  ? 'Settled on ${Formatters.formatDate(date)}'
                  : 'Due ${Formatters.formatDate(date)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (paymentMethod != null && status == SettlementStatus.completed) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.payment,
                size: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              const SizedBox(width: 4),
              Text(
                'via $paymentMethod',
                style: theme.textTheme.bodySmall,
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
            color: status.color,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: status.color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status.icon,
                size: 12,
                color: status.color,
              ),
              const SizedBox(width: 4),
              Text(
                status.name,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDetailsBottomSheet(BuildContext context) {
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
                _buildAvatarStack(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCurrentUser
                            ? (status == SettlementStatus.completed
                                ? 'You paid $to'
                                : 'You owe $to')
                            : (status == SettlementStatus.completed
                                ? '$from paid $to'
                                : '$from owes $to'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Formatters.formatCurrency(amount),
                        style: TextStyle(
                          fontSize: 16,
                          color: status.color,
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
            
            // Details
            _buildDetailRow('Status', status.name, status.icon, status.color),
            
            if (groupName != null)
              _buildDetailRow('Group', groupName!, Icons.group, Colors.blue),
            
            _buildDetailRow(
              'Date', 
              status == SettlementStatus.completed
                  ? 'Settled on ${Formatters.formatDate(date)}'
                  : 'Due ${Formatters.formatDate(date)}',
              Icons.calendar_today,
              Colors.grey,
            ),
            
            if (paymentMethod != null && status == SettlementStatus.completed)
              _buildDetailRow('Payment Method', paymentMethod!, Icons.payment, Colors.green),
            
            if (transactionId != null && status == SettlementStatus.completed)
              _buildDetailRow('Transaction ID', transactionId!, Icons.receipt, Colors.orange),
            
            const SizedBox(height: 20),
            
            // Action buttons
            if (showActions && status == SettlementStatus.pending) ...[
              if (isCurrentUser && onMarkComplete != null)
                _buildActionButton(
                  context,
                  'Mark as Paid',
                  Icons.check_circle,
                  Colors.green,
                  () {
                    Navigator.pop(context);
                    onMarkComplete?.call();
                  },
                ),
              
              if (isCurrentUser && onMarkComplete != null && onCancel != null)
                const SizedBox(height: 12),
              
              if (onCancel != null)
                _buildActionButton(
                  context,
                  'Cancel Settlement',
                  Icons.cancel,
                  Colors.red,
                  () {
                    Navigator.pop(context);
                    _showCancelConfirmation(context);
                  },
                ),
            ],
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Settlement'),
        content: Text(
          'Are you sure you want to cancel this settlement of ${Formatters.formatCurrency(amount)} between $from and $to?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onCancel?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Settlement'),
          ),
        ],
      ),
    );
  }
}