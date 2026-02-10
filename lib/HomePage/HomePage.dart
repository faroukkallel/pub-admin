import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'dart:ui';

class AppAssets {
  static const String logo = 'assets/prest-zone-logo-removebg.png';
  static const String product1 = 'assets/machine1.png';
  static const String product2 = 'assets/machine2.png';
  static const String machine1 = 'assets/machine1.png';
  static const String machine2 = 'assets/machine2.png';
  static const String machine3 = 'assets/machine3.png';
  static const String machine4 = 'assets/machine4.png';
  static const String machine5 = 'assets/machine5.png';
  static const String machine6 = 'assets/machine6.png';
  static const String machine7 = 'assets/machine7.png';
  static const String arenaLocation = 'assets/arena_location.png';
  static const String logoArenaGym = 'assets/arenagym.jpg';
  static const String logoDigits = 'assets/digits.jpg';
  static const String logoZebraClub = 'assets/zebraclub.jpg';
  static const String logoMahParis = 'assets/mahparis.png';
  static const String logoFatales = 'assets/fatales.png';
  static const String facebook = 'assets/facebook.png';
  static const String instagram = 'assets/instagram.png';
}

class AnimateIfVisible extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset slideBegin;
  final double fadeBegin;

  const AnimateIfVisible({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.slideBegin = Offset.zero,
    this.fadeBegin = 0.0,
  }) : super(key: key);

  @override
  _AnimateIfVisibleState createState() => _AnimateIfVisibleState();
}

class _AnimateIfVisibleState extends State<AnimateIfVisible>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _slideAnimation = Tween<Offset>(begin: widget.slideBegin, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: widget.fadeBegin, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!_triggered && info.visibleFraction > 0.1) {
      _triggered = true;
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(position: _slideAnimation, child: widget.child),
      ),
    );
  }
}

class ScaleOnHover extends StatefulWidget {
  final Widget child;
  final double scale;

  const ScaleOnHover({Key? key, required this.child, this.scale = 1.05})
      : super(key: key);

  @override
  _ScaleOnHoverState createState() => _ScaleOnHoverState();
}

