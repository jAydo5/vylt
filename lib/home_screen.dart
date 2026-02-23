import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- IMPORTS ---
// Preserving your project structure
import 'predictions_screen.dart'; 
import 'profile_screen.dart';     
import 'wallet_screen.dart';      
import 'transactions_screen.dart'; 
import 'vylt_actions_suite.dart'; 

// ==============================================================================
//  CORE DATA MODELS (PRODUCTION GRADE)
// ==============================================================================

enum AccountType { aggregate, fiat, crypto, investment }

class AccountData {
  final String id;
  final String label;
  final AccountType type;
  final double balance;
  final double volatility; // 0.0 to 1.0 (Controls graph jaggedness)
  final Color primaryColor;

  AccountData({
    required this.id, 
    required this.label, 
    required this.type, 
    required this.balance, 
    required this.volatility,
    required this.primaryColor
  });
}

// ==============================================================================
//  MAIN SCREEN
// ==============================================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // --- THE BRAIN ---
  final FinancialSystem _system = FinancialSystem();

  // --- REACTIVE STATE (The Source of Truth) ---
  late AccountData _activeContext; // Currently selected account context
  bool _isPrivacyModeActive = false; // Global obfuscation state
  List<AccountData> _accounts = [];

  // --- ANIMATION CONTROLLERS ---
  late final AnimationController _entryController;
  late final AnimationController _graphController;
  late final AnimationController _pulseController;
  final ScrollController _scrollController = ScrollController();

  // --- STATE MEMORY ---
  bool _hasViewedProvenance = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    // Initialize "Real" Data State
    _initializeData();

    _entryController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 1200)
    )..forward();

    _graphController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 4)
    ); 

    _pulseController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 3)
    )..repeat(reverse: true);
  }

  void _initializeData() {
    // Define the data sources
    _accounts = [
      AccountData(id: 'all', label: 'Net Worth', type: AccountType.aggregate, balance: 14250.30, volatility: 0.3, primaryColor: const Color(0xFF0A84FF)),
      AccountData(id: 'hsbc', label: 'Current', type: AccountType.fiat, balance: 500.00, volatility: 0.05, primaryColor: Colors.white),
      AccountData(id: 'revolut', label: 'Travel', type: AccountType.fiat, balance: 57.30, volatility: 0.1, primaryColor: const Color(0xFF00E5FF)),
      AccountData(id: 'ledger', label: 'Cold Storage', type: AccountType.crypto, balance: 8450.00, volatility: 0.8, primaryColor: const Color(0xFFF7931A)),
    ];
    _activeContext = _accounts[0]; // Default to Aggregate view
  }

  void _setActiveContext(AccountData account) {
    if (_activeContext.id == account.id) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _activeContext = account;
    });
    // Restart graph to reflect new volatility profile
    _graphController.reset();
    _graphController.repeat();
  }

  void _togglePrivacyMode() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isPrivacyModeActive = !_isPrivacyModeActive;
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _graphController.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    _system.dispose();
    super.dispose();
  }

  // --- NAVIGATION ---
  void _nav(Widget page) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, a, s) => page,
      transitionsBuilder: (c, a, s, child) => FadeTransition(opacity: a, child: child),
      transitionDuration: const Duration(milliseconds: 300),
    ));
  }

  void _openSheet(Widget sheet) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => sheet,
    );
  }

  @override
  Widget build(BuildContext context) {
    const double kHorizontalPadding = 24.0;
    
    // Derived UI State
    final mood = _system.state.systemMood;
    final bool isHighAlert = mood == FinancialMood.volatile || _system.state.confidenceScore < 0.4;
    Color moodColor = isHighAlert ? const Color(0xFFFF375F) : _activeContext.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBody: true,
      body: Stack(
        children: [
          // 0. Ambient Background (Reactive to Context)
          _SystemAmbientBackground(
            color: moodColor, 
            pulse: _pulseController, 
            opacity: isHighAlert ? 0.05 : 0.12 
          ),

          // 1. Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // --- HEADER ---
              SliverAppBar(
                backgroundColor: Colors.transparent,
                toolbarHeight: 60,
                expandedHeight: 110, 
                floating: true, pinned: true, elevation: 0,
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.6),
                      child: FlexibleSpaceBar(
                        expandedTitleScale: 1.0,
                        titlePadding: EdgeInsets.zero,
                        title: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _SystemStatusRail(
                            mood: mood,
                            confidence: _system.state.confidenceScore,
                            risk: _activeContext.type == AccountType.crypto ? 0.85 : 0.12, // Dynamic Risk based on context
                            color: moodColor,
                            padding: kHorizontalPadding,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      _AnimatedBrandIcon(color: moodColor),
                      const SizedBox(width: 12),
                      Text(
                        _activeContext.type == AccountType.aggregate ? "VYLT" : _activeContext.label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: '.SF Pro Display',
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  // FEATURE 2: Privacy Shield Toggle
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _BouncingButton(
                      onTap: _togglePrivacyMode,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isPrivacyModeActive ? Colors.white : Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPrivacyModeActive ? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, 
                          color: _isPrivacyModeActive ? Colors.black : Colors.white, 
                          size: 18
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: _BouncingButton(
                      onTap: () {
                         setState(() => _hasViewedProvenance = true);
                         _openSheet(const _ProvenanceSheet());
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1))
                        ),
                        child: Icon(
                          _hasViewedProvenance ? CupertinoIcons.shield_fill : CupertinoIcons.exclamationmark_shield_fill, 
                          color: _hasViewedProvenance ? Colors.white38 : moodColor, 
                          size: 18
                        ),
                      ),
                    ),
                  )
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kHorizontalPadding),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _entryController, curve: Curves.easeOutQuad),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // FEATURE 1: Context-Aware Hero
                        // Updates based on selection
                        _LiveBalanceHero(
                          graphController: _graphController,
                          balance: _activeContext.balance,
                          volatilityFactor: _activeContext.volatility,
                          isPending: _system.state.isPending,
                          primaryColor: moodColor,
                          isObfuscated: _isPrivacyModeActive,
                        ),
                        
                        const SizedBox(height: 48),

                        // FEATURE 1: Interactive Account Orchestrator
                        _AccountsOrchestrator(
                          accounts: _accounts,
                          selectedId: _activeContext.id,
                          onAccountSelected: _setActiveContext,
                          onAddTap: () => _openSheet(AddSheet(system: _system)),
                          totalLiquidity: 14250.30, // Aggregate
                          isObfuscated: _isPrivacyModeActive,
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // FEATURE 3: Smart Action Grid
                        _SmartActionGrid(
                          onAddTap: () => _openSheet(AddSheet(system: _system)),
                          onSwapTap: () => _openSheet(SwapSheet(system: _system)),
                        ),
                        
                        const SizedBox(height: 48),

                        _SystemVitalsGrid(
                          runway: _activeContext.type == AccountType.aggregate ? _system.state.runwayDays : 999, // Dynamic logic
                          risk: _activeContext.volatility,
                          isObfuscated: _isPrivacyModeActive,
                        ),
                        
                        const SizedBox(height: 48),

                        const _ExpandableBento(),

                        const SizedBox(height: 48),

                        const _SectionHeader(title: 'Live Markets', action: 'Details'),
                        const SizedBox(height: 20),
                        
                        // FEATURE 3: Live Ticker
                        const _LiveMarketTicker(),
                        
                        const SizedBox(height: 48),

                        const _SectionHeader(title: 'Intelligence', action: ''),
                        const SizedBox(height: 20),
                        _IosGlassList(onTapAnalytics: () => _nav(const PredictionsScreen())),
                        
                        const SizedBox(height: 48),

                        _SectionHeader(title: 'Recent Activity', action: 'View all', onActionTap: () => _nav(const TransactionsScreen())),
                        const SizedBox(height: 20),
                        _ActivityFeed(isObfuscated: _isPrivacyModeActive),

                        const SizedBox(height: 140), 
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          Positioned(
            bottom: 34, left: 24, right: 24,
            child: _DynamicNavBar(
              onChartTap: () => _nav(const PredictionsScreen()),
              onWalletTap: () => _nav(const WalletScreen()),
              onProfileTap: () => _nav(const ProfileScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================================================
//  FEATURE 1: INTERACTIVE ACCOUNTS ORCHESTRATOR
// ==============================================================================

class _AccountsOrchestrator extends StatelessWidget {
  final List<AccountData> accounts;
  final String selectedId;
  final Function(AccountData) onAccountSelected;
  final VoidCallback onAddTap;
  final double totalLiquidity;
  final bool isObfuscated;

  const _AccountsOrchestrator({
    required this.accounts,
    required this.selectedId,
    required this.onAccountSelected,
    required this.onAddTap,
    required this.totalLiquidity,
    required this.isObfuscated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Data Sources", 
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, fontFamily: '.SF Pro Display', letterSpacing: -0.5)
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(
                      "Live Connection", 
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w500)
                    ),
                  ],
                ),
              ],
            ),
            _BouncingButton(
              onTap: (){}, 
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Row(children: const [Text("Edit", style: TextStyle(color: Color(0xFF00E5FF), fontSize: 13, fontWeight: FontWeight.w600)), SizedBox(width: 6), Icon(CupertinoIcons.pencil, color: Color(0xFF00E5FF), size: 14)]),
              )
            )
          ],
        ),
        const SizedBox(height: 24),
        
        SizedBox(
          height: 155,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            itemCount: accounts.length + 1,
            itemBuilder: (context, index) {
              if (index == accounts.length) return _AddAccountBubble(onTap: onAddTap);
              
              final account = accounts[index];
              final isSelected = account.id == selectedId;
              
              return _AccountBubble(
                data: account,
                isSelected: isSelected,
                isObfuscated: isObfuscated,
                onTap: () => onAccountSelected(account),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AccountBubble extends StatelessWidget {
  final AccountData data;
  final bool isSelected;
  final bool isObfuscated;
  final VoidCallback onTap;

  const _AccountBubble({
    required this.data,
    required this.isSelected,
    required this.isObfuscated,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: _BouncingButton(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? data.primaryColor : Colors.white.withValues(alpha: 0.05),
              width: isSelected ? 2 : 1
            ),
            boxShadow: isSelected 
              ? [BoxShadow(color: data.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 4))] 
              : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                 width: 48, height: 48,
                 decoration: BoxDecoration(
                   color: isSelected ? data.primaryColor : Colors.black,
                   shape: BoxShape.circle,
                   border: Border.all(color: Colors.white12),
                 ),
                 child: Center(
                   child: data.type == AccountType.aggregate 
                    ? const Icon(CupertinoIcons.graph_square_fill, color: Colors.white, size: 24)
                    : Text(data.label[0], style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                 ),
               ),
               const SizedBox(height: 16),
               SecureText(
                 text: "£${data.balance.toInt()}", 
                 isObfuscated: isObfuscated,
                 style: TextStyle(
                   color: isSelected ? Colors.black : Colors.white, 
                   fontWeight: FontWeight.bold, 
                   fontSize: 15
                  )
               ),
               const SizedBox(height: 4),
               Text(
                 data.label, 
                 textAlign: TextAlign.center, 
                 style: TextStyle(
                   color: isSelected ? Colors.black54 : Colors.white54, 
                   fontSize: 12, 
                   height: 1.1
                )
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==============================================================================
//  FEATURE 2: SECURE PRIVACY WIDGETS
// ==============================================================================

class SecureText extends StatelessWidget {
  final String text;
  final bool isObfuscated;
  final TextStyle style;

  const SecureText({super.key, required this.text, required this.isObfuscated, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isObfuscated 
        ? ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Text(text, style: style.copyWith(color: Colors.transparent)),
            ),
          )
        : Text(text, style: style),
    );
  }
}

// ==============================================================================
//  FEATURE 3: LIVE MARKET TICKER (STATEFUL & DRIFTING)
// ==============================================================================

class _LiveMarketTicker extends StatefulWidget {
  const _LiveMarketTicker();

  @override
  State<_LiveMarketTicker> createState() => _LiveMarketTickerState();
}

class _LiveMarketTickerState extends State<_LiveMarketTicker> {
  // Using generic mock data structures but animating them to feel "connected"
  List<Map<String, dynamic>> assets = [
    {'symbol': 'BTC', 'price': 74200.50, 'change': 1.2},
    {'symbol': 'ETH', 'price': 3850.12, 'change': -0.4},
    {'symbol': 'GOLD', 'price': 2040.00, 'change': 0.1},
    {'symbol': 'VUSA', 'price': 68.40, 'change': 0.8},
  ];
  late Timer _ticker;

  @override
  void initState() {
    super.initState();
    // Simulate websocket heartbeat
    _ticker = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) return;
      setState(() {
        for (var asset in assets) {
          // Random walk drift
          double drift = (math.Random().nextDouble() - 0.5) * 5.0; // +/- small amount
          asset['price'] += drift;
          // Occasionally flip change direction for liveliness
          if (math.Random().nextDouble() > 0.9) {
             asset['change'] += (drift * 0.1); 
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        itemCount: assets.length,
        itemBuilder: (context, index) {
          final asset = assets[index];
          return _LiveAssetCard(
            symbol: asset['symbol'], 
            price: asset['price'], 
            changePct: asset['change'],
            color: asset['change'] >= 0 ? const Color(0xFF00C853) : const Color(0xFFFF375F)
          );
        },
      ),
    );
  }
}

class _LiveAssetCard extends StatelessWidget {
  final String symbol;
  final double price;
  final double changePct;
  final Color color;

  const _LiveAssetCard({
    required this.symbol, required this.price, required this.changePct, required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft, 
          end: Alignment.bottomRight, 
          colors: [
            const Color(0xFF1C1C1E),
            const Color(0xFF101012),
          ]
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: Icon(
                  changePct >= 0 ? CupertinoIcons.arrow_up_right : CupertinoIcons.arrow_down_right,
                  color: color, 
                  size: 14
                ),
              ),
              _BouncingButton(
                child: const Icon(CupertinoIcons.ellipsis, color: Colors.white24, size: 16)
              )
            ],
          ),
          const Spacer(),
          Text(symbol, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            "£${price.toStringAsFixed(2)}", 
            style: const TextStyle(
              color: Colors.white, 
              fontSize: 18, 
              fontWeight: FontWeight.w600,
              fontFeatures: [FontFeature.tabularFigures()]
            )
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4)
            ),
            child: Text(
              "${changePct > 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%", 
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)
            ),
          )
        ],
      ),
    );
  }
}

