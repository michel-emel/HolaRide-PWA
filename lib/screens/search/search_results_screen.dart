import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trip_card.dart';
import '../../widgets/profile_icon_button.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/date_labels.dart';
import '../trip/trip_detail_screen.dart';

enum _SortBy { time, price }

/// Screen 8 — Search results.
class SearchResultsScreen extends StatefulWidget {
  final String fromCity;
  final String toCity;
  final DateTime date;
  final int passengers;

  const SearchResultsScreen({
    super.key,
    required this.fromCity,
    required this.toCity,
    required this.date,
    required this.passengers,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Trip> _trips = [];
  bool _loading = true;
  String? _error;
  _SortBy _sortBy = _SortBy.time;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final trips = await TripService.instance.search(
        originCity: widget.fromCity,
        destinationCity: widget.toCity,
        departureDate: widget.date,
      );
      if (!mounted) return;
      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/search/search_results_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _error = AppLocalizations.of(context).searchLoadError;
        _loading = false;
      });
    }
  }

  List<Trip> get _sortedTrips {
    final list = [..._trips];
    if (_sortBy == _SortBy.price) {
      list.sort((a, b) => a.pricePerSeat.compareTo(b.pricePerSeat));
    } else {
      list.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    }
    return list;
  }

  String get _dateLabel {
    return '${widget.date.day} ${monthAbbrev(context, widget.date.month)} ${widget.date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('${widget.fromCity} → ${widget.toCity}'),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: const [ProfileIconButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_dateLabel · ${widget.passengers} ${widget.passengers > 1 ? l.searchResultsPassengerPlural : l.searchResultsPassengerSingular}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                PopupMenuButton<_SortBy>(
                  initialValue: _sortBy,
                  onSelected: (v) => setState(() => _sortBy = v),
                  child: Row(
                    children: [
                      Text(
                        _sortBy == _SortBy.time ? l.searchTimeLabel : l.searchPriceLabel,
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
                    ],
                  ),
                  itemBuilder: (_) => [
                    PopupMenuItem(value: _SortBy.time, child: Text(l.searchSortTime)),
                    PopupMenuItem(value: _SortBy.price, child: Text(l.searchSortPrice)),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(child: Text(_error!, style: const TextStyle(color: AppColors.textSecondary))),
          ],
        ),
      );
    }
    final trips = _sortedTrips;
    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            const SizedBox(height: 80),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  AppLocalizations.of(context).searchNoResults,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: trips.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final trip = trips[i];
          return TripCard(
            trip: trip,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
            ),
          );
        },
      ),
    );
  }
}
