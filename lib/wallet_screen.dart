import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with TickerProviderStateMixin {
  // 1. ANIMATION CONTROLLERS
  late final AnimationController _flipController;
  late final AnimationController _shimmerController;
  late final AnimationController _freezeController;
  late final AnimationController _pulseController;
  late final PageController _cardPageController;

  // 2. STATE VARIABLES
  bool _isFrozen = false;
  bool _isRevealActive = false; // For biometric reveal
  double _dragX = 0.0;
  double _dragY = 0.0;
  double _spendingLimit = 2500.0;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    // FLIP PHYSICS
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      reverseDuration: const Duration(milliseconds: 800),
    );

    // HOLOGRAPHIC SHIMMER
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // FREEZE EFFECT
    _freezeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // PULSE (For active indicators)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _cardPageController = PageController(viewportFraction: 0.85);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shimmerController.dispose();
    _freezeController.dispose();
    _pulseController.dispose();
    _cardPageController.dispose();
    super.dispose();
  }

  // --- INTERACTION METHODS ---

  void _onCardDrag(DragUpdateDetails details) {
    setState(() {
      // Sensitivity factor for 3D tilt
      _dragX += details.delta.dx * 0.001; 
      _dragY -= details.delta.dy * 0.001;
      
      // Clamp tilt to prevent flipping over
      _dragX = _dragX.clamp(-0.15, 0.15);
      _dragY = _dragY.clamp(-0.15, 0.15);
    });
  }

  void _onCardDragEnd(DragEndDetails details) {
    // Spring back to center
    setState(() {
      _dragX = 0.0;
      _dragY = 0.0;
    });
  }

  void _toggleCardFlip() {
    HapticFeedback.mediumImpact();
    if (_flipController.status == AnimationStatus.dismissed) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _toggleFreeze() {
    HapticFeedback.heavyImpact();
    setState(() => _isFrozen = !_isFrozen);
    if (_isFrozen) {
      _freezeController.forward();
    } else {
      _freezeController.reverse();
    }
  }

  void _onBiometricPress() async {
    HapticFeedback.mediumImpact();
    // Simulate FaceID scan delay
    setState(() => _isRevealActive = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      HapticFeedback.heavyImpact();
      // Show PIN (Logic would go here)
      setState(() => _isRevealActive = false);
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    showCupertinoDialog(
      context: context, 
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('PIN Revealed'),
        content: const Text('Your PIN is 8492. It will auto-hide in 5 seconds.'),
        actions: [CupertinoDialogAction(child: const Text('Done'), onPressed: () => Navigator.pop(ctx))],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          const _AmbientBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // 1. CUSTOM NAV BAR
                _buildNavBar(context),

                const SizedBox(height: 10),

                // 2. THE STAGE (Scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // --- 3D GYRO-CARD ---
                        SizedBox(
                          height: 260,
                          child: PageView.builder(
                            controller: _cardPageController,
                            onPageChanged: (index) {
                              HapticFeedback.selectionClick();
                              setState(() => _currentCardIndex = index);
                              if (_flipController.isCompleted) _flipController.reverse();
                            },
                            itemCount: 3,
                            itemBuilder: (context, index) {
                              // Only interactive if it's the active card
                              if (index != _currentCardIndex) {
                                return _buildStaticCard(index);
                              }
                              return GestureDetector(
                                onPanUpdate: _onCardDrag,
                                onPanEnd: _onCardDragEnd,
                                onTap: _toggleCardFlip,
                                child: AnimatedBuilder(
                                  animation: Listenable.merge([_flipController, _freezeController]),
                                  builder: (context, child) {
                                    // Combine Flip + Drag Tilt
                                    final flipAngle = _flipController.value * math.pi;
                                    final isBack = flipAngle > math.pi / 2;
                                    
                                    // Matrix Math for 3D
                                    final matrix = Matrix4.identity()
                                      ..setEntry(3, 2, 0.001) // Perspective
                                      ..rotateY(flipAngle + (_dragX * 5)) // Rotate Y (Flip + Tilt)
                                      ..rotateX(_dragY * 5); // Rotate X (Tilt)

                                    return Transform(
                                      transform: matrix,
                                      alignment: Alignment.center,
                                      child: isBack
                                          ? Transform(
                                              alignment: Alignment.center,
                                              transform: Matrix4.identity()..rotateY(math.pi),
                                              child: _CardBack(isFrozen: _isFrozen),
                                            )
                                          : _CardFront(
                                              shimmerController: _shimmerController, 
                                              freezeController: _freezeController,
                                              cardType: index,
                                            ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),

                        // --- PAGE INDICATOR ---
                        const SizedBox(height: 20),
                        _buildPageIndicator(),

                        const SizedBox(height: 40),

                        // --- CONTROL DECK ---
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // QUICK ACTIONS (Glass Grid)
                              _SectionHeader('COMMAND CENTER'),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _GlassActionButton(
                                    icon: _isFrozen ? CupertinoIcons.lock_open_fill : CupertinoIcons.snow,
                                    label: _isFrozen ? 'Unfreeze' : 'Freeze',
                                    isActive: _isFrozen,
                                    activeColor: Colors.blueAccent,
                                    onTap: _toggleFreeze,
                                  ),
                                  _GlassActionButton(
                                    icon: _isRevealActive ? CupertinoIcons.lock_shield_fill : CupertinoIcons.eye_fill,
                                    label: _isRevealActive ? 'Scanning...' : 'Show PIN',
                                    isActive: _isRevealActive,
                                    activeColor: Colors.purpleAccent,
                                    onTap: _onBiometricPress, // Simulates Long Press/Scan
                                  ),
                                  _GlassActionButton(
                                    icon: CupertinoIcons.slider_horizontal_3,
                                    label: 'Limits',
                                    isActive: false,
                                    activeColor: Colors.orangeAccent,
                                    onTap: () {},
                                  ),
                                  _GlassActionButton(
                                    icon: CupertinoIcons.settings,
                                    label: 'Manage',
                                    isActive: false,
                                    activeColor: Colors.grey,
                                    onTap: () {},
                                  ),
                                ],
                              ),

                              const SizedBox(height: 32),

                              // NEON SLIDER
                              _SectionHeader('MONTHLY ALLOWANCE'),
                              const SizedBox(height: 12),
                              _NeonSpendingSlider(
                                value: _spendingLimit, 
                                onChanged: (val) {
                                  setState(() => _spendingLimit = val);
                                  HapticFeedback.selectionClick();
                                }
                              ),

                              const SizedBox(height: 32),

                              // HIGH-FIDELITY SETTINGS
                              _SectionHeader('SECURITY PROTOCOLS'),
                              const SizedBox(height: 12),
                              _GlassSettingsContainer(
                                children: [
                                  _SecurityToggleRow(
                                    icon: CupertinoIcons.wifi, 
                                    label: 'Contactless Payments', 
                                    initValue: true
                                  ),
                                  _Divider(),
                                  _SecurityToggleRow(
                                    icon: CupertinoIcons.globe, 
                                    label: 'Online Transactions', 
                                    initValue: true
                                  ),
                                  _Divider(),
                                  _SecurityToggleRow(
                                    icon: CupertinoIcons.money_dollar_circle, 
                                    label: 'ATM Withdrawals', 
                                    initValue: false
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),
                              
                              // DESTRUCTIVE ACTION
                              if (_currentCardIndex == 2) 
                                _buildDestroyButton(),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassCircleButton(
            icon: CupertinoIcons.arrow_left, 
            onTap: () => Navigator.pop(context)
          ),
          const Text(
            'The Vault',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          _GlassCircleButton(
            icon: CupertinoIcons.add, 
            onTap: () {}, 
            color: const Color(0xFF0A84FF)
          ),
        ],
      ),
    );
  }

  Widget _buildStaticCard(int index) {
    return Transform.scale(
      scale: 0.9,
      child: Opacity(
        opacity: 0.5,
        child: _CardFront(
          shimmerController: _shimmerController, 
          freezeController: _freezeController, // Doesn't matter here
          cardType: index, 
          isFrozen: false,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: _currentCardIndex == index ? 24 : 6,
        height: 6,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: _currentCardIndex == index ? const Color(0xFF0A84FF) : Colors.white12,
          boxShadow: _currentCardIndex == index ? [
            BoxShadow(color: const Color(0xFF0A84FF).withOpacity(0.5), blurRadius: 8)
          ] : [],
        ),
      )),
    );
  }

  Widget _buildDestroyButton() {
    return _BouncingButton(
      onTap: () => HapticFeedback.heavyImpact(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFF375F).withOpacity(0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFF375F).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(CupertinoIcons.trash, color: Color(0xFFFF375F), size: 18),
            SizedBox(width: 8),
            Text('Destroy Disposable Card', style: TextStyle(color: Color(0xFFFF375F), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   THE HYPER-CARD (Physics & Visuals)
   ============================================================ */

class _CardFront extends StatelessWidget {
  final AnimationController shimmerController;
  final AnimationController freezeController;
  final int cardType; // 0: Metal, 1: Virtual, 2: Disposable
  final bool isFrozen;

  const _CardFront({
    required this.shimmerController, 
    required this.freezeController,
    required this.cardType,
    this.isFrozen = false,
  });

  @override
  Widget build(BuildContext context) {
    // Card Style Config
    Color baseColor;
    String cardLabel;
    IconData cardIcon;
    List<Color> gradients;
    
    if (cardType == 0) { // METAL
      baseColor = const Color(0xFF1C1C1E);
      cardLabel = 'METAL';
      cardIcon = CupertinoIcons.hexagon_fill;
      gradients = [const Color(0xFF2C2C2E), const Color(0xFF000000)];
    } else if (cardType == 1) { // VIRTUAL
      baseColor = const Color(0xFF0A84FF);
      cardLabel = 'VIRTUAL';
      cardIcon = CupertinoIcons.cloud_fill;
      gradients = [const Color(0xFF00C6FF), const Color(0xFF0072FF)];
    } else { // DISPOSABLE
      baseColor = const Color(0xFFFF375F);
      cardLabel = 'GHOST';
      cardIcon = CupertinoIcons.flame_fill;
      gradients = [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)];
    }

    return AnimatedBuilder(
      animation: freezeController,
      builder: (context, child) {
        final freezeVal = freezeController.value;
        
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          height: 220,
          width: 340,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              // Color lerp for freeze effect
              colors: [
                Color.lerp(gradients[0], const Color(0xFF90A4AE), freezeVal)!,
                Color.lerp(gradients[1], const Color(0xFF37474F), freezeVal)!,
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1 + (freezeVal * 0.2)),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color.lerp(baseColor.withOpacity(0.4), const Color(0xFF90A4AE).withOpacity(0.2), freezeVal)!,
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 1. Shimmer Effect (Moves continuously)
              if (freezeVal < 1.0)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: shimmerController,
                    builder: (context, _) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.transparent, Colors.white.withOpacity(0.15), Colors.transparent],
                            stops: [
                              shimmerController.value - 0.2,
                              shimmerController.value,
                              shimmerController.value + 0.2,
                            ],
                            transform: GradientRotation(shimmerController.value * 0.5),
                          ).createShader(bounds);
                        },
                        child: Container(color: Colors.white.withOpacity(0.05)),
                      );
                    },
                  ),
                ),
              
              // 2. Frost Overlay (Appears when frozen)
              if (freezeVal > 0)
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5 * freezeVal, sigmaY: 5 * freezeVal),
                    child: Container(color: Colors.white.withOpacity(0.1 * freezeVal)),
                  ),
                ),

              // 3. Card Details
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(cardIcon, color: Colors.white.withOpacity(0.9), size: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            freezeVal > 0.5 ? 'FROZEN' : cardLabel, 
                            style: TextStyle(
                              color: freezeVal > 0.5 ? const Color(0xFF90A4AE) : Colors.white, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 1.5,
                              fontSize: 12,
                            )
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text('•••• •••• •••• 4291', 
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9), 
                        fontFamily: 'Courier', 
                        fontSize: 22, 
                        letterSpacing: 3,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 2, offset: Offset(1,1))]
                      )
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ALEX MORGAN', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        Text('12/28', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              
              // 4. Lock Icon (Centers when frozen)
              if (freezeVal > 0.1)
                Center(
                  child: Opacity(
                    opacity: freezeVal,
                    child: const Icon(CupertinoIcons.snow, color: Colors.white, size: 60),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CardBack extends StatelessWidget {
  final bool isFrozen;
  const _CardBack({required this.isFrozen});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      height: 220,
      width: 340,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFF1C1C1E),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 30),
              Container(height: 50, color: Colors.black),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(width: 200, height: 40, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(width: 10),
                    const Text('842', style: TextStyle(color: Colors.white, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Issuing Bank: VYLT Financial Ltd.\nSupport: +44 800 000 000', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 10)),
              ),
            ],
          ),
          if (isFrozen)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.1)),
              ),
            ),
        ],
      ),
    );
  }
}