// ==============================================================================
//  SMART ACTION GRID
// ==============================================================================

class _SmartActionGrid extends StatelessWidget {
  final VoidCallback onAddTap, onSwapTap;
  const _SmartActionGrid({required this.onAddTap, required this.onSwapTap});
  
  @override 
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
    children: [
      _ActionItem(CupertinoIcons.add, 'Add', onAddTap, delay: 0), 
      _ActionItem(CupertinoIcons.arrow_2_circlepath, 'Swap', onSwapTap, delay: 100), 
      _ActionItem(CupertinoIcons.paperplane_fill, 'Send', (){
        // Simulated Contact Picker
        HapticFeedback.mediumImpact();
        showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (c) => Container(
          height: 300, 
          decoration: const BoxDecoration(color: Color(0xFF1C1C1E), borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: const Center(child: Text("Contact Context Placeholder", style: TextStyle(color: Colors.white))),
        ));
      }, delay: 200), 
      _ActionItem(CupertinoIcons.viewfinder, 'Scan', (){
        // Simulated Camera Context
        HapticFeedback.heavyImpact();
      }, delay: 300)
    ]
  );
}

// ==============================================================================
//  UPDATED HERO COMPONENT (WITH CONTEXT)
// ==============================================================================

class _LiveBalanceHero extends StatelessWidget {
  final AnimationController graphController;
  final double balance;
  final double volatilityFactor; // Determines wave chaos
  final bool isPending;
  final Color primaryColor;
  final bool isObfuscated;
  
