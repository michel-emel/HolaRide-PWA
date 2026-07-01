import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'location_picker_screen.dart';
import 'search_results_screen.dart';

/// Screen 7 — Search form.
///
/// Lives as the "Route" tab content for guests (see `main_tab_screen.dart`)
/// and is also reachable from Home's "Find a Ride" tile — same screen
/// either way, so it no longer has its own AppBar (a tab doesn't need
/// one) and instead opens with a header that matches the rest of the
/// app's card-based look.
///
/// "From"/"To" pick a real [LocationResult] from `GET /locations/search`
/// (id + point name + city). Search itself only filters by city though
/// — your backend's `/trips/search` takes `origin_city`/`destination_city`
/// strings, not specific points — so the picked point is shown for
/// context but only its city name is actually sent to the API.
class SearchFormScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;

  const SearchFormScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<SearchFormScreen> createState() => _SearchFormScreenState();
}

class _SearchFormScreenState extends State<SearchFormScreen> {
  LocationResult? _from;
  LocationResult? _to;
  DateTime _date = DateTime.now();
  int _passengers = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    // initialFrom/initialTo (e.g. from Home's "Popular routes") arrive
    // as plain city names — wrap them as a city-only LocationResult so
    // the rest of this screen can treat them the same as a real picker
    // result. There's no specific point in this case, just the city.
    if (widget.initialFrom != null) {
      _from = LocationResult(id: '', name: '', cityId: '', cityName: widget.initialFrom!);
    }
    if (widget.initialTo != null) {
      _to = LocationResult(id: '', name: '', cityId: '', cityName: widget.initialTo!);
    }
  }

  Future<void> _pickFrom() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen(title: 'Leaving from')),
    );
    if (result != null) setState(() {
      _from = result;
      _error = null;
    });
  }

  Future<void> _pickTo() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen(title: 'Going to')),
    );
    if (result != null) setState(() {
      _to = result;
      _error = null;
    });
  }

  void _swap() {
    setState(() {
      final temp = _from;
      _from = _to;
      _to = temp;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_date.day} ${months[_date.month - 1]} ${_date.year}';
  }

  void _search() {
    if (_from == null || _to == null) {
      setState(() => _error = 'Choose where you\'re leaving from and going to.');
      return;
    }
    // HolaRide is intercity only — a same-city "trip" isn't something
    // this product supports, and the backend's search filters by city
    // anyway, so this would just return nothing useful either way.
    if (_from!.cityName.trim().toLowerCase() == _to!.cityName.trim().toLowerCase()) {
      setState(() => _error = 'Departure and destination can\'t be the same city — HolaRide connects different cities.');
      return;
    }
    setState(() => _error = null);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SearchResultsScreen(
          fromCity: _from!.cityName,
          toCity: _to!.cityName,
          date: _date,
          passengers: _passengers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
          children: [
            const Text('Find your route',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(height: 4),
            const Text(
              'Search for a published trip going your way.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withOpacity(0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      Column(
                        children: [
                          _LocationField(
                            label: 'From',
                            value: _from,
                            icon: Icons.radio_button_checked,
                            onTap: _pickFrom,
                          ),
                          const SizedBox(height: 10),
                          _LocationField(
                            label: 'To',
                            value: _to,
                            icon: Icons.location_on,
                            onTap: _pickTo,
                          ),
                        ],
                      ),
                      Positioned(
                        right: 4,
                        child: InkWell(
                          onTap: _swap,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.textPrimary.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.swap_vert, size: 18, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Text(_dateLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 18, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Passengers', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          onPressed: _passengers > 1 ? () => setState(() => _passengers--) : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text('$_passengers', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        IconButton(
                          onPressed: _passengers < 4 ? () => setState(() => _passengers++) : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 16, color: AppColors.danger),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.danger, fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  PrimaryButton(label: 'Search Trips', onPressed: _search),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationField extends StatelessWidget {
  final String label;
  final LocationResult? value;
  final IconData icon;
  final VoidCallback onTap;

  const _LocationField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                  Text(
                    value?.label ?? 'Select location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: value == null ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}