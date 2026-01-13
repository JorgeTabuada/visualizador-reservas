import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatsCards extends StatelessWidget {
  const StatsCards({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Obter dados reais das estatísticas
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Mês',
                value: '€ 12.450,00',
                subtitle: '+12% vs mês anterior',
                icon: Icons.trending_up,
                iconColor: AppTheme.successColor,
                backgroundColor: AppTheme.successColor.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Pendentes',
                value: '8',
                subtitle: '€ 2.340,00',
                icon: Icons.pending_actions,
                iconColor: AppTheme.warningColor,
                backgroundColor: AppTheme.warningColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Aprovadas',
                value: '45',
                subtitle: 'Este mês',
                icon: Icons.check_circle_outline,
                iconColor: AppTheme.primaryColor,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Vencidas',
                value: '3',
                subtitle: 'Ação necessária',
                icon: Icons.warning_amber,
                iconColor: AppTheme.errorColor,
                backgroundColor: AppTheme.errorColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
