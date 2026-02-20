import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/egg_reservation.dart';
import '../models/egg_sale.dart';
import '../state/providers/providers.dart';
import '../dialogs/reservation_dialog.dart';
import '../l10n/locale_provider.dart';
import '../l10n/translations.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/empty_state.dart';
import '../widgets/gradient_fab.dart';
import '../widgets/search_bar.dart';

class ReservationsPage extends StatefulWidget {
  const ReservationsPage({super.key});

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = Provider.of<LocaleProvider>(context).code;
    final t = (String k) => Translations.of(locale, k);
    final reservationProvider = Provider.of<ReservationProvider>(context);

    final allReservations = reservationProvider.reservations;
    final reservations = _searchQuery.isEmpty
        ? allReservations
        : reservationProvider.search(_searchQuery);
    final today = DateUtils.dateOnly(DateTime.now());
    final upcomingReservations = reservations.where((r) {
      if (r.pickupDate == null) return true;
      return !DateUtils.dateOnly(DateTime.parse(r.pickupDate!)).isBefore(today);
    }).toList();
    final pastReservations = reservations.where((r) {
      if (r.pickupDate == null) return false;
      return DateUtils.dateOnly(DateTime.parse(r.pickupDate!)).isBefore(today);
    }).toList();

    // Loading state
    if (reservationProvider.isLoading && allReservations.isEmpty) {
      return AppScaffold(
        title: t('egg_reservations'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Error state
    if (reservationProvider.hasError && allReservations.isEmpty) {
      return AppScaffold(
        title: t('egg_reservations'),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                t('error_loading_reservations'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => reservationProvider.loadReservations(),
                icon: const Icon(Icons.refresh),
                label: Text(t('try_again')),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: t('egg_reservations'),
      fab: GradientFAB(
        extended: true,
        icon: Icons.add,
        label: t('add_reservation'),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const ReservationDialog(),
          );
        },
      ),
      body: allReservations.isEmpty
          ? ChickenEmptyState(
              title: t('no_reservations'),
              message: t('manage_reservations'),
              actionLabel: t('add_reservation'),
              onAction: () {
                showDialog(
                  context: context,
                  builder: (context) => const ReservationDialog(),
                );
              },
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                // Search Bar
                AppSearchBar(
                  controller: _searchController,
                  hintText: t('search_reservations'),
                  hasContent: _searchQuery.isNotEmpty,
                  onChanged: _onSearchChanged,
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                ),

                // Search empty state
                if (reservations.isEmpty && _searchQuery.isNotEmpty)
                  SearchEmptyState(
                    query: _searchQuery,
                    locale: locale,
                    onClear: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search results indicator
                        if (_searchQuery.isNotEmpty) ...[
                          Text(
                            '${reservations.length} ${t('results')}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Upcoming Reservations
                        if (upcomingReservations.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.upcoming, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                t('active_reservations'),
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
                                t('overdue_reservations'),
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
                  ),
                ],
              ],
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
                          : theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
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
                              Translations.of(locale, 'anonymous_customer'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${reservation.quantity} ${Translations.of(locale, 'eggs')}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: Translations.of(locale, 'convert_to_sale'),
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
                    '${Translations.of(locale, 'reserved')}: ${_formatDate(reservation.date)}',
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
                      '${Translations.of(locale, 'pickup')}: ${_formatDate(reservation.pickupDate!)}',
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

  void _convertToSale(BuildContext context) async {
    final locale = Provider.of<LocaleProvider>(context, listen: false).code;
    final theme = Theme.of(context);

    // Ask for payment status - only Pending and Advance make sense for conversions
    final paymentStatus = await showDialog<PaymentStatus>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Translations.of(locale, 'convert_to_sale')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Translations.of(locale, 'convert_dialog_message'),
            ),
            const SizedBox(height: 16),
            // Only show Pending and Advance options
            ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: Text(PaymentStatus.pending.displayName(locale)),
              subtitle: Text(
                Translations.of(locale, 'payment_pending_desc'),
              ),
              onTap: () => Navigator.pop(context, PaymentStatus.pending),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet, color: Colors.blue),
              title: Text(PaymentStatus.advance.displayName(locale)),
              subtitle: Text(
                Translations.of(locale, 'payment_advance_desc'),
              ),
              onTap: () => Navigator.pop(context, PaymentStatus.advance),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Translations.of(locale, 'cancel')),
          ),
        ],
      ),
    );

    if (paymentStatus == null || !context.mounted) return;

    // Convert to sale
    try {
      final reservationProvider = context.read<ReservationProvider>();
      final saleProvider = context.read<SaleProvider>();
      await reservationProvider.convertReservationToSale(
        reservation,
        paymentStatus,
        saleProvider,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              Translations.of(locale, 'reservation_converted'),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
