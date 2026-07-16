import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import 'search_results_screen.dart';

/// Screen 7 — "Find your ride" search screen.
/// Hero illustration + route card + date card + quick routes + trust badges.
class SearchFormScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  const SearchFormScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<SearchFormScreen> createState() => _SearchFormScreenState();
}

class _SearchFormScreenState extends State<SearchFormScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFE8A838);

  // Fixed list of popular corridors (hard-coded on purpose).
  static const _quickRoutes = <List<String>>[
    ['Douala', 'Yaoundé'],
    ['Yaoundé', 'Bafoussam'],
    ['Douala', 'Limbe'],
    ['Yaoundé', 'Douala'],
    ['Bafoussam', 'Douala'],
  ];

  final _fromCtrl  = TextEditingController();
  final _toCtrl    = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus   = FocusNode();

  LocationResult? _from;
  LocationResult? _to;

  List<LocationResult> _fromResults = [];
  List<LocationResult> _toResults   = [];
  bool _fromLoading = false;
  bool _toLoading   = false;
  bool _showFromDrop = false;
  bool _showToDrop   = false;

  Timer? _fromDebounce;
  Timer? _toDebounce;
  DateTime _date = DateTime.now();
  String? _error;
  late AnimationController _swapCtrl;

  @override
  void initState() {
    super.initState();
    _swapCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    if (widget.initialFrom != null) {
      _fromCtrl.text = widget.initialFrom!;
      _from = LocationResult(id: '', name: widget.initialFrom!, cityId: '', cityName: widget.initialFrom!);
    }
    if (widget.initialTo != null) {
      _toCtrl.text = widget.initialTo!;
      _to = LocationResult(id: '', name: widget.initialTo!, cityId: '', cityName: widget.initialTo!);
    }
    _fromFocus.addListener(() {
      if (mounted) setState(() {});
      if (!_fromFocus.hasFocus) Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showFromDrop = false);
      });
    });
    _toFocus.addListener(() {
      if (mounted) setState(() {});
      if (!_toFocus.hasFocus) Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showToDrop = false);
      });
    });
  }

  @override
  void dispose() {
    _swapCtrl.dispose();
    _fromCtrl.dispose(); _toCtrl.dispose();
    _fromFocus.dispose(); _toFocus.dispose();
    _fromDebounce?.cancel(); _toDebounce?.cancel();
    super.dispose();
  }

  // ── Search logic (unchanged) ──────────────────────────────────────────

  void _searchFrom(String v) {
    _from = null;
    _fromDebounce?.cancel();
    if (v.trim().isEmpty) { setState(() { _fromResults = []; _showFromDrop = false; }); return; }
    _fromDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _fromLoading = true);
      try {
        final r = await LocationService.instance.search(v);
        if (mounted) setState(() { _fromResults = r; _fromLoading = false; _showFromDrop = r.isNotEmpty; });
      } catch (_) { if (mounted) setState(() => _fromLoading = false); }
    });
  }

  void _searchTo(String v) {
    _to = null;
    _toDebounce?.cancel();
    if (v.trim().isEmpty) { setState(() { _toResults = []; _showToDrop = false; }); return; }
    _toDebounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted) return;
      setState(() => _toLoading = true);
      try {
        final r = await LocationService.instance.search(v);
        final dep = _from?.cityName.trim().toLowerCase() ?? '';
        final filtered = dep.isEmpty ? r : r.where((l) => l.cityName.trim().toLowerCase() != dep).toList();
        if (mounted) setState(() { _toResults = filtered; _toLoading = false; _showToDrop = filtered.isNotEmpty; });
      } catch (_) { if (mounted) setState(() => _toLoading = false); }
    });
  }

  void _selectFrom(LocationResult loc) {
    setState(() {
      _from = loc; _fromCtrl.text = loc.label;
      _showFromDrop = false; _error = null;
      if (_to != null && _to!.cityName.trim().toLowerCase() == loc.cityName.trim().toLowerCase()) {
        _to = null; _toCtrl.clear();
      }
    });
    _fromFocus.unfocus();
    Future.delayed(const Duration(milliseconds: 100), () => _toFocus.requestFocus());
  }

  void _selectTo(LocationResult loc) {
    setState(() { _to = loc; _toCtrl.text = loc.label; _showToDrop = false; _error = null; });
    _toFocus.unfocus();
  }

  void _swap() {
    _swapCtrl.forward(from: 0);
    setState(() {
      final tl = _from; _from = _to; _to = tl;
      final tt = _fromCtrl.text; _fromCtrl.text = _toCtrl.text; _toCtrl.text = tt;
    });
  }

  void _applyQuickRoute(String from, String to) {
    FocusScope.of(context).unfocus();
    setState(() {
      _from = LocationResult(id: '', name: from, cityId: '', cityName: from);
      _to   = LocationResult(id: '', name: to,   cityId: '', cityName: to);
      _fromCtrl.text = from;
      _toCtrl.text   = to;
      _fromResults = []; _toResults = [];
      _showFromDrop = false; _showToDrop = false;
      _error = null;
    });
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context, initialDate: _date,
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (p != null) setState(() => _date = p);
  }

  String get _dateLabel {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final now = DateTime.now();
    if (_date.day == now.day && _date.month == now.month && _date.year == now.year) return 'Today, ${_date.day} ${m[_date.month-1]}';
    final tom = now.add(const Duration(days: 1));
    if (_date.day == tom.day && _date.month == tom.month && _date.year == tom.year) return 'Tomorrow, ${_date.day} ${m[_date.month-1]}';
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wd[_date.weekday-1]} ${_date.day} ${m[_date.month-1]} ${_date.year}';
  }

  void _search() {
    if (_from == null || _to == null) {
      setState(() => _error = 'Please select both departure and destination.');
      return;
    }
    if (_from!.cityName.trim().toLowerCase() == _to!.cityName.trim().toLowerCase()) {
      setState(() => _error = 'Departure and destination must be different cities.');
      return;
    }
    setState(() => _error = null);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SearchResultsScreen(fromCity: _from!.cityName, toCity: _to!.cityName, date: _date, passengers: 1),
    ));
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.arrow_back, color: AppColors.primary, size: 20),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [

            // ── Hero: title + illustration ──────────────────────
            SizedBox(
              height: 168,
              child: Stack(
                children: [
                  // Illustration on the right — blurred, edges feathered
                  // so it melts into the background (no visible rectangle)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: .70,
                        heightFactor: 1,
                        child: ShaderMask(
                          shaderCallback: (rect) => const RadialGradient(
                            center: Alignment(0.25, 0),
                            radius: 0.95,
                            colors: [Colors.white, Colors.white, Colors.transparent],
                            stops: [0, .62, 1],
                          ).createShader(rect),
                          blendMode: BlendMode.dstIn,
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                            child: Image.asset(
                              'assets/images/hero_road.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Soft fade so the title stays readable
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            AppColors.background,
                            AppColors.background.withOpacity(.85),
                            AppColors.background.withOpacity(0),
                          ],
                          stops: const [0, .42, .82],
                        ),
                      ),
                    ),
                  ),
                  // Title + subtitle
                  Positioned(
                    left: 4, top: 18,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 230),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, height: 1.05),
                              children: [
                                TextSpan(text: 'Find ', style: TextStyle(color: AppColors.textPrimary)),
                                TextSpan(text: 'your ride', style: TextStyle(color: AppColors.primary)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Find comfortable rides\nbetween cities.',
                            style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ── Route card ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.06), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Stack(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left rail: bubble → dashed line → bubble
                        SizedBox(
                          width: 44,
                          child: Column(
                            children: [
                              const SizedBox(height: 22),
                              const _RailBubble(
                                icon: Icons.radio_button_unchecked,
                                color: AppColors.primary,
                              ),
                              Expanded(
                                child: CustomPaint(
                                  size: const Size(2, double.infinity),
                                  painter: _DashedLinePainter(color: AppColors.border),
                                ),
                              ),
                              const _RailBubble(
                                icon: Icons.location_on,
                                color: _gold,
                              ),
                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Fields
                        Expanded(
                          child: Column(
                            children: [
                              _BoxedField(
                                label: 'Leaving from',
                                hint: 'City or pickup point',
                                controller: _fromCtrl,
                                focusNode: _fromFocus,
                                loading: _fromLoading,
                                isFilled: _from != null,
                                isActive: _fromFocus.hasFocus,
                                onChanged: _searchFrom,
                                onClear: () => setState(() {
                                  _from = null; _fromCtrl.clear(); _fromResults = []; _showFromDrop = false;
                                }),
                              ),
                              const SizedBox(height: 26),
                              _BoxedField(
                                label: 'Going to',
                                hint: 'City or drop-off point',
                                controller: _toCtrl,
                                focusNode: _toFocus,
                                loading: _toLoading,
                                isFilled: _to != null,
                                isActive: _toFocus.hasFocus,
                                onChanged: _searchTo,
                                onClear: () => setState(() {
                                  _to = null; _toCtrl.clear(); _toResults = []; _showToDrop = false;
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 50),
                      ],
                    ),
                  ),

                  // Swap button — right side, vertically centered
                  Positioned(
                    right: 0, top: 0, bottom: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _swap,
                        child: RotationTransition(
                          turns: Tween(begin: 0.0, end: 1.0).animate(
                              CurvedAnimation(parent: _swapCtrl, curve: Curves.easeInOut)),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.infoBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(.15)),
                            ),
                            child: const Icon(Icons.swap_vert, color: AppColors.primary, size: 22),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // FROM dropdown
            if (_showFromDrop && _fromResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DropdownList(results: _fromResults, onSelect: _selectFrom),
            ],

            // TO dropdown
            if (_showToDrop && _toResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DropdownList(results: _toResults, onSelect: _selectTo),
            ],

            const SizedBox(height: 12),

            // ── Date card ───────────────────────────────────────
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Departure date',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_dateLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                  ]),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.infoBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Change', style: TextStyle(fontSize: 12.5, color: AppColors.primary, fontWeight: FontWeight.w700)),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                    ]),
                  ),
                ]),
              ),
            ),

            // ── Error ───────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withOpacity(.2)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13, fontWeight: FontWeight.w500))),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // ── Find Available Rides button ─────────────────────
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 8))],
              ),
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: _search,
                  borderRadius: BorderRadius.circular(18),
                  child: const Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Find Available Rides',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        SizedBox(width: 10),
                        Icon(Icons.search, color: Colors.white, size: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 26),

            // ── Quick Routes ────────────────────────────────────
            const Row(children: [
              Icon(Icons.bolt, color: AppColors.primary, size: 20),
              SizedBox(width: 6),
              Text('Quick Routes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ]),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.only(left: 26),
              child: Text('Tap a route to fill your search instantly.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 46,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _quickRoutes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final r = _quickRoutes[i];
                  return _QuickRouteChip(
                    from: r[0],
                    to: r[1],
                    onTap: () => _applyQuickRoute(r[0], r[1]),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // ── Trust badges ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                const Expanded(child: _TrustItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Secure payments',
                  subtitle: 'Your data is protected',
                )),
                Container(width: 1, height: 44, color: AppColors.border.withOpacity(.6)),
                const Expanded(child: _TrustItem(
                  icon: Icons.groups_outlined,
                  title: 'Trusted community',
                  subtitle: 'Verified drivers',
                )),
                Container(width: 1, height: 44, color: AppColors.border.withOpacity(.6)),
                const Expanded(child: _TrustItem(
                  icon: Icons.headset_mic_outlined,
                  title: '24/7 Support',
                  subtitle: "We're here for you",
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rail bubble (circle with icon, left of the fields) ─────────────────
class _RailBubble extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _RailBubble({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withOpacity(.8)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

// ── Dashed vertical line ────────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0, gap = 5.0;
    final x = size.width / 2;
    double y = 4;
    while (y < size.height - 4) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + dash).clamp(0, size.height - 4)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

// ── Boxed field (bordered input like the mockup) ────────────────────────
class _BoxedField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final bool isFilled;
  final bool isActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _BoxedField({
    required this.label, required this.hint,
    required this.controller, required this.focusNode,
    required this.loading, required this.isFilled,
    required this.isActive,
    required this.onChanged, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: .2,
          color: isActive ? AppColors.primary : AppColors.textSecondary,
        )),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? AppColors.primary : AppColors.border,
              width: isActive ? 1.6 : 1,
            ),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: isFilled ? FontWeight.w700 : FontWeight.w400,
                  color: isFilled ? AppColors.textPrimary : AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w400),
                  border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (loading)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
            else if (controller.text.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: Icon(Icons.cancel_rounded, size: 20, color: AppColors.textSecondary.withOpacity(.5)),
              )
            else
              Icon(Icons.my_location_outlined, size: 18, color: AppColors.textSecondary.withOpacity(.5)),
          ]),
        ),
      ],
    );
  }
}