  const _LiveBalanceHero({
    required this.graphController, 
    required this.balance, 
    required this.volatilityFactor,
    required this.isPending, 
    required this.primaryColor,
    required this.isObfuscated,
  });

  @override
  Widget build(BuildContext context) {
    final formattedLiquidity = balance.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    final parts = formattedLiquidity.split('.');

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Stack(
        children: [
          // Background Graph
          Positioned.fill(
            child: AnimatedBuilder(
              animation: graphController, 
              builder: (context, child) => CustomPaint(
                painter: _LiveWavePainter(
                  animationValue: graphController.value, 
                  color: primaryColor, 
                  volatility: volatilityFactor
                )
              )
            )
          ),
          
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Container(
                  key: ValueKey(primaryColor),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.2))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.link, size: 11, color: primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        isPending ? "RECONCILING LEDGER..." : "LIVE FEED ACTIVE", 
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'AVAILABLE LIQUIDITY', 
                style: TextStyle(
                  color: Colors.white54, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 2.0
                )
              ),
              const SizedBox(height: 8),
              SecureText(
                isObfuscated: isObfuscated,
                text: "£$formattedLiquidity",
                style: const TextStyle(color: Colors.transparent), // Hidden, using child below for layout
              ),
              // We reconstruct the row to handle the visual style better than SecureText can alone
              _ShimmerWrapper(
                active: isPending, 
                child: isObfuscated 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        height: 60, width: 200, 
                        color: Colors.white.withValues(alpha: 0.1)
                      ),
                    ),
                  )
                : Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline, 
                  textBaseline: TextBaseline.alphabetic, 
                  children: [
                    Text('£', style: TextStyle(color: primaryColor, fontSize: 32, fontWeight: FontWeight.w300)),
                    const SizedBox(width: 4),
                    AnimatedFlipCounter(
                      value: double.parse(parts[0].replaceAll(',', '')),
                      textStyle: const TextStyle(
                        color: Colors.white, 
                        fontSize: 64, 
                        fontWeight: FontWeight.w700, 
                        letterSpacing: -2.5,
                        fontFeatures: [FontFeature.tabularFigures()]
                      ),
                    ),
                    Text('.${parts[1]}', style: const TextStyle(color: Colors.white54, fontSize: 36, fontWeight: FontWeight.w300)),
                  ],
                )
              ),
            ]
          ),
        ],
      ),
    );
  }
}

