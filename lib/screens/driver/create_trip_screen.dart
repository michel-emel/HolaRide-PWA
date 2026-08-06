import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/date_labels.dart';
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
/// Price per seat defaults to the admin-suggested price for the route +
/// vehicle category — fetched live via `GET /trips/price-preview` as
/// soon as both locations and the vehicle are known (reusing the exact
/// same pricing lookup `createTrip` ends up using server-side, so the
/// suggestion can never drift out of sync with the admin default).
///
/// The driver can then adjust that suggestion for THIS trip only, in
/// multiples of 500 XAF between 1500 and 10000 — via the −500/+500
/// buttons or by typing a value directly (rounded up to the nearest 500
/// on blur/publish, client-side, purely for feedback). The backend is
/// the actual authority: it re-rounds and re-bounds whatever's sent and
/// rejects anything invalid, so this screen's rounding is a convenience,
/// never the source of truth. The admin's route pricing itself is never
/// modified — only this one trip's snapshot.
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

  // Driver's adjustment on top of the admin-suggested price, for THIS
  // trip only. Pre-filled with the (rounded) admin suggestion as soon
  // as it loads, and stays whatever's currently shown in the field —
  // that's always what gets published. Only stays null if the price
  // lookup never succeeded AND the driver never typed anything either,
  // in which case nothing is sent and the backend falls back to the
  // raw admin price, exactly like before this feature existed.
  int? _selectedPrice;
  String? _priceFieldError;
  final _priceController = TextEditingController();
  final _priceFocusNode = FocusNode();

  static const int _minPrice = 1500;
  static const int _maxPrice = 10000;
  static const int _priceStep = 500;

  int get _maxSeats => _vehicle?.totalSeats ?? 8;

  @override
  void initState() {
    super.initState();
    _priceFocusNode.addListener(() {
      if (!_priceFocusNode.hasFocus) _commitTypedPrice(_priceController.text);
    });
    _loadVehicle();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocusNode.dispose();
    super.dispose();
  }

  int _roundUpToStep(num v) {
    final rounded = (v / _priceStep).ceil() * _priceStep;
    return rounded < 0 ? 0 : rounded;
  }

  void _adjustPrice(int delta) {
    final base = _selectedPrice ?? _roundUpToStep(_pricePreview ?? _minPrice);
    final next = (base + delta).clamp(_minPrice, _maxPrice);
    setState(() {
      _selectedPrice = next;
      _priceFieldError = null;
      _priceController.text = next.toString();
    });
  }

  /// Commits whatever's currently typed in the price field: rounds up
  /// to the nearest 500, then flags an error (without silently
  /// substituting a different number) if that's still out of bounds —
  /// mirrors the backend's own round-then-reject logic so the two never
  /// disagree about what's valid. An empty field is left alone (no
  /// error) — that only happens when the price lookup itself never
  /// succeeded and the driver hasn't typed anything, in which case
  /// publish just falls back to the admin price, same as today.
  void _commitTypedPrice(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final parsed = num.tryParse(trimmed);
    if (parsed == null) {
      setState(() => _priceFieldError = AppLocalizations.of(context).createTripPriceInvalid);
      return;
    }
    final rounded = _roundUpToStep(parsed);
    if (rounded < _minPrice || rounded > _maxPrice) {
      setState(() {
        _priceFieldError = AppLocalizations.of(context).createTripPriceOutOfRange;
      });
      return;
    }
    setState(() {
      _selectedPrice = rounded;
      _priceFieldError = null;
      _priceController.text = rounded.toString();
    });
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

  /// Resets the driver's price adjustment back to the (rounded) admin
  /// suggestion — called whenever the route changes and a fresh
  /// suggestion comes in, since an adjustment made for a different
  /// route doesn't mean anything here.
  void _resetPriceAdjustment(num? suggested) {
    _priceFieldError = null;
    if (suggested == null) {
      _selectedPrice = null;
      _priceController.text = '';
    } else {
      _selectedPrice = _roundUpToStep(suggested).clamp(_minPrice, _maxPrice);
      _priceController.text = _selectedPrice.toString();
    }
  }

  Future<void> _updatePricePreview() async {
    if (_from == null || _to == null || _vehicle == null) {
      setState(() {
        _pricePreview = null;
        _priceError = null;
        _resetPriceAdjustment(null);
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
        _resetPriceAdjustment(price);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _pricePreview = null;
        _priceError = e.message;
        _loadingPrice = false;
        _resetPriceAdjustment(null);
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error in lib/screens/driver/create_trip_screen.dart: $e');
      if (!mounted) return;
      setState(() {
        _pricePreview = null;
        _priceError = AppLocalizations.of(context).createTripNoPriceError;
        _loadingPrice = false;
        _resetPriceAdjustment(null);
      });
    }
  }

  Future<void> _pickFrom() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(title: AppLocalizations.of(context).createTripLeavingFrom)),
    );
    if (result != null) {
      setState(() => _from = result);
      _updatePricePreview();
    }
  }

  Future<void> _pickTo() async {
    final result = await Navigator.of(context).push<LocationResult>(
      MaterialPageRoute(builder: (_) => LocationPickerScreen(title: AppLocalizations.of(context).createTripGoingTo)),
    );
    if (result != null) {
      setState(() => _to = result);
      _updatePricePreview();
    }
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
    return '${_date.day} ${monthAbbrev(context, _date.month)} ${_date.year}';
  }

  String get _timeLabel =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _publish() async {
    if (_from == null || _to == null) {
      setState(() => _error = AppLocalizations.of(context).createTripLocationHint);
      return;
    }
    if (_vehicle == null) {
      setState(() => _error = AppLocalizations.of(context).createTripNoVehicle);
      return;
    }
    // Commit whatever's currently typed (in case the driver edited the
    // field but never lost focus) before deciding what to publish with.
    _commitTypedPrice(_priceController.text);
    if (_priceFieldError != null) {
      setState(() => _error = _priceFieldError);
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
        pricePerSeat: _selectedPrice,
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
      setState(() => _error = AppLocalizations.of(context).createTripPublishError);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: Text(l.createTripTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _locationField(label: l.createTripFrom, value: _from, icon: Icons.radio_button_checked, onTap: _pickFrom),
          const SizedBox(height: 10),
          _locationField(label: l.createTripTo, value: _to, icon: Icons.location_on, onTap: _pickTo),
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
                              Text(l.createTripDate, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                              Text(l.createTripDeparture,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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
                      Text(l.createTripSeats, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (_vehicle != null)
                        Text(l.createTripSeatsHint(_maxSeats),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.payments_outlined, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.createTripPrice, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
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
                      else if (_selectedPrice == null)
                        Text(
                          l.createTripPriceHint,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                        )
                      else
                        Row(
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _selectedPrice! > _minPrice ? () => _adjustPrice(-_priceStep) : null,
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 96,
                              child: TextField(
                                controller: _priceController,
                                focusNode: _priceFocusNode,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.primary),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (_) {
                                  if (_priceFieldError != null) setState(() => _priceFieldError = null);
                                },
                                onSubmitted: _commitTypedPrice,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _selectedPrice! < _maxPrice ? () => _adjustPrice(_priceStep) : null,
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                            const SizedBox(width: 6),
                            const Text('XAF', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      if (_priceFieldError != null) ...[
                        const SizedBox(height: 4),
                        Text(_priceFieldError!,
                            style: const TextStyle(fontSize: 12, color: AppColors.danger)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              l.createTripPriceNote,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          PrimaryButton(
            label: l.createTripPublish,
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
                    value?.label ?? AppLocalizations.of(context).createTripSelectLocation,
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