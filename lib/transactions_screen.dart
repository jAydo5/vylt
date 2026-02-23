import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import The Brain
import 'vylt_actions_suite.dart'; 

// --- DATA MODELS ---
class Transaction {
  final String title;
  final String amount;
  final String time;
  final String account;
  final IconData icon;
  final Color color;
  final String bankLogo; 
  final bool isPending;
  final bool isPositive;

  const Transaction(this.title, this.amount, this.time, this.account, this.icon, this.color, this.bankLogo, {this.isPending = false, this.isPositive = false});
}

class DayGroup {
  final String dateHeader;
  final String dailyTotal;
  final List<Transaction> transactions;

  const DayGroup(this.dateHeader, this.dailyTotal, this.transactions);
}

class TransactionsScreen extends StatefulWidget {
  final FinancialSystem? system; 
  const TransactionsScreen({super.key, this.system});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> with TickerProviderStateMixin {
  late final AnimationController _auroraController;
  late final ScrollController _scrollController;
  final FocusNode _searchFocus = FocusNode();
  
  late final FinancialSystem _localSystem;
  FinancialSystem get _activeSystem => widget.system ?? _localSystem;

  int _selectedMonthIndex = 4; // Default to "Jan"
  final List<String> _months = ['Sep', 'Oct', 'Nov', 'Dec', 'Jan'];

  @override
  void initState() {
    super.initState();
    if (widget.system == null) _localSystem = FinancialSystem();

    _auroraController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    if (widget.system == null) _localSystem.dispose();
    _auroraController.dispose();
    _scrollController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // --- DATA ENGINE ---
  List<DayGroup> _getDataForMonth(int index) {
    switch (index) {
      case 4: return _janData;
      case 3: return _decData;
      case 2: return _novData;
      case 1: return _octData;
      case 0: return _sepData;
      default: return [];
    }
  }

  // FIX: Using .expand instead of .map with a wrapper
  List<Widget> _buildSlivers() {
    final data = _getDataForMonth(_selectedMonthIndex);
    // .expand flattens the list of lists into a single list of slivers
    return data.expand((group) {
      return [
        _buildDateHeader(group.dateHeader, group.dailyTotal),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final tx = group.transactions[index];
              return _TransactionTile(
                title: tx.title,
                time: tx.time,
                amount: tx.amount,
                account: tx.account,
                iconData: tx.icon,
                iconColor: tx.color,
                bankLogo: tx.bankLogo,
                isPending: tx.isPending,
                isPositive: tx.isPositive,
              );
            },
            childCount: group.transactions.length,
          ),
        ),
      ];
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: AnimatedBuilder(
        animation: _activeSystem,
        builder: (context, child) {
          // React to System Mood
          final mood = _activeSystem.state.systemMood;
          Color moodColor = const Color(0xFF4A00E0); // Stable Blue
          if (mood == FinancialMood.volatile) moodColor = const Color(0xFF800020); // Volatile Red
          if (mood == FinancialMood.anxious) moodColor = const Color(0xFF503000); // Anxious Amber
          if (mood == FinancialMood.recovering) moodColor = const Color(0xFF2E7D32); // Healing Green

          return Stack(
            children: [
              // 1. REACTIVE AURORA
              _LivingAurora(controller: _auroraController, baseColor: moodColor),
              
              const Positioned.fill(
                child: Opacity(opacity: 0.04, child: _FilmGrain()),
              ),

              // 2. CONTENT
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- APP BAR ---
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    expandedHeight: 190,
                    floating: true,
                    pinned: true,
                    leading: _BouncingButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CupertinoIcons.arrow_left, color: Colors.white, size: 20),
                      ),
                    ),
                    flexibleSpace: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.7),
                          child: FlexibleSpaceBar(
                            background: Container(
                              alignment: Alignment.topRight,
                              padding: const EdgeInsets.only(top: 50, right: 20),
                              child: Text(
                                "Live Feed • ${_activeSystem.state.advisorMessage}",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    title: const Text(
                      'All Transactions', 
                      style: TextStyle(
                        fontFamily: '.SF Pro Display', 
                        color: Colors.white, 
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      )
                    ),
                    actions: [
                      _BouncingButton(
                        onTap: () => HapticFeedback.mediumImpact(),
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: moodColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: moodColor.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Text("Export", style: TextStyle(color: moodColor.withValues(alpha: 1.0), fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(width: 4),
                              Icon(CupertinoIcons.doc_text, color: moodColor.withValues(alpha: 1.0), size: 14),
                            ],
                          ),
                        ),
                      )
                    ],
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(150),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: TextField(
                                focusNode: _searchFocus,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(CupertinoIcons.search, color: Colors.white.withValues(alpha: 0.4), size: 18),
                                  hintText: 'Search ledger...',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.only(top: 10),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          SizedBox(
                            height: 40,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _months.length,
                              itemBuilder: (context, index) {
                                final isSelected = _selectedMonthIndex == index;
                                return _BouncingButton(
                                  onTap: () {
                                    setState(() => _selectedMonthIndex = index);
                                    HapticFeedback.selectionClick();
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? const Color(0xFF5E5CE6) 
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _months[index],
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : const Color(0xFF5E5CE6),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // --- INJECTED DATA ---
                  ..._buildSlivers(),

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildDateHeader(String date, String total) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyHeaderDelegate(date: date, total: total),
    );
  }
}

// ==============================================================================
//  DATA POPULATION (20+ Items Per Month)
// ==============================================================================

// --- JANUARY (Recovery) ---
final List<DayGroup> _janData = [
  const DayGroup("Today, 17 Jan", "£42.19", [
    Transaction("Sainsbury's", "£12.50", "18:45", "Current", CupertinoIcons.cart, Colors.orange, "R", isPending: true),
    Transaction("TFL Travel", "£6.40", "02:00", "Current", CupertinoIcons.tram_fill, Color(0xFF113B92), "R"),
    Transaction("Pret A Manger", "£4.25", "08:30", "Current", Icons.coffee, Colors.brown, "R"),
    Transaction("Gymbox", "£19.04", "06:00", "Current", Icons.fitness_center, Colors.white, "HSBC"),
  ]),
  const DayGroup("Yesterday, 16 Jan", "£88.20", [
    Transaction("Uber Rides", "£18.50", "23:15", "Virtual", CupertinoIcons.car_fill, Colors.white, "R"),
    Transaction("The Alchemist", "£42.00", "20:00", "Current", Icons.local_bar, Colors.purpleAccent, "R"),
    Transaction("Tesco Extra", "£22.40", "17:30", "Joint", CupertinoIcons.cart_fill, Color(0xFF00539F), "HSBC"),
    Transaction("Costa", "£3.80", "14:15", "Current", Icons.coffee, Color(0xFF74131C), "R"),
    Transaction("Boots", "£1.50", "12:45", "Current", Icons.medical_services, Colors.blue, "R"),
  ]),
  const DayGroup("14 Jan", "£12.99", [
    Transaction("Spotify", "£10.99", "10:00", "Virtual", CupertinoIcons.music_albums, Colors.green, "R"),
    Transaction("TFL Bus", "£2.00", "08:15", "Current", CupertinoIcons.bus, Colors.red, "R"),
  ]),
  const DayGroup("12 Jan", "£154.00", [
    Transaction("Rent (Part)", "£140.00", "09:00", "Savings", CupertinoIcons.house_fill, Colors.blueAccent, "HSBC"),
    Transaction("Netflix", "£14.00", "08:00", "Virtual", CupertinoIcons.tv_fill, Color(0xFFE50914), "R"),
  ]),
  const DayGroup("10 Jan", "£45.60", [
    Transaction("Wagamama", "£32.40", "19:30", "Current", Icons.dining, Colors.grey, "R"),
    Transaction("Odeon", "£13.20", "16:00", "Current", CupertinoIcons.ticket_fill, Colors.blue, "R"),
  ]),
  const DayGroup("05 Jan", "£220.00", [
    Transaction("IKEA", "£220.00", "14:00", "Current", CupertinoIcons.cube_box, Colors.yellow, "R"),
  ]),
  const DayGroup("01 Jan", "£65.00", [
    Transaction("Uber XL", "£45.00", "03:00", "Current", CupertinoIcons.car_fill, Colors.white, "R"),
    Transaction("McDonalds", "£20.00", "04:30", "Current", Icons.fastfood, Colors.red, "R"),
  ]),
];

// --- DECEMBER (High Spend) ---
final List<DayGroup> _decData = [
  const DayGroup("31 Dec, NYE", "£185.50", [
    Transaction("Uber XL", "£45.00", "02:30", "Current", CupertinoIcons.car_fill, Colors.white, "R"),
    Transaction("The Shard Bar", "£120.00", "23:45", "Current", Icons.wine_bar, Colors.purple, "R"),
    Transaction("Sainsbury's", "£20.50", "16:00", "Current", CupertinoIcons.cart, Colors.orange, "R"),
  ]),
  const DayGroup("24 Dec, Xmas Eve", "£210.20", [
    Transaction("Waitrose", "£85.00", "14:20", "Joint", CupertinoIcons.cart_fill, Color(0xFF5B8C5A), "HSBC"),
    Transaction("John Lewis", "£60.20", "11:00", "Current", CupertinoIcons.gift_fill, Colors.purple, "R"),
    Transaction("Fortnum & Mason", "£45.00", "10:15", "Current", CupertinoIcons.bag_fill, Colors.teal, "R"),
    Transaction("Starbucks", "£20.00", "09:00", "Current", Icons.coffee, Color(0xFF00704A), "R"),
  ]),
  const DayGroup("20 Dec (Travel)", "£142.50", [
    Transaction("Trainline", "£58.00", "09:30", "Virtual", CupertinoIcons.train_style_one, Colors.green, "R"),
    Transaction("Heathrow Express", "£25.00", "08:00", "Current", CupertinoIcons.tram_fill, Colors.purple, "R"),
    Transaction("Pret", "£9.50", "07:45", "Current", Icons.coffee, Colors.brown, "R"),
    Transaction("World Duty Free", "£50.00", "10:30", "Current", CupertinoIcons.bag_fill, Colors.black, "R"),
  ]),
  const DayGroup("15 Dec", "£850.00", [
    Transaction("Monthly Rent", "£850.00", "09:00", "Current", CupertinoIcons.house_fill, Colors.blueAccent, "HSBC"),
  ]),
  const DayGroup("10 Dec", "£45.00", [
    Transaction("Winter Wonderland", "£45.00", "19:00", "Current", CupertinoIcons.ticket_fill, Colors.red, "R"),
  ]),
  const DayGroup("05 Dec", "£120.00", [
    Transaction("Zara", "£80.00", "13:00", "Current", CupertinoIcons.bag_fill, Colors.white, "R"),
    Transaction("Nando's", "£40.00", "19:00", "Current", Icons.dining, Colors.orange, "R"),
  ]),
];

// --- NOVEMBER (Black Friday) ---
final List<DayGroup> _novData = [
  const DayGroup("29 Nov, Black Friday", "£1,040.00", [
    Transaction("Apple Store", "£899.00", "10:45", "Savings", Icons.laptop_mac, Colors.white, "R"),
    Transaction("Zara", "£85.00", "14:20", "Current", CupertinoIcons.bag_fill, Colors.white70, "R"),
    Transaction("Uniqlo", "£56.00", "13:00", "Current", CupertinoIcons.tag_fill, Colors.redAccent, "R"),
  ]),
  const DayGroup("28 Nov", "£45.20", [
    Transaction("Nando's", "£32.00", "19:00", "Current", Icons.dining, Colors.orange, "R"),
    Transaction("Uber", "£13.20", "22:00", "Current", CupertinoIcons.car_fill, Colors.white, "R"),
  ]),
  const DayGroup("15 Nov", "£22.00", [
    Transaction("Odeon", "£22.00", "20:00", "Current", CupertinoIcons.film, Colors.blue, "R"),
  ]),
  const DayGroup("05 Nov", "£65.00", [
    Transaction("Thames Water", "£45.00", "09:00", "Bills", CupertinoIcons.drop_fill, Colors.blueAccent, "HSBC"),
     Transaction("EE Mobile", "£20.00", "09:00", "Bills", CupertinoIcons.device_phone_portrait, Colors.teal, "HSBC"),
  ]),
  const DayGroup("01 Nov", "£1,450.00", [
    Transaction("London Rent", "£1,400.00", "09:00", "Current", CupertinoIcons.house_fill, Colors.blueAccent, "HSBC"),
    Transaction("Gymbox", "£50.00", "06:00", "Current", Icons.fitness_center, Colors.orange, "R"),
  ]),
];

// --- OCTOBER (Regular) ---
final List<DayGroup> _octData = [
  const DayGroup("31 Oct, Halloween", "£85.40", [
    Transaction("Uber", "£22.50", "23:45", "Current", CupertinoIcons.car_fill, Colors.white, "HSBC"),
    Transaction("The Alchemist", "£62.90", "20:30", "Current", Icons.local_bar, Colors.purpleAccent, "R"),
  ]),
  const DayGroup("25 Oct", "£320.00", [
    Transaction("Waitrose", "£120.00", "18:00", "Joint", CupertinoIcons.cart_fill, Color(0xFF5B8C5A), "HSBC"),
    Transaction("Council Tax", "£200.00", "09:00", "Bills", CupertinoIcons.building_2_fill, Colors.grey, "HSBC"),
  ]),
  const DayGroup("15 Oct", "£54.00", [
    Transaction("Vue Cinema", "£24.00", "19:30", "Current", CupertinoIcons.film, Colors.orange, "R"),
    Transaction("Pizza Express", "£30.00", "18:00", "Current", Icons.local_pizza, Colors.blue, "R"),
  ]),
  const DayGroup("10 Oct", "£38.50", [
    Transaction("Pret Subscription", "£30.00", "09:00", "Current", Icons.coffee, Colors.brown, "R", isPending: true),
    Transaction("Tesco", "£8.50", "13:00", "Current", CupertinoIcons.cart, Colors.blue, "R"),
  ]),
  const DayGroup("02 Oct", "£12.99", [
    Transaction("Amazon Prime", "£12.99", "10:00", "Virtual", CupertinoIcons.play_rectangle_fill, Colors.blueAccent, "R"),
  ]),
  const DayGroup("01 Oct", "£45.00", [
    Transaction("Virgin Media", "£45.00", "09:00", "Bills", CupertinoIcons.wifi, Colors.red, "HSBC"),
  ]),
];

// --- SEPTEMBER (Back to School) ---
final List<DayGroup> _sepData = [
  const DayGroup("28 Sep", "£45.00", [
    Transaction("Waterstones", "£25.00", "14:00", "Current", CupertinoIcons.book_fill, Colors.black, "R"),
    Transaction("Starbucks", "£20.00", "15:30", "Current", Icons.coffee, Color(0xFF00704A), "R"),
  ]),
  const DayGroup("15 Sep", "£62.00", [
    Transaction("Spotify", "£12.00", "10:00", "Virtual", CupertinoIcons.music_note_2, Colors.green, "R"),
    Transaction("Gymshark", "£50.00", "11:00", "Current", Icons.fitness_center, Colors.blueGrey, "R"),
  ]),
  const DayGroup("10 Sep", "£350.00", [
    Transaction("Eurostar", "£150.00", "09:00", "Current", CupertinoIcons.train_style_one, Colors.blue, "HSBC"),
    Transaction("Airbnb", "£200.00", "09:05", "Current", CupertinoIcons.house_alt, Colors.redAccent, "HSBC"),
  ]),
  const DayGroup("05 Sep", "£8.99", [
    Transaction("Audible", "£8.99", "10:00", "Virtual", CupertinoIcons.headphones, Colors.orange, "R"),
  ]),
  const DayGroup("01 Sep", "£1,400.00", [
    Transaction("London Rent", "£1,400.00", "09:00", "Current", CupertinoIcons.house_fill, Colors.blueAccent, "HSBC"),
  ]),
  const DayGroup("02 Sep", "£15.00", [
    Transaction("Uber Eats", "£15.00", "19:00", "Current", Icons.fastfood, Colors.green, "R"),
  ]),
];

// ==============================================================================
//  HELPER WIDGETS
// ==============================================================================

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String date;
  final String total;

  _StickyHeaderDelegate({required this.date, required this.total});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF000000).withValues(alpha: 0.95), 
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
          Text(total, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 36;
  @override
  double get minExtent => 36;
  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) => true; 
}

class _TransactionTile extends StatelessWidget {
  final String title, time, amount, account, bankLogo;
  final IconData iconData;
  final Color iconColor;
  final bool isPositive;
  final bool isPending;

  const _TransactionTile({
    required this.title, required this.time, required this.amount, required this.account,
    required this.iconData, required this.iconColor, required this.bankLogo,
    this.isPositive = false, this.isPending = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: const BoxDecoration(color: Colors.transparent),
            child: Stack(
              children: [
                Align(alignment: Alignment.center, child: Icon(iconData, color: iconColor, size: 28)),
                if (title.contains("TFL") || title.contains("Uber"))
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                      child: const Icon(CupertinoIcons.location_fill, color: Colors.blueAccent, size: 8),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    if (isPending) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(4)),
                        child: const Text("PENDING", style: TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: TextStyle(color: isPositive ? const Color(0xFF00E676) : Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(account, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  const SizedBox(width: 6),
                  if (bankLogo == 'R') const Icon(Icons.currency_pound, color: Colors.white, size: 12)
                  else if (bankLogo == 'HSBC') const Icon(CupertinoIcons.hexagon_fill, color: Colors.red, size: 12)
                  else const Icon(Icons.circle, color: Colors.white, size: 10),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (isPending) return _PulseOpacity(child: content);
    return content;
  }
}

class _PulseOpacity extends StatefulWidget {
  final Widget child;
  const _PulseOpacity({required this.child});
  @override
  State<_PulseOpacity> createState() => _PulseOpacityState();
}
class _PulseOpacityState extends State<_PulseOpacity> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true); }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _c, builder: (_, __) => Opacity(opacity: 0.5 + (_c.value * 0.5), child: widget.child));
}

// --- SHARED VISUALS ---

class _LivingAurora extends StatelessWidget {
  final AnimationController controller;
  final Color baseColor; 
  const _LivingAurora({required this.controller, required this.baseColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return Stack(
          children: [
            Positioned(
              top: -200 + (math.sin(t) * 50),
              right: -100 + (math.cos(t) * 30),
              child: _GlowOrb(color: baseColor.withValues(alpha: 0.15)),
            ),
            Positioned(
              top: 300,
              left: -150 + (math.sin(t + 2) * 60),
              child: _GlowOrb(color: const Color(0xFF00E5FF).withValues(alpha: 0.1)),
            ),
          ],
        );
      },
    );
  }
}

class _FilmGrain extends StatelessWidget {
  const _FilmGrain();
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GrainPainter(), child: Container());
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    final random = math.Random();
    for (int i = 0; i < 5000; i++) {
      canvas.drawRect(Rect.fromLTWH(random.nextDouble() * size.width, random.nextDouble() * size.height, 1, 1), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});
  @override
  Widget build(BuildContext context) => AnimatedContainer(duration: const Duration(seconds: 1), width: 600, height: 600, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
}

class _BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _BouncingButton({required this.child, required this.onTap});
  @override
  State<_BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<_BouncingButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  @override
  void initState() {
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(animation: _scale, builder: (_, child) => Transform.scale(scale: _scale.value, child: widget.child)),
    );
  }
}