// ── Quick route chip ─────────────────────────────────────────────────────
class _QuickRouteChip extends StatelessWidget {
  final String from;
  final String to;
  final VoidCallback onTap;
  const _QuickRouteChip({required this.from, required this.to, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.infoBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(.12)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.route_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('$from ↔ $to',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
      ),
    );
  }
}

// ── Trust badge item ─────────────────────────────────────────────────────
class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _TrustItem({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, size: 22, color: AppColors.primary),
      const SizedBox(height: 6),
      Text(title, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      const SizedBox(height: 2),
      Text(subtitle, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
    ]);
  }
}

// ── Dropdown results ─────────────────────────────────────────────────────
class _DropdownList extends StatelessWidget {
  final List<LocationResult> results;
  final ValueChanged<LocationResult> onSelect;
  const _DropdownList({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = results.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(.07), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key; final loc = e.value; final isLast = i == items.length - 1;
          return Column(children: [
            InkWell(
              onTap: () => onSelect(loc),
              borderRadius: BorderRadius.vertical(
                top: i == 0 ? const Radius.circular(16) : Radius.zero,
                bottom: isLast ? const Radius.circular(16) : Radius.zero,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.infoBg, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.cityName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                      if (loc.name.isNotEmpty && loc.name != loc.cityName)
                        Text(loc.name,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                    ],
                  )),
                  const Icon(Icons.north_west, size: 14, color: AppColors.textSecondary),
                ]),
              ),
            ),
            if (!isLast) Divider(height: 1, color: AppColors.border.withOpacity(.5), indent: 64),
          ]);
        }).toList(),
      ),
    );
  }
}