import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';

/// Screen 6 — Location picker.
///
/// Reused for both "From"/"To" on the search form (rider) and on
/// Create Trip (driver). Typing hits the real `GET /locations/search`,
/// which matches on either the point's own name or its city's name —
/// typing "Yaoundé" surfaces every point inside it, typing "Emana"
/// finds that point directly.
///
/// Returns a real [LocationResult] (with a real `id`), never a bare
/// string — trip creation needs that id for `departure_location_id`/
/// `destination_location_id`, so nothing here can be a free-text
/// guess. Tapping a "popular city" just pre-fills the search box and
/// runs a real search rather than resolving to a fake selection.
class LocationPickerScreen extends StatefulWidget {
  final String title;
  const LocationPickerScreen({super.key, required this.title});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final _controller = TextEditingController();
  List<LocationResult> _results = [];
  bool _loading = false;
  Timer? _debounce;

  static const List<String> _popularCities = [
    'Yaoundé',
    'Douala',
    'Buea',
    'Bafoussam',
  ];

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    setState(() => _loading = true);
    try {
      final results = await LocationService.instance.search(value);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/search/location_picker_screen.dart: $e');
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _tapPopularCity(String city) {
    _controller.text = city;
    setState(() {});
    _search(city);
  }

  void _selectLocation(LocationResult loc) => Navigator.of(context).pop(loc);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(widget.title)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              decoration: const InputDecoration(
                hintText: 'Search city or pickup point',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _controller.text.trim().isEmpty
                  ? _buildPopularCities()
                  : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularCities() {
    return ListView(
      children: [
        const Text('Popular cities',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        ..._popularCities.map(
          (c) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.location_city, color: AppColors.primary),
            title: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => _tapPopularCity(c),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text('No matching locations.', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final loc = _results[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
          title: Text(loc.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(loc.cityName),
          onTap: () => _selectLocation(loc),
        );
      },
    );
  }
}
