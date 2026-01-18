import 'package:flutter/material.dart';

class NoInternetWidget extends StatefulWidget {
  final VoidCallback onRetry;
  final bool isRetrying;

  const NoInternetWidget({
    Key? key,
    required this.onRetry,
    this.isRetrying = false,
  }) : super(key: key);

  @override
  State<NoInternetWidget> createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    // Start animations
    _pulseController.repeat(reverse: true);
    _bounceController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight =
        screenHeight - MediaQuery.of(context).padding.top - kToolbarHeight;

    return Container(
      width: double.infinity,
      height: availableHeight,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: availableHeight - 40),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flexible space at top
                Flexible(flex: 1, child: SizedBox(height: 20)),

                // Animated No Internet Icon
                _buildAnimatedIcon(),

                SizedBox(height: 24),

                // Title
                _buildTitle(),

                SizedBox(height: 12),

                // Description
                _buildDescription(),

                SizedBox(height: 32),

                // Connection Tips - Made more compact
                _buildCompactTips(),

                SizedBox(height: 24),

                // Retry Button
                _buildRetryButton(),

                SizedBox(height: 16),

                // Status indicator
                _buildStatusIndicator(),

                // Flexible space at bottom
                Flexible(flex: 1, child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFEF4444).withOpacity(0.1),
                    Color(0xFFF97316).withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Color(0xFFEF4444).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 60,
                color: Color(0xFFEF4444),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitle() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Text(
        "Tidak Ada Koneksi Internet",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).textTheme.headlineLarge?.color ?? Color(0xFF1E293B),
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescription() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          "Periksa koneksi internet Anda dan coba lagi.",
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B), height: 1.5),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildCompactTips() {
    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
                SizedBox(width: 6),
                Text(
                  "Tips Koneksi",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              "• Periksa WiFi atau data seluler\n• Coba pindah lokasi dengan sinyal baik\n• Restart router jika perlu",
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (!widget.isRetrying) return SizedBox.shrink();

    return ScaleTransition(
      scale: _bounceAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0xFF3B82F6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
            SizedBox(width: 6),
            Text(
              "Memeriksa koneksi...",
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFF64748B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: widget.isRetrying ? null : widget.onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: widget.isRetrying
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
        label: Text(
          widget.isRetrying ? "Memeriksa..." : "Coba Lagi",
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
