import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import the Shared Brain
import 'vylt_actions_suite.dart'; 

class PredictionsScreen extends StatefulWidget {
  final FinancialSystem? system; 
  
  const PredictionsScreen({super.key, this.system});

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final ScrollController _mainScrollController;
  late final PageController _timelineController;

  late final FinancialSystem _localSystem;
  FinancialSystem get _activeSystem => widget.system ?? _localSystem;

  int _selectedDayIndex = 0;
  double _viewUncertainty = 0.0;
  
  // --- SCENARIO MODE STATE ---
  bool _isScenarioMode = false;
  double _simulatedBurnMultiplier = 1.0; 
  bool _showTotalBalance = false;

  @override
  void initState() {
    super.initState();
    if (widget.system == null) _localSystem = FinancialSystem();

    _mainScrollController = ScrollController();
    _timelineController = PageController(viewportFraction: 0.22); 

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _timelineController.addListener(() {
      if (_timelineController.hasClients) {
        final page = _timelineController.page ?? 0;
        setState(() {
          final baseConfidence = _activeSystem.state.confidenceScore;
          _viewUncertainty = (page / 20).clamp(0.0, 1.0) * (2.0 - baseConfidence);
        });
      }
    });
  }

  @override
  void dispose() {
    if (widget.system == null) _localSystem.dispose();
    _pulseController.dispose();
    _mainScrollController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _toggleScenarioMode() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isScenarioMode = !_isScenarioMode;
      if (!_isScenarioMode) _simulatedBurnMultiplier = 1.0; 
    });
  }

  void _onDayTap(int index) {
    HapticFeedback.selectionClick();
    _timelineController.animateToPage(
      index, 
      duration: const Duration(milliseconds: 400), 
      curve: Curves.easeOutQuart
    );
  }

  void _showTransactionDetails(String title, String reason) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _GlassDetailSheet(title: title, reason: reason),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scenario Logic: Affects visual output without mutating persistent state
    final effectiveLiquidity = _activeSystem.state.liquidity;
    final baseRunway = _activeSystem.state.runwayDays;
    final effectiveRunway = (baseRunway / _simulatedBurnMultiplier).round();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // 1. AMBIENT BACKGROUND
          _HorizonAmbientBackground(uncertainty: _viewUncertainty, isScenario: _isScenarioMode),

          // 2. MAIN SCROLL VIEW
          AnimatedBuilder(
            animation: _activeSystem,
            builder: (context, child) {
              return CustomScrollView(
                controller: _mainScrollController,
                physics: _isScenarioMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),

                  // HERO SECTION (Interactive Dial)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _showTotalBalance = !_showTotalBalance);
                            },
                            child: _SafetyDialHero(
                              pulseController: _pulseController,
                              liquidity: effectiveLiquidity,
                              runway: effectiveRunway,
                              showTotal: _showTotalBalance,
                              isScenario: _isScenarioMode,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // TIMELINE SECTION
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _SectionTitle(_isScenarioMode ? 'Hypothetical Timeline' : 'Projected Timeline'),
                              _ConfidenceBadge(score: _activeSystem.state.confidenceScore),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 100,
                          child: PageView.builder(
                            controller: _timelineController,
                            itemCount: effectiveRunway, 
                            physics: const BouncingScrollPhysics(),
                            onPageChanged: (index) => setState(() => _selectedDayIndex = index),
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () => _onDayTap(index),
                                child: _DayCapsule(
                                  dayIndex: index,
                                  isSelected: index == _selectedDayIndex,
                                  uncertainty: (index / 30).clamp(0.0, 1.0), 
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // INTELLIGENCE CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _IntelligenceCard(
                        dayIndex: _selectedDayIndex,
                        riskScore: _activeSystem.state.riskScore,
                      ),
                    ),
                  ),

                  // PREDICTED EVENTS
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: _SectionTitle('Cashflow Events'),
                        ),
                        const SizedBox(height: 16),
                        _PredictionFeed(
                          dayIndex: _selectedDayIndex, 
                          onTapItem: _showTransactionDetails
                        ),
                        const SizedBox(height: 140), 
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          
          // 3. FOG OVERLAY
          IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: _viewUncertainty * 0.7),
                  ],
                ),
              ),
            ),
          ),

          // 4. SCENARIO TUNER (Bottom Sheet)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            bottom: _isScenarioMode ? 0 : -220,
            left: 0, right: 0,
            child: _ScenarioTuner(
              multiplier: _simulatedBurnMultiplier,
              onChanged: (val) {
                if ((val - _simulatedBurnMultiplier).abs() > 0.05) HapticFeedback.selectionClick();
                setState(() => _simulatedBurnMultiplier = val);
              },
              onClose: _toggleScenarioMode,
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      toolbarHeight: 60,
      floating: true, pinned: true, elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: const Icon(CupertinoIcons.arrow_left, color: Colors.white),
        ),
      ),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(color: Colors.black.withValues(alpha: 0.2)),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.scope, color: _isScenarioMode ? Colors.purpleAccent : Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            'HORIZON',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              color: _isScenarioMode ? Colors.purpleAccent : Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        CupertinoButton(
          padding: const EdgeInsets.only(right: 20),
          onPressed: _toggleScenarioMode,
          child: Icon(
            _isScenarioMode ? CupertinoIcons.slider_horizontal_3 : CupertinoIcons.slider_horizontal_3, 
            color: _isScenarioMode ? Colors.purpleAccent : Colors.white70
          ),
        )
      ],
    );
  }
}

