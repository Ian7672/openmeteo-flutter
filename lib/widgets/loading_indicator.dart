import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Modern loading animation dengan gradient background
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF667EEA).withOpacity(0.1),
                  Color(0xFF764BA2).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF667EEA).withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: SpinKitPulsingGrid(color: Color(0xFF667EEA), size: 60.0),
          ),

          SizedBox(height: 32),

          // Loading text dengan animasi
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 1500),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Column(
                    children: [
                      Text(
                        "Memuat Data Cuaca",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.titleLarge?.color ?? Color(0xFF1E293B),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Mohon tunggu sebentar...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color ?? Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          SizedBox(height: 40),

          // Progress indicator with dots
          _buildDotIndicator(),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            double delay = index * 0.2;
            double animValue = (value - delay).clamp(0.0, 1.0);

            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Color(0xFF667EEA).withOpacity(animValue),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
      onEnd: () {
        // Restart animation
        Future.delayed(
          Duration(milliseconds: 500),
          (dynamic context) {
                if (context.mounted) {
                  (context as Element).markNeedsBuild();
                }
              }
              as FutureOr Function()?,
        );
      },
    );
  }
}
