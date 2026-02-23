import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==============================================================================
//  PART 0: HAPTIC ENGINE
// ==============================================================================

class VyltHaptics {
  static Future<void> light() async => await HapticFeedback.lightImpact();
  static Future<void> medium() async => await HapticFeedback.mediumImpact();
  static Future<void> heavy() async => await HapticFeedback.heavyImpact();

  static Future<void> patternSuccess() async {
    await light(); await Future.delayed(const Duration(milliseconds: 100)); await light();
  }
  
  static Future<void> patternError() async {
    await heavy(); await Future.delayed(const Duration(milliseconds: 100)); await heavy();
  }

  static Future<void> patternSalary() async { await light(); }
  static Future<void> patternYield() async { await light(); await Future.delayed(const Duration(milliseconds: 150)); await medium(); }
  static Future<void> patternHealing() async { await light(); await Future.delayed(const Duration(milliseconds: 150)); await medium(); await Future.delayed(const Duration(milliseconds: 150)); await light(); }
  static Future<void> patternSettlementTick() async => await HapticFeedback.selectionClick();
}

// ==============================================================================
//  PART 1: THE FINANCIAL BRAIN (Conscious Edition)
// ==============================================================================

enum FinancialMood { stable, anxious, confident, volatile, recovering }
enum InflowSource { salary, freelance, refund, gift, yield }
enum OutflowIntent { necessary, optional, strategic, panic }

class SourceMetadata {
  final double confidenceImpact;
  final double variance; 
  final String label;
  const SourceMetadata(this.label, this.confidenceImpact, this.variance);
}

const Map<InflowSource, SourceMetadata> kSourceMeta = {
  InflowSource.salary: SourceMetadata("Salary", 0.15, 0.05),
  InflowSource.freelance: SourceMetadata("Freelance", 0.08, 0.2),
  InflowSource.refund: SourceMetadata("Refund", 0.02, 0.0),
  InflowSource.gift: SourceMetadata("Gift", 0.05, 0.1),
  InflowSource.yield: SourceMetadata("Yield", 0.03, 0.8), 
};

class FinancialSnapshot {
  final double liquidity;
  final int runwayDays;
  final double confidenceScore; 
  final double confidenceCeiling; 
  final double riskScore;
  final int riskMomentum;
  final DateTime lastUpdated;
  final String advisorMessage;
  final FinancialMood systemMood;
  final bool isPending;
  final bool isStale; // NEW: Data freshness
  final List<String> dataProvenance; // NEW: GDPR Transparency
  final List<String> actionHistory;

  const FinancialSnapshot({
    required this.liquidity,
    required this.runwayDays,
    required this.confidenceScore,
    required this.confidenceCeiling,
    required this.riskScore,
    required this.riskMomentum,
    required this.lastUpdated,
    required this.advisorMessage,
    required this.systemMood,
    this.isPending = false,
    this.isStale = false,
    this.dataProvenance = const ["User Input", "Local Heuristics"],
    this.actionHistory = const [],
  });

  factory FinancialSnapshot.initial() {
    return FinancialSnapshot(
      liquidity: 24500.42,
      runwayDays: 142,
      confidenceScore: 0.85,
      confidenceCeiling: 1.0,
      riskScore: 0.12,
      riskMomentum: 0,
      lastUpdated: DateTime.now(),
      advisorMessage: "No significant changes since morning.",
      systemMood: FinancialMood.stable,
    );
  }

  FinancialSnapshot copyWith({
    double? liquidity,
    int? runwayDays,
    double? confidenceScore,
    double? confidenceCeiling,
    double? riskScore,
    int? riskMomentum,
    DateTime? lastUpdated,
    String? advisorMessage,
    FinancialMood? systemMood,
    bool? isPending,
    bool? isStale,
    List<String>? dataProvenance,
    List<String>? actionHistory,
  }) {
    return FinancialSnapshot(
      liquidity: liquidity ?? this.liquidity,
      runwayDays: runwayDays ?? this.runwayDays,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      confidenceCeiling: confidenceCeiling ?? this.confidenceCeiling,
      riskScore: riskScore ?? this.riskScore,
      riskMomentum: riskMomentum ?? this.riskMomentum,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      advisorMessage: advisorMessage ?? this.advisorMessage,
      systemMood: systemMood ?? this.systemMood,
      isPending: isPending ?? this.isPending,
      isStale: isStale ?? this.isStale,
      dataProvenance: dataProvenance ?? this.dataProvenance,
      actionHistory: actionHistory ?? this.actionHistory,
    );
  }
}

