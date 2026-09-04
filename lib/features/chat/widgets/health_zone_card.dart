import 'package:flutter/material.dart';
import 'package:sehatfile/services/health_analysis_service.dart';

class HealthZoneCard extends StatelessWidget {
  final MetricAnalysis metric;

  const HealthZoneCard({
    super.key,
    required this.metric,
  });

  Color _severityColor() {
    switch (metric.severity) {
      case 0:
        return Colors.green;
      case 1:
        return Colors.amber.shade700;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color statusColor = _severityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD7ECEA)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F3D3A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  metric.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            metric.valueText,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF143A37),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            metric.advice,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF607D7A),
            ),
          ),
          const SizedBox(height: 16),

          // Zone bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Row(
              children: [
                Expanded(
                  child: Container(height: 10, color: Colors.green),
                ),
                Expanded(
                  child: Container(height: 10, color: Colors.amber),
                ),
                Expanded(
                  child: Container(height: 10, color: Colors.orange),
                ),
                Expanded(
                  child: Container(height: 10, color: Colors.red),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          LayoutBuilder(
            builder: (context, constraints) {
              double left = constraints.maxWidth * metric.markerPosition;
              if (left < 8) left = 8;
              if (left > constraints.maxWidth - 8) {
                left = constraints.maxWidth - 8;
              }

              return SizedBox(
                height: 16,
                child: Stack(
                  children: [
                    Positioned(
                      left: left - 8,
                      child: Icon(
                        Icons.arrow_drop_up_rounded,
                        size: 24,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          Row(
            children: const [
              Expanded(
                child: Text(
                  'Good',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'Fair',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'Watch',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
              Expanded(
                child: Text(
                  'Doctor',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}