import 'dart:ui';
// ignore: unused_import
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late final AnimationController _cardShimmerController;
  late final AnimationController _pulseController;
  late final AnimationController _slideController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 1. CARD SHIMMER
    _cardShimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // 2. HEALTH/SECURITY PULSE
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 3. ENTRY ANIMATION
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _cardShimmerController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getAdaptiveGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 18) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // 1. AMBIENT BACKGROUND
          const _AmbientBackground(),

          // 2. SCROLLABLE CONTENT
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 2.1 NAV BAR
              SliverAppBar(
                backgroundColor: Colors.transparent,
                expandedHeight: 60,
                floating: false,
                pinned: true,
                leading: _BouncingButton(
                  onTap: () {
                    HapticFeedback.lightImpact(); // Micro-haptic
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    // FIXED: Arrow Left
                    child: const Icon(CupertinoIcons.arrow_left, color: Colors.white, size: 20),
                  ),
                ),
                flexibleSpace: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.black.withOpacity(0.2)),
                  ),
                ),
                title: const Text(
                  'Command Center',
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  _BouncingButton(
                    onTap: () => HapticFeedback.selectionClick(),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: const Text(
                        'Edit',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                ],
              ),

              // 2.2 PROFILE CONTENT
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: FadeTransition(
                    opacity: _slideController,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        
                        // --- IDENTITY HERO ---
                        _CupertinoAvatar(pulseController: _pulseController),
                        
                        const SizedBox(height: 24),
                        
                        // ADAPTIVE GREETING
                        Text(
                          '${_getAdaptiveGreeting()}, Test User',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: '.SF Pro Display',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // SYSTEM PRESENCE & SECURITY
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _SystemPresenceBadge(),
                            const SizedBox(width: 8),
                            _SecurityCapsule(pulseController: _pulseController),
                          ],
                        ),
                        
                        const SizedBox(height: 32),

                        // --- INTELLIGENCE INSIGHT STRIP (NEW) ---
                        const _IntelligenceInsight(
                          message: "Safe-to-spend looks good. You're £120 under budget this week.",
                        ),

                        const SizedBox(height: 24),
                        
                        // --- HOLOGRAPHIC CARD ---
                        _HolographicCard(shimmerController: _cardShimmerController),
                        
                        const SizedBox(height: 32),

                        // --- LINKED INSTITUTIONS (OPEN BANKING) ---
                        _SectionHeader('LINKED ACCOUNTS'),
                        const SizedBox(height: 12),
                        const _LinkedInstitutionsRow(),

                        const SizedBox(height: 32),

                        // --- PLAN LIMITS ---
                        _SectionHeader('PLAN LIMITS'),
                        const SizedBox(height: 12),
                        _UsageBar(
                          label: 'ATM Withdrawals', 
                          spend: '£200', 
                          limit: '£800', 
                          percent: 0.25, 
                          color: Colors.greenAccent
                        ),
                        const SizedBox(height: 12),
                        _UsageBar(
                          label: 'FX Exchange', 
                          spend: '£4,500', 
                          limit: '£10,000', 
                          percent: 0.45, 
                          color: Colors.blueAccent
                        ),

                        const SizedBox(height: 32),

                        // --- SETTINGS: ACCOUNT ---
                        _SectionHeader('ACCOUNT'),
                        const SizedBox(height: 10),
                        _GlassGroup(
                          children: [
                            _SettingsTile(
                              icon: CupertinoIcons.person_crop_circle, 
                              title: 'Personal Details', 
                              color: Colors.blue,
                            ),
                            _SettingsTile(
                              icon: CupertinoIcons.doc_text_fill, 
                              title: 'Tax Residency', 
                              color: Colors.orange,
                            ),
                            _SettingsTile(
                              icon: CupertinoIcons.creditcard_fill, 
                              title: 'Cards & Apple Pay', 
                              color: Colors.purple,
                              isLast: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- SETTINGS: WEALTH & SECURITY ---
                        _SectionHeader('WEALTH & SECURITY'),
                        const SizedBox(height: 10),
                        _GlassGroup(
                          children: [
                            _SettingsTile(
                              icon: CupertinoIcons.chart_bar_square_fill, 
                              title: 'Investment Profile', 
                              color: Colors.green,
                            ),
                            _SettingsTile(
                              icon: CupertinoIcons.shield_fill, 
                              title: 'Security Privacy', 
                              color: Colors.indigo,
                              trailing: const _StatusBadge(text: 'Strong', color: Colors.green),
                            ),
                            _SettingsTile(
                              icon: CupertinoIcons.lock_rotation, 
                              title: 'App Lock', 
                              color: Colors.red,
                              trailing: const Text('Face ID', style: TextStyle(color: Colors.white54, fontSize: 13)),
                              isLast: true,
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // LOGOUT
                        _BouncingButton(
                          onTap: (){ HapticFeedback.heavyImpact(); },
                          child: const Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          'VYLT System v2.1.0 (Build 305)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   NEW FEATURES: INTELLIGENCE & SECURITY
   ============================================================ */

// 🧠 INTELLIGENCE INSIGHT STRIP
class _IntelligenceInsight extends StatelessWidget {
  final String message;
  const _IntelligenceInsight({required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.sparkles, color: Colors.blueAccent, size: 16),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🛡 SECURITY STATUS CAPSULE
class _SecurityCapsule extends StatelessWidget {
  final AnimationController pulseController;
  const _SecurityCapsule({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF00E676).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00E676).withOpacity(0.3 + (0.2 * pulseController.value)),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withOpacity(0.1 * pulseController.value),
                blurRadius: 8,
              )
            ]
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.shield_fill, color: const Color(0xFF00E676).withOpacity(0.9), size: 12),
              const SizedBox(width: 6),
              const Text(
                'Secured',
                style: TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 🕒 SYSTEM PRESENCE
class _SystemPresenceBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Online • London',
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/* ============================================================
   CORE WIDGETS
   ============================================================ */

// 3. CUPERTINO AVATAR
class _CupertinoAvatar extends StatelessWidget {
  final AnimationController pulseController;
  const _CupertinoAvatar({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Breathing Glow
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0A84FF).withOpacity(0.2 * pulseController.value),
                  width: 2,
                ),
              ),
            ),
            // The Icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C1E),
                border: Border.all(color: Colors.white12, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0A84FF).withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: const Center(
                child: Icon(
                  CupertinoIcons.person_crop_circle_fill, 
                  size: 100, 
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LinkedInstitutionsRow extends StatelessWidget {
  const _LinkedInstitutionsRow();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        children: [
          _BankIcon(label: 'Monzo', color: const Color(0xFFFF4D4D), icon: CupertinoIcons.at_circle_fill),
          _BankIcon(label: 'Revolut', color: Colors.white, icon: CupertinoIcons.square_fill, isWhite: true),
          _BankIcon(label: 'Barclays', color: const Color(0xFF00A4E4), icon: CupertinoIcons.building_2_fill),
          _BankIcon(label: 'Coinbase', color: const Color(0xFF0052FF), icon: CupertinoIcons.bitcoin_circle_fill),
          _AddBankButton(),
        ],
      ),
    );
  }
}

class _BankIcon extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isWhite;

  const _BankIcon({required this.label, required this.color, required this.icon, this.isWhite = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _AddBankButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1), style: BorderStyle.solid),
            ),
            child: const Center(
              child: Icon(CupertinoIcons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          const Text('Link', style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final String spend;
  final String limit;
  final double percent;
  final Color color;

  const _UsageBar({
    required this.label, required this.spend, required this.limit, required this.percent, required this.color
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: spend, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  TextSpan(text: ' / $limit', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                ],
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(color: color.withOpacity(0.5), blurRadius: 6, offset: const Offset(0, 2))
                ]
              ),
            ),
          ),
        )
      ],
    );
  }
}

class _HolographicCard extends StatelessWidget {
  final AnimationController shimmerController;
  const _HolographicCard({required this.shimmerController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerController,
      builder: (context, _) {
        return Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C1C1E), Color(0xFF000000)],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: [
                          shimmerController.value - 0.2,
                          shimmerController.value,
                          shimmerController.value + 0.2,
                        ],
                        transform: GradientRotation(shimmerController.value * 0.5),
                      ).createShader(bounds);
                    },
                    child: Container(color: Colors.white.withOpacity(0.05)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(CupertinoIcons.hexagon_fill, color: Colors.white, size: 28),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('METAL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text('•••• 4291', style: TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 20, letterSpacing: 3.0)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('CARD HOLDER', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('TEST USER', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('EXPIRES', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              const Text('12/28', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassGroup extends StatelessWidget {
  final List<Widget> children;
  const _GlassGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool isLast;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon, required this.title, required this.color, this.isLast = false, this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return _BouncingButton(
      onTap: () {
        HapticFeedback.selectionClick();
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Text(title, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
            const Icon(CupertinoIcons.chevron_right, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
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

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: const Color(0xFF000000)),
        Positioned(top: -150, left: -100, child: _GlowOrb(color: const Color(0xFF4A00E0).withOpacity(0.15))),
        Positioned(bottom: -150, right: -100, child: _GlowOrb(color: const Color(0xFF00E5FF).withOpacity(0.1))),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  const _GlowOrb({required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(width: 500, height: 500, decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])));
  }
}