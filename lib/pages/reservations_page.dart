import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/egg_reservation.dart';
import '../state/app_state.dart';
import '../dialogs/reservation_dialog.dart';
import '../l10n/locale_provider.dart';
import '../widgets/app_drawer.dart';

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final state = Provider.of<AppState>(context);

    final reservations = state.reservations;
    final upcomingReservations = reservations.where((r) {
      if (r.pickupDate == null) return true;
      return DateTime.parse(r.pickupDate!).isAfter(DateTime.now().subtract(const Duration(days: 1)));
    }).toList();
    final pastReservations = reservations.where((r) {
      if (r.pickupDate == null) return false;
      return DateTime.parse(r.pickupDate!).isBefore(DateTime.now());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(locale == 'pt' ? 'Reservas de Ovos' : 'Egg Reservations'),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      drawer: const AppDrawer(),
      body: reservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    locale == 'pt'
                        ? 'Nenhuma reserva encontrada'
                        : 'No reservations found',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    locale == 'pt'
                        ? 'Toque no + para adicionar uma reserva'
                        : 'Tap + to add a reservation',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Upcoming Reservations
                if (upcomingReservations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.upcoming, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'pt' ? 'Reservas Ativas' : 'Active Reservations',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...upcomingReservations.map((reservation) =>
                      _ReservationCard(reservation: reservation, locale: locale)),
                  const SizedBox(height: 24),
                ],
                // Past/Overdue Reservations
                if (pastReservations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.history, color: Colors.orange.shade700),
                      const SizedBox(width: 8),
                      Text(
                        locale == 'pt' ? 'Reservas Atrasadas' : 'Overdue Reservations',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...pastReservations.map((reservation) =>
                      _ReservationCard(reservation: reservation, locale: locale, isOverdue: true)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ReservationDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(locale == 'pt' ? 'Nova Reserva' : 'New Reservation'),
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final EggReservation reservation;
  final String locale;
  final bool isOverdue;

  const _ReservationCard({
    required this.reservation,
    required this.locale,
    this.isOverdue = false,
  });

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    if (locale == 'pt') {
      final months = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isOverdue ? 3 : 1,
      color: isOverdue ? Colors.orange.shade50 : null,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => ReservationDialog(existingReservation: reservation),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isOverdue
                          ? Colors.orange.shade100
                          : theme.colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark,
                      color: isOverdue ? Colors.orange.shade700 : theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.customerName ??
                              (locale == 'pt' ? 'Cliente Anônimo' : 'Anonymous Customer'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reservation.quantity} ${locale == 'pt' ? 'ovos' : 'eggs'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: locale == 'pt' ? 'Converter em Venda' : 'Convert to Sale',
                    onPressed: () => _convertToSale(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    '${locale == 'pt' ? 'Reservado' : 'Reserved'}: ${_formatDate(reservation.date)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              if (reservation.pickupDate != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 16,
                      color: isOverdue ? Colors.orange.shade700 : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${locale == 'pt' ? 'Levantamento' : 'Pickup'}: ${_formatDate(reservation.pickupDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isOverdue ? Colors.orange.shade700 : null,
                        fontWeight: isOverdue ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
              ],
              if (reservation.customerPhone != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Text(
                      reservation.customerPhone!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
              if (reservation.notes != null) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reservation.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _convertToSale(BuildContext context) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(locale == 'pt' ? 'Converter em Venda?' : 'Convert to Sale?'),
        content: Text(
          locale == 'pt'
              ? 'Esta reserva será removida e uma nova venda será criada. Continuar?'
              : 'This reservation will be removed and a new sale will be created. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(locale == 'pt' ? 'Cancelar' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement conversion to sale
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    locale == 'pt'
                        ? 'Funcionalidade em desenvolvimento'
                        : 'Feature under development',
                  ),
                ),
              );
            },
            child: Text(locale == 'pt' ? 'Converter' : 'Convert'),
          ),
        ],
      ),
    );
  }
}