// --- INTELLIGENT COMPONENTS ---

class _SafetyDialHero extends StatelessWidget {
  final AnimationController pulseController;
  final double liquidity;
  final int runway;
  final bool showTotal;
  final bool isScenario;

  const _SafetyDialHero({
    required this.pulseController, 
    required this.liquidity, 
    required this.runway, 
    required this.showTotal,
    required this.isScenario,
  });

  @override
  Widget build(BuildContext context) {
    // Logic: Safe Spend = (Liquidity / Runway) * Safety Factor
    final dailyBurn = liquidity / math.max(runway, 1);
    final safeSpend = (dailyBurn * 0.85).round();
    
    final displayAmount = showTotal ? "£${liquidity.toStringAsFixed(0)}" : "£$safeSpend";
    final displayLabel = showTotal ? "PROJECTED END BALANCE" : "DAILY SAFE SPEND";
    final accentColor = isScenario ? Colors.purpleAccent : const Color(0xFF00E676);

    return SizedBox(
      height: 240,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ticks (New Layer)
          CustomPaint(
            size: const Size(260, 260),
            painter: _DialTicksPainter(color: Colors.white.withValues(alpha: 0.1)),
          ),
          // Arc
          CustomPaint(
            size: const Size(220, 220),
            painter: _SafetyArcPainter(color: accentColor, percent: showTotal ? 1.0 : 0.85),
          ),
          // Pulse
          AnimatedBuilder(
            animation: pulseController,
            builder: (context, child) {
              return Container(
                width: 180 + (pulseController.value * 10),
                height: 180 + (pulseController.value * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.15 - (pulseController.value * 0.1)),
                      blurRadius: 60,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              );
            },
          ),
          // Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  displayLabel,
                  key: ValueKey(displayLabel),
                  style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: FadeTransition(opacity: anim, child: child)),
                child: Text(
                  displayAmount,
                  key: ValueKey(displayAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isScenario) const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(CupertinoIcons.lab_flask, size: 12, color: Colors.purpleAccent),
                    ),
                    Text(
                      '$runway Days Runway',
                      style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DialTicksPainter extends CustomPainter {
  final Color color;
  _DialTicksPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final tickPaint = Paint()..color = color..strokeWidth = 2..strokeCap = StrokeCap.round;

    for (int i = 0; i < 40; i++) {
      final angle = (i * (360 / 40)) * (math.pi / 180);
      // Skip bottom part
      if (angle > math.pi * 0.25 && angle < math.pi * 0.75) continue;
      
      final p1 = center + Offset(math.cos(angle), math.sin(angle)) * (radius - 10);
      final p2 = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      canvas.drawLine(p1, p2, tickPaint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScenarioTuner extends StatelessWidget {
  final double multiplier;
  final Function(double) onChanged;
  final VoidCallback onClose;

  const _ScenarioTuner({required this.multiplier, required this.onChanged, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF100518).withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: Colors.purpleAccent.withValues(alpha: 0.3))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("SCENARIO TUNER", style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  GestureDetector(onTap: onClose, child: const Icon(CupertinoIcons.down_arrow, color: Colors.white38, size: 20)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Monthly Burn Rate", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text("${(multiplier * 100).toInt()}%", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: Colors.purpleAccent,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: Colors.white,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Slider(
                  value: multiplier,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: onChanged,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Adjust to simulate higher or lower spending patterns.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayCapsule extends StatelessWidget {
  final int dayIndex;
  final bool isSelected;
  final double uncertainty;

  const _DayCapsule({required this.dayIndex, required this.isSelected, required this.uncertainty});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.now().add(Duration(days: dayIndex));
    final dayNum = date.day.toString();
    final weekDay = ['M', 'T', 'W', 'T', 'F', 'S', 'S'][date.weekday - 1];
    
    // Visual decay for future days
    final opacity = (1.0 - (uncertainty * 0.8)).clamp(0.2, 1.0);
    final borderColor = isSelected 
        ? Colors.white 
        : Colors.white.withValues(alpha: 0.05);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.only(top: isSelected ? 0 : 16, bottom: isSelected ? 0 : 16, left: 6, right: 6),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF0A84FF) : const Color(0xFF1C1C1E).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: isSelected ? 1 : 1),
        boxShadow: isSelected
            ? [BoxShadow(color: const Color(0xFF0A84FF).withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(weekDay, style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(dayNum, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 16, fontWeight: FontWeight.bold)),
          if (uncertainty > 0.4) ...[
            const SizedBox(height: 4),
            Icon(CupertinoIcons.question_circle_fill, size: 6, color: Colors.white.withValues(alpha: 0.2))
          ]
        ],
      ),
    );
  }
}

class _GlassDetailSheet extends StatelessWidget {
  final String title;
  final String reason;

  const _GlassDetailSheet({required this.title, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(color: Colors.white10, shape: BoxShape.circle), child: const Icon(CupertinoIcons.doc_text_search, color: Colors.white)),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Text("Projected Transaction", style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(reason, style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5)),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              child: const Text("Edit Projection"),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SafetyArcPainter extends CustomPainter {
  final Color color;
  final double percent;
  _SafetyArcPainter({required this.color, this.percent = 0.85});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Background Track
    final bgPaint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 15..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi * 0.8, math.pi * 1.4, false, bgPaint);

    // Active Arc
    final activePaint = Paint()..color = color..strokeWidth = 15..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    // Gradient Shader
    final rect = Rect.fromCircle(center: center, radius: radius);
    activePaint.shader = SweepGradient(
      startAngle: math.pi * 0.8,
      endAngle: math.pi * 2.2,
      colors: [color.withValues(alpha: 0.1), color],
      stops: const [0.0, 1.0],
      transform: GradientRotation(math.pi * 0.1),
    ).createShader(rect);

    canvas.drawArc(rect, math.pi * 0.8, math.pi * 1.4 * percent, false, activePaint);
  }
  @override
  bool shouldRepaint(covariant _SafetyArcPainter old) => old.percent != percent || old.color != color;
}

class _IntelligenceCard extends StatelessWidget {
  final int dayIndex;
  final double riskScore;
  const _IntelligenceCard({required this.dayIndex, required this.riskScore});

  @override
  Widget build(BuildContext context) {
    String title = "Clear forecast";
    String body = "Spending patterns look normal. You are safely within your calculated runway.";
    IconData icon = CupertinoIcons.check_mark_circled_solid;
    Color color = Colors.greenAccent;

    if (riskScore > 0.3) { title = "Heightened Volatility"; body = "Recent reallocations have increased your risk exposure."; icon = CupertinoIcons.graph_circle; color = Colors.orangeAccent; }
    if (dayIndex > 7) { title = "Variable Zone"; body = "Long-range forecasts are speculative."; icon = CupertinoIcons.eye_slash_fill; color = Colors.purpleAccent; }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF1C1C1E).withValues(alpha: 0.6), borderRadius: BorderRadius.circular(24), border: Border.all(color: color.withValues(alpha: 0.3))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 24), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 6), Text(body, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))]))]),
        ),
      ),
    );
  }
}

