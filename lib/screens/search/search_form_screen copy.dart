import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/location.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import 'search_results_screen.dart';

/// Screen 7 — "Find your ride" search screen.
/// Hero illustration + route card + date card + quick routes.
class SearchFormScreen extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  const SearchFormScreen({super.key, this.initialFrom, this.initialTo});

  @override
  State<SearchFormScreen> createState() => _SearchFormScreenState();
}



class _RailDot extends StatelessWidget {
  final Color color;
  final bool filled;
  final IconData? icon;
  const _RailDot({required this.color, required this.filled, this.icon});

  @override
  Widget build(BuildContext context) {
    if (!filled) {
      // Outlined ring — departure point
      return Container(
        width: 18, height: 18,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.5),
        ),
      );
    }
    // Filled pin — destination point
    return Container(
      width: 26, height: 26,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Icon(icon, size: 15, color: Colors.white),
    );
  }
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

  // Anchors used to position the floating dropdown under the right field.
  final _fromLink = LayerLink();
  final _toLink   = LayerLink();

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

  // ── Search logic ──────────────────────────────────────────

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
    final screenWidth = MediaQuery.of(context).size.width;
    // Card padding (18) + ListView padding (16) on each side = 34 total left/right.
    final dropdownWidth = screenWidth - 32;

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
      body: Stack(
        children: [
          // ── Scrollable content ─────────────────────────────
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [

                // ── Hero: title + illustration ──────────────────────
                SizedBox(
                  height: 168,
                  child: Stack(
                    children: [
                      // Illustration on the right — with fade-out edges
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: FractionallySizedBox(
                            widthFactor: .62,
                            heightFactor: .92,
                            child: ShaderMask(
                              shaderCallback: (rect) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.transparent, Colors.black],
                                  stops: [0.0, 0.35],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
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
                                AppColors.background.withOpacity(.6),
                                AppColors.background.withOpacity(0),
                              ],
                              stops: const [0, .30, .55],
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
                  padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
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
                              width: 34,
                              child: Column(
                                children: [
                                  const SizedBox(height: 6),
                                  const _RailDot(color: AppColors.primary, filled: false),
                                  Expanded(
                                    child: CustomPaint(
                                      size: const Size(2, double.infinity),
                                      painter: _DashedLinePainter(color: AppColors.border),
                                    ),
                                  ),
                                  const _RailDot(color: _gold, filled: true, icon: Icons.location_on),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Fields — direct inline typing, no inner box
                            Expanded(
                              child: Column(
                                children: [
                                  CompositedTransformTarget(
                                    link: _fromLink,
                                    child: _InlineField(
                                      label: 'Leaving from',
                                      hint: 'City or pickup point',
                                      controller: _fromCtrl,
                                      focusNode: _fromFocus,
                                      loading: _fromLoading,
                                      onChanged: _searchFrom,
                                      onClear: () => setState(() {
                                        _from = null; _fromCtrl.clear(); _fromResults = []; _showFromDrop = false;
                                      }),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    child: Divider(height: 1, color: AppColors.border.withOpacity(.6)),
                                  ),
                                  CompositedTransformTarget(
                                    link: _toLink,
                                    child: _InlineField(
                                      label: 'Going to',
                                      hint: 'City or drop-off point',
                                      controller: _toCtrl,
                                      focusNode: _toFocus,
                                      loading: _toLoading,
                                      onChanged: _searchTo,
                                      onClear: () => setState(() {
                                        _to = null; _toCtrl.clear(); _toResults = []; _showToDrop = false;
                                      }),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 44), // room for swap button
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
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary.withOpacity(.15)),
                                ),
                                child: const Icon(Icons.swap_vert, color: AppColors.primary, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

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
              ],
            ),
          ),

          // ── Floating dropdown overlays ───────────────────────────
          // FROM
          if (_showFromDrop && _fromResults.isNotEmpty)
            CompositedTransformFollower(
              link: _fromLink,
              showWhenUnlinked: false,
              offset: const Offset(-64, 62),
              child: SizedBox(
                width: dropdownWidth,
                child: _DropdownList(results: _fromResults, onSelect: _selectFrom),
              ),
            ),
          // TO
          if (_showToDrop && _toResults.isNotEmpty)
            CompositedTransformFollower(
              link: _toLink,
              showWhenUnlinked: false,
              offset: const Offset(-64, 62),
              child: SizedBox(
                width: dropdownWidth,
                child: _DropdownList(results: _toResults, onSelect: _selectTo),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Boxed field (bordered input) ────────────────────────────────────────
class _InlineField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool loading;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _InlineField({
    required this.label, required this.hint,
    required this.controller, required this.focusNode,
    required this.loading,
    required this.onChanged, required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: .2,
          color: focusNode.hasFocus ? AppColors.primary : AppColors.textSecondary,
        )),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w400),
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (loading)
            const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
          else if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.cancel_rounded, size: 18, color: AppColors.textSecondary.withOpacity(.5)),
            ),
        ]),
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

// ── Dropdown results ─────────────────────────────────────────────────────
class _DropdownList extends StatelessWidget {
  final List<LocationResult> results;
  final ValueChanged<LocationResult> onSelect;
  const _DropdownList({required this.results, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final items = results.take(5).toList();
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxHeight: items.length * 62.0 + 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(.12), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.border.withOpacity(.5), indent: 64),
          itemBuilder: (ctx, i) {
            final loc = items[i];
            final isFirst = i == 0;
            final isLast = i == items.length - 1;
            return InkWell(
              onTap: () => onSelect(loc),
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(16) : Radius.zero,
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
            );
          },
        ),
      ),
    );
  }
}

// ── Dashed vertical line painter (route rail) ────────────────────────────
class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashHeight;
  final double gapHeight;
  final double strokeWidth;

  const _DashedLinePainter({
    required this.color,
    this.dashHeight = 4,
    this.gapHeight = 4,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), paint);
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashHeight != dashHeight ||
        oldDelegate.gapHeight != gapHeight ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}