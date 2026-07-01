import 'package:flutter/material.dart';
import '../../models/trip.dart';
import '../../services/trip_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/trip_card.dart';
import '../../widgets/profile_icon_button.dart';
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
        _error = "Couldn't load trips. Pull down to try again.";
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${widget.date.day} ${months[widget.date.month - 1]} ${widget.date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
                  '$_dateLabel · ${widget.passengers} passenger${widget.passengers > 1 ? 's' : ''}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                PopupMenuButton<_SortBy>(
                  initialValue: _sortBy,
                  onSelected: (v) => setState(() => _sortBy = v),
                  child: Row(
                    children: [
                      Text(
                        _sortBy == _SortBy.time ? 'Time' : 'Price',
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 18),
                    ],
                  ),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: _SortBy.time, child: Text('Sort by time')),
                    PopupMenuItem(value: _SortBy.price, child: Text('Sort by price')),
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
          children: const [
            SizedBox(height: 80),
            Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'No trips on this route and date yet. Try another date, or be among our first riders to request it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
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