class _ScaleOnHoverState extends State<ScaleOnHover> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: widget.child,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _machinesKey = GlobalKey();
  final GlobalKey _publiciteKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _partnersKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _showAppBar = true;
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll > _lastScrollPosition && currentScroll > 100) {
      if (_showAppBar) setState(() => _showAppBar = false);
    } else {
      if (!_showAppBar) setState(() => _showAppBar = true);
    }
    _lastScrollPosition = currentScroll;
  }

  void _scrollToSection(String section) {
    Navigator.of(context).pop();

    GlobalKey? targetKey;
    switch (section) {
      case 'home':
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
        return;
      case 'about':
        targetKey = _aboutKey;
        break;
      case 'machines':
        targetKey = _machinesKey;
        break;
      case 'publicite':
        targetKey = _publiciteKey;
        break;
      case 'location':
        targetKey = _locationKey;
        break;
      case 'partners':
        targetKey = _partnersKey;
        break;
      case 'contact':
        targetKey = _contactKey;
        break;
    }

    if (targetKey?.currentContext != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        Scrollable.ensureVisible(
          targetKey!.currentContext!,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width <= 768;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F6F4),
      drawer: _buildDrawer(isMobile),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ImageCarouselSection(isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: _buildGoldDivider(isMobile)),
              SliverToBoxAdapter(
                child: FAQSection(key: _aboutKey, isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: _buildGoldDivider(isMobile)),
              SliverToBoxAdapter(
                child: MachinesSection(key: _machinesKey, isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: _buildGoldDivider(isMobile)),
              SliverToBoxAdapter(
                child: PubliciteSection(key: _publiciteKey, isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: _buildGoldDivider(isMobile)),
              SliverToBoxAdapter(
                child: LocationSection(key: _locationKey, isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: _buildGoldDivider(isMobile)),
              SliverToBoxAdapter(
                child: PartnersSection(key: _partnersKey, isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: _buildGoldDivider(isMobile)),
              SliverToBoxAdapter(
                child: ContactSection(key: _contactKey, isMobile: isMobile),
              ),
              SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
            ],
          ),
          _buildAppBar(isMobile),
        ],
      ),
    );
  }

  Widget _buildGoldDivider(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 60 : 200),
      child: Container(
        height: 1,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isMobile) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: _showAppBar ? Offset.zero : const Offset(0, -1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.black,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 15 : 40,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    AnimateIfVisible(
                      slideBegin: const Offset(-0.5, 0),
                      fadeBegin: 0,
                      duration: const Duration(milliseconds: 600),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimateIfVisible(
                      slideBegin: const Offset(0, -0.5),
                      fadeBegin: 0,
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: Container(
                        height: isMobile ? 40 : 50,
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        child: Image.asset(
                          AppAssets.logo,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Text(
                              'PREST ZONE',
                              style: GoogleFonts.montserrat(
                                color: Colors.white,
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isMobile) {
    final menuItems = [
      {'title': 'Accueil', 'key': 'home'},
      {'title': 'À Propos', 'key': 'about'},
      {'title': 'Nos Machines', 'key': 'machines'},
      {'title': 'Publicité de Luxe', 'key': 'publicite'},
      {'title': 'Où on se trouve', 'key': 'location'},
      {'title': 'Partenaires', 'key': 'partners'},
      {'title': 'Contact', 'key': 'contact'},
    ];

    return Drawer(
      backgroundColor: Colors.black,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.grey.shade900],
              ),
            ),
            child: Column(
              children: [
                Container(
                  height: 80,
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    AppAssets.logo,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          'PREST ZONE',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'LUX SERVICE',
                  style: GoogleFonts.montserrat(
                    color: const Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return AnimateIfVisible(
                  delay: Duration(milliseconds: 100 * index),
                  slideBegin: const Offset(-0.3, 0),
                  fadeBegin: 0,
                  child: ScaleOnHover(
                    scale: 1.02,
                    child: InkWell(
                      onTap: () => _scrollToSection(item['key'] as String),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: const Color(0xFFD4AF37).withOpacity(0.6),
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          item['title'] as String,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  '© 2025-2026 Prest Zone',
                  style: GoogleFonts.openSans(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.2),
                    ),
                  ),
                  child: Text(
                    'Développé par AFK',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFFD4AF37).withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class ImageCarouselSection extends StatefulWidget {
  final bool isMobile;

  const ImageCarouselSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  State<ImageCarouselSection> createState() => _ImageCarouselSectionState();
}

class _ImageCarouselSectionState extends State<ImageCarouselSection>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _pulseController;
  int _currentPage = 0;
  Timer? _timer;
  bool _userInteracting = false;

  final List<String> _images = [
    AppAssets.product1,
    AppAssets.product2,
    AppAssets.machine1,
    AppAssets.machine2,
    AppAssets.machine3,
    AppAssets.machine4,
    AppAssets.machine5,
    AppAssets.machine6,
    AppAssets.machine7,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!_userInteracting && mounted) {
        if (_currentPage < _images.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _onUserInteraction() {
    setState(() => _userInteracting = true);
    _timer?.cancel();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _userInteracting = false);
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * (widget.isMobile ? 0.75 : 0.8),
      child: Stack(
        children: [
          GestureDetector(
            onPanDown: (_) => _onUserInteraction(),
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Container(
                  color: const Color(0xFFF7F6F4),
                  child: Center(
                    child: AnimateIfVisible(
                      fadeBegin: 0,
                      slideBegin: index % 2 == 0 ? const Offset(-0.3, 0) : const Offset(0.3, 0),
                      duration: const Duration(milliseconds: 1000),
                      child: ScaleOnHover(
                        scale: 1.02,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: widget.isMobile
                                ? MediaQuery.of(context).size.width * 0.9
                                : 600,
                            maxHeight: MediaQuery.of(context).size.height * 0.7,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              _images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 400,
                                  height: 400,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.image,
                                        size: 100, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _images.length,
                    (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: _currentPage == index ? 35 : 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.black
                        : Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
          ),
          if (widget.isMobile)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Opacity(
                    opacity: 0.3 + (_pulseController.value * 0.7),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 30,
                        ),
                        Text(
                          'Découvrir',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class FAQSection extends StatelessWidget {
  final bool isMobile;

  const FAQSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 100,
        vertical: isMobile ? 60 : 100,
      ),
      color: Colors.white,
      child: Column(
        children: [
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            child: Text(
              'À PROPOS DE PREST ZONE',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Une startup tunisienne innovante',
              style: GoogleFonts.playfairDisplay(
                color: Colors.black,
                fontSize: isMobile ? 28 : 38,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Prest Zone est une startup tunisienne innovante, spécialisée dans les distributeurs automatiques haut de gamme intégrant des écrans publicitaires digitaux.',
              style: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: isMobile ? 15 : 18,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Notre mission est d\'introduire une nouvelle expérience de consommation et une nouvelle forme de publicité premium dans les lieux les plus prestigieux de Tunisie.',
              style: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: isMobile ? 15 : 18,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Grâce à nos dispositifs intelligents — combinant design, technologie et communication visuelle — nous transformons les distributeurs automatiques en supports publicitaires modernes offrant une visibilité ciblée et élégante aux marques de luxe, sportives et lifestyle.',
              style: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: isMobile ? 15 : 18,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 500),
            child: Text(
              'Chez Prest Zone, chaque machine devient un média, un point de contact exclusif entre les marques et une clientèle haut de gamme, alliant innovation, élégance et performance publicitaire.',
              style: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: isMobile ? 15 : 18,
                height: 1.8,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class MachinesSection extends StatelessWidget {
  final bool isMobile;

  const MachinesSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final machines = [
      {
        'title': 'Distributeur automatique de parfum',
        'image': AppAssets.machine1,
        'page': const Machine1DetailPage(),
      },
      {
        'title': 'Distributeur automatique multifonction',
        'image': AppAssets.machine2,
        'page': const Machine2DetailPage(),
      },
      {
        'title': 'Prest Zone Fresh',
        'image': AppAssets.machine3,
        'page': const Machine3DetailPage(),
      },
      {
        'title': 'Distributeur de shaker protéiné',
        'image': AppAssets.machine4,
        'page': const Machine4DetailPage(),
      },
      {
        'title': 'Nettoyage de casques',
        'image': AppAssets.machine5,
        'page': const Machine5DetailPage(),
      },
      {
        'title': 'Distributeur de maquillage',
        'image': AppAssets.machine6,
        'page': const Machine6DetailPage(),
      },
      {
        'title': 'Distributeur de serviettes',
        'image': AppAssets.machine7,
        'page': const Machine7DetailPage(),
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 100,
        vertical: isMobile ? 60 : 80,
      ),
      color: const Color(0xFFF7F6F4),
      child: Column(
        children: [
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            child: Text(
              'NOS MACHINES',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Découvrez nos solutions innovantes',
              style: GoogleFonts.playfairDisplay(
                color: Colors.black,
                fontSize: isMobile ? 28 : 42,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 50),
          isMobile
              ? Column(
            children: machines.asMap().entries.map((entry) {
              final index = entry.key;
              final machine = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _buildMachineCard(
                  context,
                  machine['title'] as String,
                  machine['image'] as String,
                      () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => machine['page'] as Widget,
                    ),
                  ),
                  index,
                  true,
                ),
              );
            }).toList(),
          )
              : LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth > 1100 ? 3 : 2;
              return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 30,
              mainAxisSpacing: 30,
              childAspectRatio: 0.75,
            ),
            itemCount: machines.length,
            itemBuilder: (context, index) {
              final machine = machines[index];
              return _buildMachineCard(
                context,
                machine['title'] as String,
                machine['image'] as String,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => machine['page'] as Widget,
                  ),
                ),
                index,
                false,
              );
            },
          );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMachineCard(
      BuildContext context,
      String title,
      String imagePath,
      VoidCallback onTap,
      int index,
      bool isMobile,
      ) {
    return AnimateIfVisible(
      slideBegin: isMobile
          ? (index % 2 == 0 ? const Offset(-0.5, 0) : const Offset(0.5, 0))
          : const Offset(0, 0.3),
      fadeBegin: 0,
      delay: Duration(milliseconds: 100 * index),
      child: ScaleOnHover(
        scale: 1.03,
        child: GestureDetector(
          onTap: onTap,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: Icon(Icons.devices,
                                        size: 80, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.playfairDisplay(
                                color: Colors.black,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Voir plus',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black.withOpacity(0.6),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward,
                                  color: Colors.black.withOpacity(0.6),
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PubliciteSection extends StatelessWidget {
  final bool isMobile;

  const PubliciteSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 100,
        vertical: isMobile ? 60 : 100,
      ),
      color: Colors.white,
      child: Column(
        children: [
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            child: Text(
              'PUBLICITÉ & COMMUNICATION',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Un nouveau média indoor premium',
              style: GoogleFonts.playfairDisplay(
                color: Colors.black,
                fontSize: isMobile ? 28 : 38,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.3, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Prest Zone révolutionne la publicité en Tunisie en introduisant un support de communication inédit : le distributeur automatique intelligent, alliant design, technologie et visibilité haut de gamme.',
              style: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: isMobile ? 15 : 18,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.3, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 300),
            child: Text(
              'Nos machines ne sont pas de simples distributeurs, mais de véritables médias digitaux indoor premium, conçus pour valoriser les marques de luxe et renforcer leur présence dans les lieux les plus prestigieux du pays.',
              style: GoogleFonts.openSans(
                color: Colors.black87,
                fontSize: isMobile ? 15 : 18,
                height: 1.8,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Objectifs atteints :',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: isMobile ? 20 : 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 25),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 500),
            child: Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F6F4).withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withOpacity(0.1),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildObjectivePoint(
                    '+ 70 % de visibilité visuelle grâce à un design attractif',
                    isMobile,
                  ),
                  const SizedBox(height: 15),
                  _buildObjectivePoint(
                    'Expérience client immersive = meilleure mémorisation publicitaire',
                    isMobile,
                  ),
                  const SizedBox(height: 15),
                  _buildObjectivePoint(
                    'Ciblage précis d\'une audience haut de gamme',
                    isMobile,
                  ),
                  const SizedBox(height: 15),
                  _buildObjectivePoint(
                    'Idéal pour les marques de parfums, luxe, sport & lifestyle',
                    isMobile,
                  ),
                  const SizedBox(height: 15),
                  _buildObjectivePoint(
                    'Solution all-in-one : communication + vente + branding',
                    isMobile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectivePoint(String text, bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              color: Colors.black87,
              fontSize: isMobile ? 15 : 17,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

class LocationSection extends StatelessWidget {
  final bool isMobile;

  const LocationSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 100,
        vertical: isMobile ? 60 : 100,
      ),
      color: const Color(0xFFF7F6F4),
      child: Column(
        children: [
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            child: Text(
              'OÙ ON SE TROUVE',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 40),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 200),
            child: ScaleOnHover(
              scale: 1.01,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocationDetailPage(),
                  ),
                ),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(24)),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxHeight: 300),
                                child: Image.asset(
                                  AppAssets.arenaLocation,
                                  width: double.infinity,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.grey[300],
                                      child: const Center(
                                        child: Icon(Icons.location_on,
                                            size: 80, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(30),
                              child: Column(
                                children: [
                                  Image.asset(
                                    AppAssets.logoArenaGym,
                                    height: 50,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.business, size: 50);
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Arena Gym Premium - La Soukra',
                                    style: GoogleFonts.poppins(
                                      color: Colors.black,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 15),
                                  Text(
                                    'Notre premier dispositif vient d\'être installé à Arena Gym Premium La Soukra...',
                                    style: GoogleFonts.openSans(
                                      color: Colors.black87,
                                      fontSize: 15,
                                      height: 1.6,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 15),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Voir plus de détails',
                                        style: GoogleFonts.poppins(
                                          color: Colors.black.withOpacity(0.6),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.black.withOpacity(0.6),
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PartnersSection extends StatelessWidget {
  final bool isMobile;

  const PartnersSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final partners = [
      {'name': 'Arena Gym', 'logo': AppAssets.logoArenaGym},
      {'name': 'Digit\'s', 'logo': AppAssets.logoDigits},
      {'name': 'Zebra Club', 'logo': AppAssets.logoZebraClub},
      {'name': 'Mah Paris', 'logo': AppAssets.logoMahParis},
      {'name': 'Fatales', 'logo': AppAssets.logoFatales},
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 100,
        vertical: isMobile ? 60 : 100,
      ),
      color: Colors.white,
      child: Column(
        children: [
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            child: Text(
              'NOS PARTENAIRES',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 40),
          isMobile
              ? Column(
            children: partners.asMap().entries.map((entry) {
              final index = entry.key;
              final partner = entry.value;
              return AnimateIfVisible(
                slideBegin: index % 2 == 0 ? const Offset(-0.5, 0) : const Offset(0.5, 0),
                fadeBegin: 0,
                delay: Duration(milliseconds: 150 * index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: _buildPartnerCard(partner),
                ),
              );
            }).toList(),
          )
              : LayoutBuilder(
            builder: (context, constraints) {
              final availWidth = constraints.maxWidth;
              final cols = availWidth > 1000 ? 3 : 2;
              final cardWidth = (availWidth - (35 * (cols - 1))) / cols;
              return Wrap(
                spacing: 35,
                runSpacing: 35,
                alignment: WrapAlignment.center,
                children: partners.asMap().entries.map((entry) {
                  final index = entry.key;
                  final partner = entry.value;
                  return AnimateIfVisible(
                    slideBegin: const Offset(0, 0.3),
                    fadeBegin: 0,
                    delay: Duration(milliseconds: 150 * index),
                    child: SizedBox(
                      width: cardWidth.clamp(200, 400).toDouble(),
                      child: _buildPartnerCard(partner),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, String> partner) {
    return ScaleOnHover(
      scale: 1.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F6F4).withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Image.asset(
                      partner['logo']!,
                      height: 65,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.business, size: 45);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  partner['name']!,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactSection extends StatelessWidget {
  final bool isMobile;

  const ContactSection({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 100,
        vertical: isMobile ? 60 : 100,
      ),
      color: const Color(0xFFF7F6F4),
      child: Column(
        children: [
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
            fadeBegin: 0,
            child: Text(
              'CONTACTEZ-NOUS',
              style: GoogleFonts.montserrat(
                color: Colors.black,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Rejoignez le Réseau Premium',
              style: GoogleFonts.playfairDisplay(
                color: Colors.black,
                fontSize: isMobile ? 26 : 38,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 40),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(-0.3, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 200),
            child: ScaleOnHover(
              child: GestureDetector(
                onTap: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'info@prest-zone.com',
                    query: 'subject=Demande de partenariat - Prest Zone',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'info@prest-zone.com',
                          style: GoogleFonts.openSans(
                            color: Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),
          AnimateIfVisible(
            slideBegin: isMobile ? const Offset(0.3, 0) : const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 300),
            child: ScaleOnHover(
              child: GestureDetector(
                onTap: () async {
                  final Uri phoneUri = Uri(
                    scheme: 'tel',
                    path: '+21625100093',
                  );
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone, color: Colors.black, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          '+216 25 100 093',
                          style: GoogleFonts.openSans(
                            color: Colors.black87,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.2),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialIcon(
                  'https://www.facebook.com/Prest.Zone/',
                  AppAssets.facebook,
                ),
                const SizedBox(width: 20),
                _buildSocialIcon(
                  'https://www.instagram.com/prest.zone/',
                  AppAssets.instagram,
                ),
              ],
            ),
          ),
          const SizedBox(height: 45),
          AnimateIfVisible(
            slideBegin: const Offset(0, 0.3),
            fadeBegin: 0,
            delay: const Duration(milliseconds: 500),
            child: ScaleOnHover(
              child: ElevatedButton(
                onPressed: () async {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'info@prest-zone.com',
                    query: 'subject=Demande de partenariat - Prest Zone',
                  );
                  if (await canLaunchUrl(emailUri)) {
                    await launchUrl(emailUri);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 45 : 65,
                    vertical: isMobile ? 18 : 22,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                  elevation: 8,
                ),
                child: Text(
                  'Devenir Partenaire',
                  style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(String url, String iconPath) {
    return ScaleOnHover(
      scale: 1.1,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 26,
                height: 26,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    iconPath.contains('facebook')
                        ? Icons.facebook
                        : Icons.photo_camera,
                    color: Colors.black,
                    size: 26,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  final bool isMobile;

  const Footer({Key? key, required this.isMobile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 25 : 100,
        vertical: 50,
      ),
      color: Colors.black,
      child: Column(
        children: [
          Image.asset(
            AppAssets.logo,
            height: 50,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Text(
                'PREST ZONE',
                style: GoogleFonts.montserrat(
                  color: const Color(0xFFD4AF37),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'LUX SERVICE',
            style: GoogleFonts.montserrat(
              color: const Color(0xFFD4AF37).withOpacity(0.7),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 25),
          Container(
            height: 1,
            width: isMobile ? 120 : 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFD4AF37), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialIcon(
                'https://www.facebook.com/Prest.Zone/',
                AppAssets.facebook,
              ),
              const SizedBox(width: 18),
              _buildSocialIcon(
                'https://www.instagram.com/prest.zone/',
                AppAssets.instagram,
              ),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'Startup Tunisienne Innovante - Premier Réseau Indoor Premium',
            style: GoogleFonts.openSans(
              color: Colors.white60,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            width: isMobile ? 80 : 150,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0x55D4AF37), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '© 2025-2026 Prest Zone. Tous Droits Réservés.',
            style: GoogleFonts.openSans(
              color: Colors.white54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFD4AF37).withOpacity(0.15),
              ),
            ),
            child: Text(
              'Développé par AFK',
              style: GoogleFonts.poppins(
                color: const Color(0xFFD4AF37).withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(String url, String iconPath) {
    return ScaleOnHover(
      scale: 1.1,
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                iconPath,
                width: 22,
                height: 22,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    iconPath.contains('facebook')
                        ? Icons.facebook
                        : Icons.photo_camera,
                    color: Colors.black,
                    size: 22,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Machine1DetailPage extends StatefulWidget {
  const Machine1DetailPage({Key? key}) : super(key: key);

  @override
  State<Machine1DetailPage> createState() => _Machine1DetailPageState();
}

class _Machine1DetailPageState extends State<Machine1DetailPage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Distributeur Parfum',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFF7F6F4),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 40 : 60,
                      horizontal: isMobile ? 20 : 100,
                    ),
                    child: Column(
                      children: [
                        AnimateIfVisible(
                          slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
                          fadeBegin: 0,
                          child: Text(
                            'L\'expérience sensorielle du luxe',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.black,
                              fontSize: isMobile ? 26 : 42,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ScaleOnHover(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                AppAssets.machine1,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 250,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.devices, size: 100, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimateIfVisible(
                          slideBegin: const Offset(0, 0.2),
                          fadeBegin: 0,
                          child: Text(
                            'Dans un monde où l\'image et l\'expérience sont devenues essentielles, Prest Zone révolutionne la communication des marques de parfum grâce à un concept inédit : le distributeur automatique smart de spray de parfum, une exclusivité mondiale présente uniquement en Tunisie.',
                            style: GoogleFonts.openSans(
                              color: Colors.black87,
                              fontSize: isMobile ? 15 : 17,
                              height: 1.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimateIfVisible(
                          slideBegin: const Offset(0, 0.3),
                          fadeBegin: 0,
                          delay: const Duration(milliseconds: 400),
                          child: ScaleOnHover(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'info@prest-zone.com',
                                  query:
                                  'subject=Demande de devis - Distributeur de parfum',
                                );
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              },
                              icon: const Icon(Icons.mail_outline),
                              label: Text(
                                'Demander un devis',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 35 : 50,
                                  vertical: isMobile ? 16 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Footer(isMobile: isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Machine2DetailPage extends StatefulWidget {
  const Machine2DetailPage({Key? key}) : super(key: key);

  @override
  State<Machine2DetailPage> createState() => _Machine2DetailPageState();
}

class _Machine2DetailPageState extends State<Machine2DetailPage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Distributeur Multifonction',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: isMobile ? 40 : 60,
                      horizontal: isMobile ? 20 : 100,
                    ),
                    child: Column(
                      children: [
                        AnimateIfVisible(
                          slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.3),
                          fadeBegin: 0,
                          child: Text(
                            'Vente et communication connectée',
                            style: GoogleFonts.playfairDisplay(
                              color: Colors.black,
                              fontSize: isMobile ? 26 : 42,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        ScaleOnHover(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                AppAssets.machine2,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 250,
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: Icon(Icons.devices, size: 100, color: Colors.grey),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimateIfVisible(
                          slideBegin: const Offset(0, 0.2),
                          fadeBegin: 0,
                          child: Text(
                            'Prest Zone présente son nouveau distributeur automatique multifonction intelligent, une solution moderne et élégante pensée pour les hôtels, lounges, clubs privés, bars, salles de sport et espaces VIP.',
                            style: GoogleFonts.openSans(
                              color: Colors.black87,
                              fontSize: isMobile ? 15 : 17,
                              height: 1.8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 40),
                        AnimateIfVisible(
                          slideBegin: const Offset(0, 0.3),
                          fadeBegin: 0,
                          delay: const Duration(milliseconds: 400),
                          child: ScaleOnHover(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final Uri emailUri = Uri(
                                  scheme: 'mailto',
                                  path: 'info@prest-zone.com',
                                  query:
                                  'subject=Demande de devis - Distributeur multifonction',
                                );
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              },
                              icon: const Icon(Icons.mail_outline),
                              label: Text(
                                'Demander un devis',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 35 : 50,
                                  vertical: isMobile ? 16 : 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Footer(isMobile: isMobile),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Machine3DetailPage extends StatelessWidget {
  const Machine3DetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Prest Zone Fresh',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 60,
                horizontal: isMobile ? 20 : 100,
              ),
              child: Column(
                children: [
                  Text(
                    'Distributeur Automatique de Bouquets de Fleurs',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.black,
                      fontSize: isMobile ? 26 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.machine3,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.local_florist, size: 100, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Alliant raffinement, design et technologie, le distributeur automatique de fleurs Prest Zone Fresh permet d\'offrir un bouquet à tout moment de la journée, dans un concept moderne et haut de gamme.\n\nChaque compartiment est réfrigéré pour préserver la fraîcheur et l\'éclat des fleurs, garantissant une expérience d\'achat élégante et pratique.\n\nGrâce à son écran tactile 21,5 pouces, les utilisateurs peuvent visualiser les modèles disponibles et effectuer leur achat en quelques secondes par carte, espèces ou pièces.',
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontSize: isMobile ? 15 : 17,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                  _buildSpecsCard(isMobile, [
                    'Dimensions : 2200 × 1600 × 870 mm',
                    'Poids : 380 kg',
                    'Écran tactile : 21,5 pouces',
                    'Capacité : 11 compartiments réfrigérés',
                    'Alimentation : AC 100–240 V',
                    'Puissance : 500 W',
                    'Méthodes de paiement : carte, espèces, pièces',
                  ]),
                  const SizedBox(height: 30),
                  _buildIdealForCard(isMobile, [
                    'Cliniques',
                    'Hôtels',
                    'Aéroports',
                    'Lounges',
                    'Centres commerciaux',
                    'Restaurants haut de gamme',
                    'Événements privés',
                  ]),
                  const SizedBox(height: 40),
                  _buildContactButton(isMobile, 'Prest Zone Fresh'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
        ],
      ),
    );
  }

  Widget _buildSpecsCard(bool isMobile, List<String> specs) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caractéristiques techniques',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          ...specs.map((spec) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16)),
                Expanded(
                  child: Text(
                    spec,
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildIdealForCard(bool isMobile, List<String> places) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Idéal pour',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: places.map((place) => Chip(
              label: Text(
                place,
                style: GoogleFonts.openSans(fontSize: 13),
              ),
              backgroundColor: Colors.black.withOpacity(0.05),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton(bool isMobile, String subject) {
    return ScaleOnHover(
      child: ElevatedButton.icon(
        onPressed: () async {
          final Uri emailUri = Uri(
            scheme: 'mailto',
            path: 'info@prest-zone.com',
            query: 'subject=Demande de devis - $subject',
          );
          if (await canLaunchUrl(emailUri)) {
            await launchUrl(emailUri);
          }
        },
        icon: const Icon(Icons.mail_outline),
        label: Text(
          'Demander un devis',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 35 : 50,
            vertical: isMobile ? 16 : 20,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
        ),
      ),
    );
  }
}

class Machine4DetailPage extends StatelessWidget {
  const Machine4DetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Shaker Protéiné',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 60,
                horizontal: isMobile ? 20 : 100,
              ),
              child: Column(
                children: [
                  Text(
                    'Distributeur automatique de shaker protéiné',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.black,
                      fontSize: isMobile ? 26 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.machine4,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.sports_gymnastics, size: 100, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Pensé pour les salles de sport, clubs VIP et centres de fitness modernes, ce distributeur délivre instantanément des shakers protéinés frais pour soutenir la performance et la récupération des sportifs.\n\nÉquipé d\'un grand écran tactile 27 pouces, il offre une expérience utilisateur fluide et une plateforme publicitaire dynamique permettant aux marques de nutrition et de sport d\'afficher leurs produits en temps réel.',
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontSize: isMobile ? 15 : 17,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques techniques',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...[
                          'Dimensions : 1785 × 730 × 820 mm',
                          'Poids : 170 kg',
                          'Écran tactile : 27 pouces',
                          'Alimentation : AC 100–240 V',
                          'Puissance : 500 W',
                          'Paiement : carte, espèces, pièces',
                        ].map((spec) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  spec,
                                  style: GoogleFonts.openSans(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Idéal pour',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            'Salles de sport',
                            'Universités',
                            'Complexes sportifs',
                            'Hôtels de luxe',
                            'Événements fitness',
                          ].map((place) => Chip(
                            label: Text(
                              place,
                              style: GoogleFonts.openSans(fontSize: 13),
                            ),
                            backgroundColor: Colors.black.withOpacity(0.05),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ScaleOnHover(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'info@prest-zone.com',
                          query: 'subject=Demande de devis - Distributeur de shaker protéiné',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                      },
                      icon: const Icon(Icons.mail_outline),
                      label: Text(
                        'Demander un devis',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 35 : 50,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
        ],
      ),
    );
  }
}

class Machine5DetailPage extends StatelessWidget {
  const Machine5DetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Nettoyage de Casques',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 60,
                horizontal: isMobile ? 20 : 100,
              ),
              child: Column(
                children: [
                  Text(
                    'Distributeur automatique de nettoyage de casques',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.black,
                      fontSize: isMobile ? 26 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Une solution innovante pour les motards et les espaces premium !',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.machine5,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.motorcycle, size: 100, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Ce distributeur intelligent nettoie et désinfecte les casques de moto en quelques minutes grâce à une technologie performante et hygiénique.\n\nÉquipé d\'un écran tactile 21,5 pouces, il permet une utilisation simple et rapide tout en diffusant des publicités ou vidéos promotionnelles.',
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontSize: isMobile ? 15 : 17,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques principales',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...[
                          'Dimensions : 1800 × 640 × 550 mm',
                          'Poids : 105 kg',
                          'Alimentation : AC 100-240 V',
                          'Méthodes de paiement : carte, pièces, billets',
                          'Capacité : jusqu\'à 200 utilisations',
                          'Puissance : 6930 W',
                        ].map((spec) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  spec,
                                  style: GoogleFonts.openSans(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Parfait pour',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            'Stations-service',
                            'Parkings',
                            'Lounges',
                            'Hôtels',
                            'Clubs de motards',
                          ].map((place) => Chip(
                            label: Text(
                              place,
                              style: GoogleFonts.openSans(fontSize: 13),
                            ),
                            backgroundColor: Colors.black.withOpacity(0.05),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ScaleOnHover(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'info@prest-zone.com',
                          query: 'subject=Demande de devis - Nettoyage de casques',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                      },
                      icon: const Icon(Icons.mail_outline),
                      label: Text(
                        'Demander un devis',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 35 : 50,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
        ],
      ),
    );
  }
}

class Machine6DetailPage extends StatelessWidget {
  const Machine6DetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Distributeur Maquillage',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 60,
                horizontal: isMobile ? 20 : 100,
              ),
              child: Column(
                children: [
                  Text(
                    'Distributeur Automatique de Maquillage',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.black,
                      fontSize: isMobile ? 26 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Un concept exclusif qui redéfinit l\'élégance et la praticité',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.machine6,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.brush, size: 100, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Le distributeur automatique de maquillage Prest Zone offre une sélection raffinée de produits cosmétiques (rouges à lèvres, poudres, parfums miniatures, accessoires beauté…) accessibles 24h/24 dans un design luxueux noir et doré.',
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontSize: isMobile ? 15 : 17,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques principales',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...[
                          'Design moderne et sophistiqué, parfait pour les lieux premium',
                          'Système de vente automatique avec paiement sécurisé (pièces, cartes, QR)',
                          'Capacité modulable selon les produits (cosmétiques, parfums, soins)',
                          'Éclairage interne et vitrine chic pour une présentation élégante',
                          'Maintenance facile et rechargement rapide',
                        ].map((spec) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  spec,
                                  style: GoogleFonts.openSans(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Idéal pour installation dans',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            'Parfumeries',
                            'Instituts de beauté',
                            'Hôtels',
                            'Lounges',
                            'Rooftops',
                            'Centres commerciaux',
                            'Spas',
                            'Salons de coiffure',
                            'Salles de sport',
                            'Aéroports',
                            'Clubs privés',
                          ].map((place) => Chip(
                            label: Text(
                              place,
                              style: GoogleFonts.openSans(fontSize: 13),
                            ),
                            backgroundColor: Colors.black.withOpacity(0.05),
                          )).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ScaleOnHover(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'info@prest-zone.com',
                          query: 'subject=Demande de devis - Distributeur de maquillage',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                      },
                      icon: const Icon(Icons.mail_outline),
                      label: Text(
                        'Demander un devis',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 35 : 50,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
        ],
      ),
    );
  }
}

class Machine7DetailPage extends StatelessWidget {
  const Machine7DetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Distributeur Serviettes',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 40 : 60,
                horizontal: isMobile ? 20 : 100,
              ),
              child: Column(
                children: [
                  Text(
                    'Distributeur de Serviettes Hygiéniques',
                    style: GoogleFonts.playfairDisplay(
                      color: Colors.black,
                      fontSize: isMobile ? 26 : 42,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Un concept discret, raffiné et indispensable',
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: isMobile ? 16 : 20,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppAssets.machine7,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.health_and_safety, size: 100, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Notre distributeur automatique de serviettes hygiéniques est conçu pour la vente directe dans les toilettes, vestiaires et espaces bien-être des hôtels, lounges, gyms, spas et établissements de prestige.',
                    style: GoogleFonts.openSans(
                      color: Colors.black87,
                      fontSize: isMobile ? 15 : 17,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Caractéristiques principales',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 15),
                        ...[
                          'Design noir mat et doré, au style luxueux et moderne',
                          'Système automatique fiable et hygiénique',
                          'Distribution unitaire de serviettes ou protections féminines',
                          'Format compact, facile à installer et à entretenir',
                          'Idéal pour les espaces souhaitant offrir un service de confort haut de gamme',
                        ].map((spec) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  spec,
                                  style: GoogleFonts.openSans(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  ScaleOnHover(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final Uri emailUri = Uri(
                          scheme: 'mailto',
                          path: 'info@prest-zone.com',
                          query: 'subject=Demande de devis - Distributeur de serviettes',
                        );
                        if (await canLaunchUrl(emailUri)) {
                          await launchUrl(emailUri);
                        }
                      },
                      icon: const Icon(Icons.mail_outline),
                      label: Text(
                        'Demander un devis',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 35 : 50,
                          vertical: isMobile ? 16 : 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
        ],
      ),
    );
  }
}

class LocationDetailPage extends StatelessWidget {
  const LocationDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Notre Localisation',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.black],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 25 : 100,
                vertical: isMobile ? 40 : 60,
              ),
              child: Column(
                children: [
                  AnimateIfVisible(
                    slideBegin: isMobile ? const Offset(-0.5, 0) : const Offset(0, 0.3),
                    fadeBegin: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: isMobile ? 220 : 350),
                        child: Image.asset(
                          AppAssets.arenaLocation,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.location_on,
                                    size: 80, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimateIfVisible(
                    slideBegin: isMobile ? const Offset(0.5, 0) : const Offset(0, 0.2),
                    fadeBegin: 0,
                    delay: const Duration(milliseconds: 100),
                    child: Image.asset(
                      AppAssets.logoArenaGym,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.business, size: 60);
                      },
                    ),
                  ),
                  const SizedBox(height: 25),
                  AnimateIfVisible(
                    slideBegin: isMobile ? const Offset(-0.3, 0) : const Offset(0, 0.2),
                    fadeBegin: 0,
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      'Arena Gym Premium - La Soukra',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  AnimateIfVisible(
                    slideBegin: isMobile ? const Offset(0.3, 0) : const Offset(0, 0.2),
                    fadeBegin: 0,
                    delay: const Duration(milliseconds: 300),
                    child: Text(
                      'Notre premier dispositif vient d\'être installé à Arena Gym Premium La Soukra, un espace chic fréquenté par plus de 3 000 abonnés au profil premium.',
                      style: GoogleFonts.openSans(
                        color: Colors.black87,
                        fontSize: 17,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnimateIfVisible(
                    slideBegin: isMobile ? const Offset(-0.3, 0) : const Offset(0, 0.2),
                    fadeBegin: 0,
                    delay: const Duration(milliseconds: 400),
                    child: Text(
                      'Placée à l\'entrée principale, la machine associe un distributeur automatique haut de gamme de parfums à un écran digital 43 pouces, diffusant en continu les publicités de marques prestigieuses.',
                      style: GoogleFonts.openSans(
                        color: Colors.black87,
                        fontSize: 17,
                        height: 1.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  AnimateIfVisible(
                    slideBegin: const Offset(0, 0.3),
                    fadeBegin: 0,
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'Pourquoi ce support est une opportunité exclusive',
                      style: GoogleFonts.poppins(
                        color: Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildOpportunityPoint(
                      'Une visibilité accrue de 30 à 70 % grâce à un design innovant et attractif',
                      0,
                      isMobile),
                  _buildOpportunityPoint(
                      'Un emplacement stratégique dans un lieu à forte affluence et à clientèle sélective',
                      1,
                      isMobile),
                  _buildOpportunityPoint(
                      'Une expérience sensorielle inédite (image + parfum) qui crée un lien émotionnel durable',
                      2,
                      isMobile),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: Footer(isMobile: isMobile)),
        ],
      ),
    );
  }

  Widget _buildOpportunityPoint(String text, int index, bool isMobile) {
    return AnimateIfVisible(
      slideBegin: isMobile
          ? (index % 2 == 0 ? const Offset(-0.5, 0) : const Offset(0.5, 0))
          : const Offset(-0.3, 0),
      fadeBegin: 0,
      delay: Duration(milliseconds: 600 + (index * 100)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, color: Colors.black, size: 24),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.openSans(
                  color: Colors.black87,
                  fontSize: 16,
                  height: 1.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}