/* ============================================================
   UI COMPONENTS (GLASS & NEON)
   ============================================================ */

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon, required this.label, required this.isActive, required this.activeColor, required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return _BouncingButton(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.2) : const Color(0xFF1C1C1E).withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isActive ? activeColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                width: 1.5,
              ),
              boxShadow: isActive ? [BoxShadow(color: activeColor.withOpacity(0.3), blurRadius: 12)] : [],
            ),
            child: Icon(icon, color: isActive ? activeColor : Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            label, 
            style: TextStyle(
              color: isActive ? activeColor : Colors.white54, 
              fontSize: 12, 
              fontWeight: FontWeight.w600
            )
          ),
        ],
      ),
    );
  }
}

class _NeonSpendingSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _NeonSpendingSlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withOpacity(0.6),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Monthly Limit', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('£${value.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Safe', style: TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 30,
            child: CupertinoSlider(
              value: value,
              min: 0,
              max: 5000,
              activeColor: const Color(0xFF0A84FF),
              thumbColor: Colors.white,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassSettingsContainer extends StatelessWidget {
  final List<Widget> children;
  const _GlassSettingsContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E).withOpacity(0.6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(children: children),
        ),
      ),
    );
  }
}

class _SecurityToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool initValue;

  const _SecurityToggleRow({required this.icon, required this.label, required this.initValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white70, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
          CupertinoSwitch(
            value: initValue, 
            activeTrackColor: const Color(0xFF00E676),
            onChanged: (val) => HapticFeedback.selectionClick(),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _GlassCircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return _BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? Colors.white).withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: color ?? Colors.white, size: 22),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, color: Colors.white.withOpacity(0.05), indent: 64);
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
        Positioned(
          top: -200, left: -100,
          child: Container(
            width: 500, height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [const Color(0xFF2C3E50).withOpacity(0.2), Colors.transparent]),
            ),
          ),
        ),
      ],
    );
  }
}