class FinancialSystem extends ChangeNotifier {
  FinancialSnapshot _state = FinancialSnapshot.initial();
  FinancialSnapshot get state => _state;
  Timer? _entropyTimer;

  FinancialSystem() { _startEntropy(); }
  @override void dispose() { _entropyTimer?.cancel(); super.dispose(); }

  // --- TEMPORAL REALISM ---
  void _startEntropy() {
    _entropyTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      // Data Staling
      final timeSinceUpdate = DateTime.now().difference(_state.lastUpdated).inMinutes;
      final isStale = timeSinceUpdate > 5; // Mock stale time

      if (_state.confidenceScore > 0.4) {
        _state = _state.copyWith(
          confidenceScore: (_state.confidenceScore - 0.01).clamp(0.0, _state.confidenceCeiling),
          isStale: isStale,
        );
        _updateMood();
      }
    });
  }

  // --- RELATIONAL LOGIC ---
  void _updateMood() {
    FinancialMood newMood = FinancialMood.stable;
    String newMsg = _state.advisorMessage;

    if (_state.riskScore > 0.5) {
      newMood = FinancialMood.volatile;
      newMsg = "Markets are moving. I'm keeping an eye on your exposure.";
    } else if (_state.confidenceScore < 0.5) {
      newMood = FinancialMood.anxious;
      newMsg = "Signals are mixed. I'm less confident in this forecast.";
    } else if (_state.confidenceScore > 0.85) {
      newMood = FinancialMood.confident;
      newMsg = "Data is fresh. Your runway looks solid.";
    }

    if (newMood != _state.systemMood) {
      _state = _state.copyWith(systemMood: newMood, advisorMessage: newMsg);
      notifyListeners();
    } else {
      notifyListeners(); // Pulse update
    }
  }

  // --- ACTIONS ---
  Map<String, dynamic> forecastInflow(double amount) {
    final dailyBurn = _state.liquidity / math.max(_state.runwayDays, 1);
    final addedRunway = (amount / dailyBurn).round();
    return {
      "runwayDelta": "+$addedRunway days",
      "message": "This would extend your runway by $addedRunway days.",
    };
  }

  Future<void> commitInflow(double amount, String note) async {
    _setPending(true, "Verifying source...");
    await Future.delayed(const Duration(milliseconds: 1500));

    final dailyBurn = _state.liquidity / math.max(_state.runwayDays, 1);
    final addedRunway = (amount / dailyBurn).round();

    _addToHistory("INFLOW");
    _state = _state.copyWith(
      liquidity: _state.liquidity + amount,
      runwayDays: _state.runwayDays + addedRunway,
      confidenceScore: (_state.confidenceScore + 0.1).clamp(0.0, _state.confidenceCeiling),
      advisorMessage: "Update registered. Re-evaluating liquidity.",
      lastUpdated: DateTime.now(),
      isPending: false,
      isStale: false,
    );
    _updateMood();
  }

  void commitReallocation(double amount, bool toVolatile) {
    final riskDelta = toVolatile ? 0.05 : -0.03;
    _state = _state.copyWith(
      riskScore: (_state.riskScore + riskDelta).clamp(0.0, 1.0),
      advisorMessage: toVolatile ? "Noted. Adjusting for volatility." : "Balance restored.",
      lastUpdated: DateTime.now(),
    );
    _updateMood();
  }

  Map<String, dynamic> forecastOutflow(double amount) {
    final newRunway = (_state.runwayDays - (amount / 170)).round(); 
    final isRisky = newRunway < 60;
    return {
      "isRisky": isRisky,
      "message": isRisky ? "Careful, this creates a confidence scar." : "Safe to spend.",
    };
  }

  Future<void> commitOutflow(double amount, String note, bool scheduled) async {
    if (scheduled) {
      _state = _state.copyWith(advisorMessage: "Payment buffered.");
      notifyListeners();
      return;
    }
    _setPending(true, "Sending...");
    await Future.delayed(const Duration(milliseconds: 1000));

    final newLiquidity = _state.liquidity - amount;
    final newRunway = (_state.runwayDays - (amount / 170)).round(); 
    
    _addToHistory("OUTFLOW");
    _state = _state.copyWith(
      liquidity: newLiquidity,
      runwayDays: newRunway,
      advisorMessage: "Sent. Recalculating impact.",
      lastUpdated: DateTime.now(),
      isPending: false,
      isStale: false,
    );
    _updateMood();
  }

  void improveConfidence() {
    _state = _state.copyWith(
      confidenceScore: (_state.confidenceScore + 0.15).clamp(0.0, 1.0),
      advisorMessage: "Receipt parsed. Resolution improved.",
      lastUpdated: DateTime.now(),
      isStale: false,
    );
    _updateMood();
  }

  void _setPending(bool isPending, String msg) {
    _state = _state.copyWith(isPending: isPending, advisorMessage: msg);
    notifyListeners();
  }

  void _addToHistory(String action) {
    List<String> history = List.from(_state.actionHistory);
    history.add(action);
    if (history.length > 5) history.removeAt(0);
    _state = _state.copyWith(actionHistory: history);
  }
}

