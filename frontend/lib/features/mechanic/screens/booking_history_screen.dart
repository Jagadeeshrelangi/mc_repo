import 'package:flutter/material.dart';
import 'package:mecha_connect/features/mechanic/models/models.dart';
import 'package:mecha_connect/features/mechanic/providers/mechanic_provider.dart';
import 'package:mecha_connect/features/mechanic/screens/live_tracking_screen.dart';
import 'package:mecha_connect/features/mechanic/widgets/booking_history_card.dart';
import 'package:mecha_connect/features/mechanic/widgets/service_chip.dart';
import 'package:mecha_connect/theme/app_colors.dart';
import 'package:mecha_connect/theme/app_responsive.dart';
import 'package:mecha_connect/theme/app_spacing.dart';
import 'package:mecha_connect/theme/app_theme_helpers.dart';
import 'package:provider/provider.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String _statusFilter = 'All';

  final List<String> _filters = ['All', 'Active', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<MechanicProvider>().loadBookingHistory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Booking> get _filteredBookings {
    final provider = context.watch<MechanicProvider>();
    var list = List<Booking>.from(provider.bookingHistory);

    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isNotEmpty) {
      list =
          list.where((b) {
            return b.bookingId.toLowerCase().contains(normalizedQuery) ||
                b.mechanic.name.toLowerCase().contains(normalizedQuery) ||
                b.service.name.toLowerCase().contains(normalizedQuery) ||
                b.vehicle.toLowerCase().contains(normalizedQuery);
          }).toList();
    }

    switch (_statusFilter) {
      case 'Active':
        list =
            list
                .where(
                  (b) =>
                      b.status != BookingStatus.completed &&
                      b.status != BookingStatus.cancelled,
                )
                .toList();
        break;
      case 'Completed':
        list = list.where((b) => b.status == BookingStatus.completed).toList();
        break;
      case 'Cancelled':
        list = list.where((b) => b.status == BookingStatus.cancelled).toList();
        break;
    }

    list.sort((a, b) => b.bookingTime.compareTo(a.bookingTime));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filteredBookings;
    return Scaffold(
      backgroundColor: context.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Booking History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Space Grotesk',
            color: context.textPrimary,
          ),
        ),
      ),
      body: ConstrainedContent(
        child: Column(
          children: [
            _buildSearchBar(context),
            _buildFilterBar(context),
            Expanded(
              child:
                  bookings.isEmpty
                      ? _buildEmptyState(context)
                      : _buildList(context, bookings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppResponsive.horizontalPadding(context),
        AppSpacing.sm,
        AppResponsive.horizontalPadding(context),
        0,
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: context.border),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _query = v),
          decoration: InputDecoration(
            hintText: 'Search by mechanic, service, ID...',
            hintStyle: TextStyle(fontSize: 13, color: context.textTertiary),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: context.textTertiary,
              size: 20,
            ),
            suffixIcon:
                _query.isNotEmpty
                    ? IconButton(
                      tooltip: 'Clear search',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.textTertiary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      color: context.bgSecondary,
      padding: EdgeInsets.fromLTRB(
        AppResponsive.horizontalPadding(context),
        AppSpacing.sm,
        AppResponsive.horizontalPadding(context),
        AppSpacing.base,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              _filters.map((f) {
                final isActive = _statusFilter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ServiceChip(
                    label: f,
                    icon: _iconForFilter(f),
                    isSelected: isActive,
                    onTap: () => setState(() => _statusFilter = f),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  IconData? _iconForFilter(String filter) {
    switch (filter) {
      case 'All':
        return Icons.list_rounded;
      case 'Active':
        return Icons.bolt_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return null;
    }
  }

  Widget _buildList(BuildContext context, List<Booking> bookings) {
    return RefreshIndicator(
      onRefresh: () => context.read<MechanicProvider>().loadBookingHistory(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppResponsive.horizontalPadding(context)),
        itemCount: bookings.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return BookingHistoryCard(
            booking: booking,
            onTap: () => _openBooking(context, booking),
          );
        },
      ),
    );
  }

  void _openBooking(BuildContext context, Booking booking) {
    if (booking.status == BookingStatus.completed ||
        booking.status == BookingStatus.cancelled) {
      _showDetailsSheet(context, booking);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(bookingId: booking.bookingId),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(ctx).padding.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.textTertiary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Booking ${booking.bookingId}',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Space Grotesk',
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.mechanic.name} • ${booking.service.name}',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vehicle: ${booking.vehicle}',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total: ₹${booking.estimatedCost.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 13, color: context.textSecondary),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final hasFilters = _query.isNotEmpty || _statusFilter != 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.search_off_rounded : Icons.history_rounded,
              size: 64,
              color: context.textTertiary,
            ),
            SizedBox(height: AppSpacing.base),
            Text(
              hasFilters ? 'No matching bookings' : 'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              hasFilters
                  ? 'Try a different search or filter'
                  : 'Book a mechanic to see your history here',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: context.textTertiary),
            ),
            if (hasFilters) ...[
              SizedBox(height: AppSpacing.lg),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _query = '';
                    _statusFilter = 'All';
                  });
                },
                child: Text(
                  'Clear filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandOrange,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