class _PredictionFeed extends StatelessWidget {
  final int dayIndex;
  final Function(String, String) onTapItem;
  const _PredictionFeed({required this.dayIndex, required this.onTapItem});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (dayIndex == 0) ...[
        _FeedItem(title: 'TFL Travel Cap', subtitle: 'Predicted daily spend', amount: '~ £11.40', icon: CupertinoIcons.train_style_one, isVariable: true, onTap: () => onTapItem("TFL Travel Cap", "Based on your weekday commute patterns from last month.")),
        const SizedBox(height: 12),
        _FeedItem(title: 'Sainsbury\'s', subtitle: 'Usually 6:30 PM', amount: '~ £24.00', icon: CupertinoIcons.cart, isVariable: true, onTap: () => onTapItem("Sainsbury's", "You typically shop for groceries on Mondays.")),
      ],
      if ((dayIndex % 7) > 4) 
        _FeedItem(title: 'Social / Entertainment', subtitle: 'Weekend Average', amount: '~ £45.00', icon: CupertinoIcons.music_note_2, isVariable: true, onTap: () => onTapItem("Entertainment", "Average weekend discretionary spend.")),
      const SizedBox(height: 12),
      _FeedItem(title: 'Spotify Premium', subtitle: 'Scheduled Renewal', amount: '£10.99', icon: CupertinoIcons.music_albums, isVariable: false, onTap: () => onTapItem("Spotify", "Recurring subscription detected.")),
    ]);
  }
}