// Simple automated text ticker for the main number
class AnimatedFlipCounter extends StatelessWidget {
  final double value;
  final TextStyle textStyle;
  const AnimatedFlipCounter({super.key, required this.value, required this.textStyle});
  @override
  Widget build(BuildContext context) {
    // In a real app, use a TweenAnimationBuilder here
    return Text(
      value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
      style: textStyle
    );
  }
}

// ==============================================================================
//  UPDATED HELPERS
// ==============================================================================

class _LiveWavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  final double volatility; // 0.1 = smooth, 1.0 = chaos

  _LiveWavePainter({required this.animationValue, required this.color, required this.volatility});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.2)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, size.height * 0.7);
    
    for (double i = 0; i <= size.width; i++) {
      // Logic: Mix Sin waves based on volatility
      double wave1 = math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi));
      double wave2 = math.sin((i / size.width * (4 + volatility * 10) * math.pi) + (animationValue * 2 * math.pi));
      
      double heightOffset = (wave1 * 20) + (wave2 * (5 + volatility * 15));
      
      path.lineTo(i, size.height * 0.7 + heightOffset);
    }
    
    canvas.drawPath(path, paint);
    
    // Shader fill
    paint.color = color.withValues(alpha: 0.1);
    paint.style = PaintingStyle.fill;
    paint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [color.withOpacity(0.2), color.withOpacity(0)], 
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(_LiveWavePainter old) => true; 
}

