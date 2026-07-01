import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../models/vehicle.dart';
import '../../services/api_client.dart';
import '../../services/driver_service.dart';
import '../../services/vehicle_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../search/location_picker_screen.dart';
import 'my_trips_screen.dart';

/// Screen 19 — Create a trip.
///
/// Price per seat is never editable here — it's entirely admin-set,
/// based on route and vehicle category, and the backend snapshots it
/// at creation time. A live preview now shows as soon as both
/// locations and the vehicle are known, via a `GET /trips/price-preview`
/// endpoint added to the backend specifically for this — it reuses the
/// exact same pricing lookup `createTrip` ends up using, so the preview
/// can never drift out of sync with what publishing would actually charge.
///
/// "From"/"To" pick a real [LocationResult] (with a real id) from
/// `GET /locations/search`, not a free-text city string — the real
/// `TripCreate` schema needs `departure_location_id`/
/// `destination_location_id`, actual location UUIDs.
///
/// "Available seats" here is a separate number from the vehicle's
/// total seats set at registration — that's the car's fixed physical
/// capacity; this is how many of those seats you're offering on this
/// one trip, capped at that capacity so you can't publish more seats
/// than the car actually has.
class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  LocationResult? _from;
  LocationResult? _to;
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _seats = 3;
  Vehicle? _vehicle;
  bool _loadingVehicle = true;
  bool _submitting = false;
  String? _error;

  num? _pricePreview;
  bool _loadingPrice = false;
  String? _priceError;

  int get _maxSeats => _vehicle?.totalSeats ?? 8;

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  Future<void> _loadVehicle() async {
    try {
      final vehicle = await VehicleService.instance.getMyVehicle();
      if (!mounted) return;
      setState(() {
        _vehicle = vehicle;
        if (vehicle != null && _seats > vehicle.totalSeats) {
          _seats = vehicle.totalSeats;
        }
        _loadingVehicle = false;
      });
      _updatePricePreview();
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/create_trip_screen.dart: $e');
      if (!mounted) return;
      setState(() => _loadingVehicle = false);
    }
  }

  Future<void> _updatePricePreview() async {
    if (_from == null || _to == null || _vehicle == null) {
      setState(() {
        _pricePreview = null;
        _priceError = null;
      });
      return;
    }
    setState(() {
      _loadingPrice = true;
      _priceError = null;
    });
    try {
      final price = await DriverService.instance.previewPrice(
        vehicleId: _vehicle!.id,
        departureLocationId: _from!.id,
        destinationLocationId: _to!.id,
      );
      if (!mounted) return;
      setState(() {
        _pricePreview = price;
        _loadingPrice = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _pricePreview = null;
        _priceError = e.message;
        _loadingPrice = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/create_trip_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _pricePreview = null;
        _priceError = "Couldn't load a price for this route.";
        _loadingPrice = false;
      });
    }
  }

  Future<void> _pickFrom() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen(title: 'Leaving from')),
    );
    if (result != null) {
      setState(() => _from = result);
      _updatePricePreview();
    }
  }

  Future<void> _pickTo() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => const LocationPickerScreen(title: 'Going to')),
    );
    if (result != null) {
      setState(() => _to = result);
      _updatePricePreview();
    }
  }

  String _money(num v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf XAF';
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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  String get _dateLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${_date.day} ${months[_date.month - 1]} ${_date.year}';
  }

  String get _timeLabel =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _publish() async {
    if (_from == null || _to == null) {
      setState(() => _error = 'Choose where you\'re leaving from and going to.');
      return;
    }
    if (_vehicle == null) {
      setState(() => _error = 'No approved vehicle found on your account — check My Vehicle in Profile.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await DriverService.instance.createTrip(
        departureLocationId: _from!.id,
        destinationLocationId: _to!.id,
        departureDate: _date,
        departureHour: _time.hour,
        departureMinute: _time.minute,
        availableSeats: _seats,
        vehicleId: _vehicle!.id,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MyTripsScreen()),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/create_trip_screen.dart: $e');
      setState(() => _error = 'Could not publish this trip. Try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Create a trip')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _locationField(label: 'From', value: _from, icon: Icons.radio_button_checked, onTap: _pickFrom),
          const SizedBox(height: 10),
          _locationField(label: 'To', value: _to, icon: Icons.location_on, onTap: _pickTo),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 17, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Date', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(_dateLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 17, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Departure time',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text(_timeLabel, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.event_seat_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available seats', style: TextStyle(fontWeight: FontWeight.w600)),
                      if (_vehicle != null)
                        Text('Up to $_maxSeats — your vehicle\'s registered capacity',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _seats > 1 ? () => setState(() => _seats--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_seats', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                IconButton(
                  onPressed: _seats < _maxSeats ? () => setState(() => _seats++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Price per seat', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (_loadingPrice)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else if (_priceError != null)
                        Text(_priceError!,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.danger))
                      else if (_pricePreview != null)
                        Text(
                          _money(_pricePreview!),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                        )
                      else
                        const Text(
                          'Pick "From" and "To" to see the price',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Set by HolaRide based on your route and vehicle category — drivers don\'t set prices.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Publish Trip',
            onPressed: _loadingVehicle ? null : _publish,
            loading: _submitting || _loadingVehicle,
          ),
        ],
      ),
    );
  }

  Widget _locationField({
    required String label,
    required LocationResult? value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
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