class _FeedItem extends StatelessWidget {
  final String title, subtitle, amount;
  final IconData icon;
  final bool isVariable;
  final VoidCallback onTap;

  const _FeedItem({required this.title, required this.subtitle, required this.amount, required this.icon, required this.isVariable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF141416), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle), child: Icon(icon, size: 20, color: Colors.white)), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12))])), Text(amount, style: TextStyle(color: isVariable ? Colors.white70 : Colors.white, fontWeight: FontWeight.w600, fontSize: 15))]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget { final String title; const _SectionTitle(this.title); @override Widget build(BuildContext context) => Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white54, letterSpacing: 1.2)); }
class _ConfidenceBadge extends StatelessWidget { final double score; const _ConfidenceBadge({required this.score}); @override Widget build(BuildContext context) { Color color = score > 0.8 ? Colors.green : Colors.orange; return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.3))), child: Text(score > 0.8 ? "High Confidence" : "Med Confidence", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))); } }
class _HorizonAmbientBackground extends StatelessWidget { final double uncertainty; final bool isScenario; const _HorizonAmbientBackground({required this.uncertainty, this.isScenario = false}); @override Widget build(BuildContext context) { return AnimatedContainer(duration: const Duration(milliseconds: 500), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF050505), isScenario ? const Color(0xFF1A0520) : Color.lerp(const Color(0xFF0A0A0A), const Color(0xFF1A1020), uncertainty)!])), child: Stack(children: [AnimatedPositioned(duration: const Duration(milliseconds: 800), top: -100 + (uncertainty * 50), right: -100 + (uncertainty * 50), child: Container(width: 400, height: 400, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color.lerp(isScenario ? Colors.purpleAccent : Colors.blueAccent, Colors.purpleAccent, uncertainty)!.withValues(alpha: 0.1), Colors.transparent]))))])); } }