class _ActivityFeed extends StatelessWidget {
  final bool isObfuscated;
  const _ActivityFeed({required this.isObfuscated});
  
  @override 
  Widget build(BuildContext context) => Column(children: [
    _ActivityItem('Uber Rides', 'Pending', '-£14.20', CupertinoIcons.car_detailed, Colors.white, isObfuscated), 
    const SizedBox(height: 20), 
    _ActivityItem('Pret A Manger', 'Food & Drink', '-£8.50', Icons.coffee_rounded, Colors.brown, isObfuscated), 
    const SizedBox(height: 20), 
    _ActivityItem('TFL Refund', 'Transport', '+£2.40', CupertinoIcons.arrow_2_circlepath, Colors.green, isObfuscated)
  ]); 
}

class _ActivityItem extends StatelessWidget { 
  final String t, s, a; final IconData i; final Color c; final bool o;
  const _ActivityItem(this.t, this.s, this.a, this.i, this.c, this.o); 
  @override 
  Widget build(BuildContext context) => Row(children: [
    Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(18)), child: Icon(i, color: c, size: 22)), 
    const SizedBox(width: 16), 
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)), const SizedBox(height: 2), Text(s, style: const TextStyle(color: Colors.white38, fontSize: 13))]), 
    const Spacer(), 
    SecureText(text: a, isObfuscated: o, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]))
  ]); 
}

