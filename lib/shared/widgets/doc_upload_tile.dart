import 'package:flutter/material.dart';

import '../data/models/account_profile.dart';

class DocUploadTile extends StatelessWidget {
  const DocUploadTile({
    super.key,
    required this.docType,
    this.docSubtype,
    required this.status,
    this.onTap,
    this.expiresAt,
    this.reason,
  });

  final String docType;
  final String? docSubtype;
  final String status;
  final VoidCallback? onTap;
  final DateTime? expiresAt;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final IconData icon;
    final Color statusColor;
    final String statusText;

    switch (status.toLowerCase()) {
      case 'approved':
        icon = Icons.check_circle;
        statusColor = colorScheme.primary;
        statusText = 'Approved';
        break;
      case 'pending':
        icon = Icons.pending;
        statusColor = colorScheme.outline;
        statusText = 'Pending';
        break;
      case 'rejected':
        icon = Icons.cancel;
        statusColor = colorScheme.error;
        statusText = 'Rejected';
        break;
      case 'expired':
        icon = Icons.schedule;
        statusColor = colorScheme.error;
        statusText = 'Expired';
        break;
      case 'manual_review':
        icon = Icons.rate_review;
        statusColor = colorScheme.tertiary;
        statusText = 'In Review';
        break;
      default:
        icon = Icons.description_outlined;
        statusColor = colorScheme.outline;
        statusText = status;
    }

    final isExpiringSoon = expiresAt != null &&
        expiresAt!.difference(DateTime.now()).inDays < 30 &&
        expiresAt!.difference(DateTime.now()).inDays > 0;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          foregroundColor: statusColor,
          child: Icon(icon, size: 24),
        ),
        title: Text(
          docSubtype != null ? '$docType ($docSubtype)' : docType,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(icon, size: 16, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(color: statusColor),
                ),
              ],
            ),
            if (expiresAt != null) ...[
              const SizedBox(height: 4),
              Text(
                isExpiringSoon
                    ? 'Expires soon: ${_formatDate(expiresAt!)}'
                    : 'Expires: ${_formatDate(expiresAt!)}',
                style: TextStyle(
                  color: isExpiringSoon ? colorScheme.error : colorScheme.onSurfaceVariant,
                  fontWeight: isExpiringSoon ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                reason!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          onTap != null ? Icons.chevron_right : Icons.info_outline,
          color: colorScheme.outline,
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