// ==============================================================================
//  PART 2: THE UI (Humanized)
// ==============================================================================

const Color kVyltGreen = Color(0xFF00E676);
const Color kVyltBlue = Color(0xFF2979FF);
const Color kVyltOrange = Color(0xFFFF9100);
const Color kVyltRed = Color(0xFFFF375F);
const Color kSurfaceColor = Color(0xFF050505);

// --- ACTION 1: ADD (Typed Note) ---
class AddSheet extends StatefulWidget {
  final FinancialSystem system;
  const AddSheet({super.key, required this.system});
  @override
  State<AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<AddSheet> with SingleTickerProviderStateMixin {
  String _amount = "0";
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic>? _forecast;
  bool _isSettling = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (_isSettling) return; 
    HapticFeedback.selectionClick();
    setState(() {
      if (key == "del") {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : "0";
      } else if (key != ".") {
        _amount = _amount == "0" ? key : _amount + key;
      }
      double val = double.tryParse(_amount) ?? 0;
      if (val > 0) {
        _forecast = widget.system.forecastInflow(val);
      } else {
        _forecast = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      mood: widget.system.state.systemMood,
      child: Column(
        children: [
          const _SheetHandle(),
          const SizedBox(height: 24),
          _Label(text: _isSettling ? "ADDING..." : "ADD MONEY"),
          const Spacer(),
          
          FadeTransition(
            opacity: Tween(begin: 1.0, end: 0.5).animate(_pulseController),
            child: _AmountDisplay(amount: _amount, label: "GBP"),
          ),
          
          const SizedBox(height: 16),
          if (_forecast != null)
            _IntelligenceBadge(
              text: _forecast!['message'],
              active: true,
              color: kVyltGreen,
            ),

          const Spacer(),
          
          // FREEFORM INPUT REPLACING SELECTOR
          AbsorbPointer(
            absorbing: _isSettling,
            child: _GlassTextField(
              controller: _noteController,
              hint: "Source (e.g., Design Project, Refund...)",
            ),
          ),
          
          const SizedBox(height: 24),
          AbsorbPointer(absorbing: _isSettling, child: _Numpad(onKey: _onKey)),
          const SizedBox(height: 24),

          _LiquidButton(
            label: _isSettling ? "CONFIRMING..." : "ADD CASH",
            color: kVyltGreen,
            enabled: _amount != "0" && !_isSettling,
            onTap: () async {
              setState(() => _isSettling = true);
              _pulseController.repeat(reverse: true);
              await widget.system.commitInflow(double.parse(_amount), _noteController.text);
              if (mounted) Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// --- ACTION 2: SWAP ---
class SwapSheet extends StatefulWidget {
  final FinancialSystem system;
  const SwapSheet({super.key, required this.system});
  @override
  State<SwapSheet> createState() => _SwapSheetState();
}

class _SwapSheetState extends State<SwapSheet> {
  double _allocation = 0.0;
  bool _toVolatile = false;

  void _onSlider(double val) {
    if (_toVolatile && val > 8000) val = 8000 + (val - 8000) * 0.3;
    setState(() {
      _allocation = val;
      _toVolatile = _allocation > 1000;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      mood: _toVolatile ? FinancialMood.volatile : FinancialMood.stable,
      child: Column(
        children: [
          const _SheetHandle(),
          const SizedBox(height: 24),
          const _Label(text: "SWAP ASSETS"),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(child: _AssetCard("FROM", "GBP", true)),
              const Icon(CupertinoIcons.arrow_right, color: Colors.white24, size: 16),
              Expanded(child: _AssetCard("TO", "Stocks", false)),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("AMOUNT", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text("£${_allocation.toInt()}", style: TextStyle(color: _toVolatile ? kVyltOrange : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              Slider(
                value: _allocation, min: 0, max: 10000, divisions: 20, 
                activeColor: _toVolatile ? kVyltOrange : Colors.white, 
                onChanged: _onSlider
              ),
            ],
          ),
          const SizedBox(height: 32),
          _LiquidButton(
            label: "SWAP",
            color: _toVolatile ? kVyltOrange : Colors.white,
            enabled: _allocation > 0,
            onTap: () {
              widget.system.commitReallocation(_allocation, _toVolatile);
              Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// --- ACTION 3: SEND (Typed Note) ---
class SendSheet extends StatefulWidget {
  final FinancialSystem system;
  const SendSheet({super.key, required this.system});
  @override
  State<SendSheet> createState() => _SendSheetState();
}

class _SendSheetState extends State<SendSheet> {
  String _amount = "0";
  int _timing = 0; 
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic>? _forecast;

  void _onKey(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (key == "del") {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : "0";
      } else if (key != ".") {
        _amount = _amount == "0" ? key : _amount + key;
      }
      double val = double.tryParse(_amount) ?? 0;
      if (val > 0) {
        _forecast = widget.system.forecastOutflow(val);
      } else {
        _forecast = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isRisky = _forecast != null && _forecast!['isRisky'];

    return _GlassSheet(
      mood: isRisky ? FinancialMood.volatile : FinancialMood.stable,
      child: Column(
        children: [
          const _SheetHandle(),
          const SizedBox(height: 24),
          const _Label(text: "SEND MONEY"),
          const Spacer(),
          _AmountDisplay(amount: _amount, label: "GBP", color: isRisky ? kVyltRed : kVyltBlue),
          const SizedBox(height: 12),
          if (_forecast != null)
             _IntelligenceBadge(
               text: _forecast!['message'], 
               active: true, 
               color: isRisky ? kVyltRed : Colors.white,
             ),
          const Spacer(),
          
          // FREEFORM INPUT
          _GlassTextField(
            controller: _noteController,
            hint: "What's this for? (e.g. Rent, Dinner...)",
          ),
          
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                _TimingTab("PAY NOW", 0, _timing, (i) => setState(() => _timing = i)),
                _TimingTab("SCHEDULE", 1, _timing, (i) => setState(() => _timing = i)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Numpad(onKey: _onKey),
          const SizedBox(height: 24),
          
          _LiquidButton(
            label: _timing == 1 ? "SCHEDULE" : "PAY",
            color: isRisky ? kVyltRed : Colors.white,
            enabled: _amount != "0",
            onTap: () {
               widget.system.commitOutflow(double.parse(_amount), _noteController.text, _timing == 1);
               Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// --- ACTION 4: SCAN ---
class ScanSheet extends StatelessWidget {
  final FinancialSystem system;
  const ScanSheet({super.key, required this.system});

  @override
  Widget build(BuildContext context) {
    return _GlassSheet(
      child: Column(
        children: [
          const _SheetHandle(),
          const Spacer(),
          const Icon(CupertinoIcons.viewfinder, color: Colors.white24, size: 80),
          const SizedBox(height: 24),
          const Text("SCAN RECEIPT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Align receipt to auto-fill details", style: TextStyle(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          _LiquidButton(
            label: "CAPTURE",
            color: kVyltGreen,
            onTap: () {
              VyltHaptics.patternSuccess();
              system.improveConfidence();
              Navigator.pop(context);
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ==============================================================================
//  SHARED VISUAL COMPONENTS
// ==============================================================================

class _GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _GlassTextField({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        cursorColor: kVyltBlue,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}

class _GlassSheet extends StatelessWidget {
  final Widget child;
  final FinancialMood mood;
  const _GlassSheet({required this.child, this.mood = FinancialMood.stable});
  @override
  Widget build(BuildContext context) {
    Color tint = kSurfaceColor.withValues(alpha: 0.95);
    if (mood == FinancialMood.volatile) tint = const Color(0xFF150505).withValues(alpha: 0.98); 
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(seconds: 1),
        decoration: BoxDecoration(color: tint, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: child)),
        ),
      ),
    );
  }
}

class _LiquidButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;

  const _LiquidButton({required this.label, required this.color, required this.onTap, this.enabled = true});

  @override
  State<_LiquidButton> createState() => _LiquidButtonState();
}

class _LiquidButtonState extends State<_LiquidButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56, width: double.infinity,
        decoration: BoxDecoration(
          color: widget.enabled ? widget.color : Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            widget.label,
            style: TextStyle(
              color: widget.enabled ? Colors.black : Colors.white24,
              fontWeight: FontWeight.w800, letterSpacing: 1.2
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountDisplay extends StatelessWidget {
  final String amount, label;
  final Color color;
  const _AmountDisplay({required this.amount, required this.label, this.color = kVyltBlue});
  @override
  Widget build(BuildContext context) => Column(children: [Text("£$amount", style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w300, letterSpacing: -2)), Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5))]);
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();
  @override
  Widget build(BuildContext context) => Center(child: Container(margin: const EdgeInsets.only(top: 12), width: 32, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2))));
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontFamily: '.SF Pro Display', color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2.0));
}

class _IntelligenceBadge extends StatelessWidget {
  final String text; final String? subText; final bool active; final Color color;
  // ignore: unused_element_parameter
  const _IntelligenceBadge({required this.text, required this.active, this.subText, this.color = Colors.white70});
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(duration: const Duration(milliseconds: 300), opacity: active ? 1.0 : 0.0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))), child: Column(children: [Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)), if(subText!=null) Text(subText!, style: TextStyle(color: Colors.white38, fontSize: 11))])));
  }
}

class _AssetCard extends StatelessWidget {
  final String label, asset; final bool active;
  const _AssetCard(this.label, this.asset, this.active);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: active ? Colors.white.withValues(alpha: 0.08) : Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: active ? Colors.white24 : Colors.transparent)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)), const SizedBox(height: 4), Text(asset, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600))]));
}

class _TimingTab extends StatelessWidget {
  final String label; final int index; final int selectedIndex; final Function(int) onTap;
  const _TimingTab(this.label, this.index, this.selectedIndex, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: () { HapticFeedback.selectionClick(); onTap(index); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: index == selectedIndex ? const Color(0xFF1C1C1E) : Colors.transparent, borderRadius: BorderRadius.circular(10)), alignment: Alignment.center, child: Text(label, style: TextStyle(color: index == selectedIndex ? Colors.white : Colors.white38, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1)))));
}

class _Numpad extends StatelessWidget {
  final Function(String) onKey;
  const _Numpad({required this.onKey});
  @override
  Widget build(BuildContext context) => SizedBox(height: 240, child: Column(children: [Expanded(child: _buildRow(['1','2','3'])), Expanded(child: _buildRow(['4','5','6'])), Expanded(child: _buildRow(['7','8','9'])), Expanded(child: _buildRow(['.','0','del']))]));
  Widget _buildRow(List<String> k) => Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: k.map((x) => Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => onKey(x), child: Center(child: x == 'del' ? const Icon(CupertinoIcons.delete_left, color: Colors.white) : Text(x, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300)))))).toList());
}