// Keeping the rest of the visual utilities (BouncingButton, SystemAmbientBackground, etc.) from the previous step 
// as they are already high quality, but assuming they are present in the project.
// Minimized definitions for context:

class _AddAccountBubble extends StatelessWidget { final VoidCallback onTap; const _AddAccountBubble({required this.onTap}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(right: 16), child: _BouncingButton(onTap: onTap, child: Container(width: 100, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CustomPaint(painter: _DashedCirclePainter(), child: const SizedBox(width: 48, height: 48, child: Center(child: Icon(CupertinoIcons.add, color: Color(0xFF00E5FF), size: 24)))), const SizedBox(height: 16), const Text("Add New", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.w600))])))); }
class _ActionItem extends StatelessWidget { final IconData icon; final String label; final VoidCallback? onTap; final int delay; const _ActionItem(this.icon, this.label, this.onTap, {this.delay = 0}); @override Widget build(BuildContext context) => _BouncingButton(onTap: onTap, child: Column(children: [Container(height: 64, width: 64, decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.08))), child: Icon(icon, color: Colors.white, size: 26)), const SizedBox(height: 12), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500))])); }
class _SystemVitalsGrid extends StatelessWidget { final int runway; final double risk; final bool isObfuscated; const _SystemVitalsGrid({required this.runway, required this.risk, required this.isObfuscated}); @override Widget build(BuildContext context) => Row(children: [Expanded(child: _VitalCard(label: "RUNWAY", value: "$runway Days", subLabel: "At current burn rate", icon: CupertinoIcons.hourglass, valueColor: runway < 30 ? Colors.orangeAccent : Colors.white, isObfuscated: isObfuscated)), const SizedBox(width: 16), Expanded(child: _VitalCard(label: "SYSTEM RISK", value: "${(risk * 100).toInt()}%", subLabel: "Portfolio volatility", icon: CupertinoIcons.waveform_path_ecg, valueColor: risk > 0.5 ? const Color(0xFFFF375F) : const Color(0xFF00E5FF), isObfuscated: false))]); }
class _VitalCard extends StatelessWidget { final String label, value, subLabel; final IconData icon; final Color valueColor; final bool isObfuscated; const _VitalCard({required this.label, required this.value, required this.subLabel, required this.icon, this.valueColor = Colors.white, required this.isObfuscated}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF1C1C1E).withValues(alpha: 0.5), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)), Icon(icon, color: Colors.white24, size: 16)]), const SizedBox(height: 12), SecureText(text: value, isObfuscated: isObfuscated, style: TextStyle(color: valueColor, fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subLabel, style: const TextStyle(color: Colors.white24, fontSize: 11))])); }
// ... (Standard visual helpers like _BouncingButton, _DashedCirclePainter, etc. remain unchanged)
class _AnimatedBrandIcon extends StatelessWidget { final Color color; const _AnimatedBrandIcon({required this.color}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)), child: Icon(CupertinoIcons.hexagon_fill, color: color, size: 14)); }
class _SystemStatusRail extends StatelessWidget { final FinancialMood mood; final double confidence; final double risk; final Color color; final double padding; const _SystemStatusRail({required this.mood, required this.confidence, required this.risk, required this.color, required this.padding}); @override Widget build(BuildContext context) => Container(margin: EdgeInsets.symmetric(horizontal: padding), height: 32, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [Row(children: [Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6)])), const SizedBox(width: 8), Text("LIVE", style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2))]), Row(children: [_MiniMeter(label: "CONF", value: confidence, color: Colors.white), const SizedBox(width: 12), _MiniMeter(label: "RISK", value: risk, color: risk > 0.5 ? const Color(0xFFFF375F) : Colors.white)])])); }
class _MiniMeter extends StatelessWidget { final String label; final double value; final Color color; const _MiniMeter({required this.label, required this.value, required this.color}); @override Widget build(BuildContext context) => Row(children: [Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold)), const SizedBox(width: 6), SizedBox(width: 14, height: 14, child: CircularProgressIndicator(value: value, strokeWidth: 2, backgroundColor: Colors.white10, color: color))]); }
class _SectionHeader extends StatelessWidget { final String title, action; final VoidCallback? onActionTap; const _SectionHeader({required this.title, required this.action, this.onActionTap}); @override Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)), if(action.isNotEmpty) GestureDetector(onTap: onActionTap, child: Text(action, style: const TextStyle(fontSize: 14, color: Color(0xFF0A84FF), fontWeight: FontWeight.w600)))]); }
class _BouncingButton extends StatefulWidget { final Widget child; final VoidCallback? onTap; const _BouncingButton({required this.child, this.onTap}); @override State<_BouncingButton> createState() => _BouncingButtonState(); }
class _BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin { late AnimationController _c; late Animation<double> _s; @override void initState() { _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 100)); _s = Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)); super.initState(); } @override Widget build(BuildContext context) => GestureDetector(onTapDown: (_) => _c.forward(), onTapUp: (_) { _c.reverse(); widget.onTap?.call(); }, onTapCancel: () => _c.reverse(), child: AnimatedBuilder(animation: _s, builder: (_, child) => Transform.scale(scale: _s.value, child: widget.child))); }
class _SystemAmbientBackground extends StatelessWidget { final Color color; final AnimationController pulse; final double opacity; const _SystemAmbientBackground({required this.color, required this.pulse, this.opacity = 0.2}); @override Widget build(BuildContext context) => AnimatedBuilder(animation: pulse, builder: (context, child) => Stack(children: [Container(color: const Color(0xFF000000)), Positioned(top: -150, left: -50, child: Opacity(opacity: opacity + (pulse.value * 0.02), child: Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent], stops: const [0.0, 0.7]))))) ])); }
class _DynamicNavBar extends StatelessWidget { final VoidCallback onChartTap, onWalletTap, onProfileTap; const _DynamicNavBar({required this.onChartTap, required this.onWalletTap, required this.onProfileTap}); @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(40), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), child: Container(height: 70, decoration: BoxDecoration(color: const Color(0xFF1C1C1E).withValues(alpha: 0.8), border: Border.all(color: Colors.white.withValues(alpha: 0.1)), borderRadius: BorderRadius.circular(40)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_NavBarIcon(CupertinoIcons.house_fill, true, () {}), _NavBarIcon(CupertinoIcons.chart_bar_fill, false, onChartTap), _NavBarIcon(CupertinoIcons.creditcard_fill, false, onWalletTap), _NavBarIcon(CupertinoIcons.person_fill, false, onProfileTap)])))); }
class _NavBarIcon extends StatelessWidget { final IconData icon; final bool selected; final VoidCallback onTap; const _NavBarIcon(this.icon, this.selected, this.onTap); @override Widget build(BuildContext context) => GestureDetector(onTap: () { HapticFeedback.selectionClick(); onTap(); }, child: Container(padding: const EdgeInsets.all(12), child: Icon(icon, color: selected ? Colors.white : Colors.white24, size: 26))); }
class _ExpandableBento extends StatefulWidget { const _ExpandableBento(); @override State<_ExpandableBento> createState() => _ExpandableBentoState(); }
class _ExpandableBentoState extends State<_ExpandableBento> { bool _expanded = false; @override Widget build(BuildContext context) { return GestureDetector(onTap: () { HapticFeedback.selectionClick(); setState(() => _expanded = !_expanded); }, child: AnimatedContainer(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic, height: _expanded ? 240 : 170, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: const Color(0xFF1C1C1E).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.05))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Spend', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)), Icon(_expanded ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down, color: Colors.white24, size: 14)]), const SizedBox(height: 16), const Text('£136.69', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1.0)), const SizedBox(height: 8), const Text('▼ £413.96 vs 16 Dec', style: TextStyle(color: Color(0xFF00E676), fontSize: 13, fontWeight: FontWeight.bold)), if (_expanded) ...[const SizedBox(height: 20), const Divider(color: Colors.white10), const SizedBox(height: 10), const Text("Spending dropped mainly due to fewer transport expenses this month. You are tracking 12% below baseline.", style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))]]))); } }
class _ShimmerWrapper extends StatefulWidget { final bool active; final Widget child; const _ShimmerWrapper({required this.active, required this.child}); @override State<_ShimmerWrapper> createState() => _ShimmerWrapperState(); }
class _ShimmerWrapperState extends State<_ShimmerWrapper> with SingleTickerProviderStateMixin { late AnimationController _c; @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true); } @override void dispose() { _c.dispose(); super.dispose(); } @override Widget build(BuildContext context) { if (!widget.active) return widget.child; return AnimatedBuilder(animation: _c, builder: (_, __) => Opacity(opacity: 0.4 + (_c.value * 0.6), child: widget.child)); } }
class _DashedCirclePainter extends CustomPainter { @override void paint(Canvas canvas, Size size) { final paint = Paint()..color = Colors.white24..strokeWidth = 1.5..style = PaintingStyle.stroke; final path = Path()..addOval(Rect.fromLTWH(0, 0, size.width, size.height)); final dashPath = Path(); double dashWidth = 4.0; double dashSpace = 4.0; double distance = 0.0; for (PathMetric pathMetric in path.computeMetrics()) { while (distance < pathMetric.length) { dashPath.addPath(pathMetric.extractPath(distance, distance + dashWidth), Offset.zero); distance += dashWidth + dashSpace; } } canvas.drawPath(dashPath, paint); } @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false; }
class _ProvenanceSheet extends StatelessWidget { const _ProvenanceSheet(); @override Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: const Color(0xFF101015).withValues(alpha: 0.98), borderRadius: const BorderRadius.vertical(top: Radius.circular(24))), padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: const [Text("Data Provenance", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)), SizedBox(height: 20), Text("All data processed locally.", style: TextStyle(color: Colors.white54))])); }
class _IosGlassList extends StatelessWidget { final VoidCallback onTapAnalytics; const _IosGlassList({required this.onTapAnalytics}); @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(24), child: Container(color: const Color(0xFF1C1C1E), child: Column(children: [_IosRow(CupertinoIcons.scope, 'Horizon Forecast', Colors.purple, onTapAnalytics), const Divider(height: 1, color: Colors.white10, indent: 54), _IosRow(CupertinoIcons.chart_pie_fill, 'Spending breakdown', Colors.blue, () {}), const Divider(height: 1, color: Colors.white10, indent: 54), _IosRow(CupertinoIcons.doc_plaintext, 'Monthly statements', Colors.pink, () {})]))); }
class _IosRow extends StatelessWidget { final IconData i; final String l; final Color c; final VoidCallback t; const _IosRow(this.i, this.l, this.c, this.t); @override Widget build(BuildContext context) => GestureDetector(onTap: t, behavior: HitTestBehavior.opaque, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), child: Row(children: [Icon(i, color: c, size: 22), const SizedBox(width: 16), Text(l, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)), const Spacer(), const Icon(CupertinoIcons.chevron_right, color: Colors.white24, size: 16)]))); }