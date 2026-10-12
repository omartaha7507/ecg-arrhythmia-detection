import 'package:ecg_analysis2/Layout/root-layout.dart';
import 'package:ecg_analysis2/Widgets/ecg-line-chart.dart';
import 'package:ecg_analysis2/Widgets/info-card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  static const String path = '/result';
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _animation;
  double _totalDuration = 0.0;
  double _currentInstantBPM = 0.0;
  bool _isInitialized = false;

  // Animation parameters
  final double windowDuration = 10.0;
  final double scrollSpeed = 1;

  @override
  void initState() {
    super.initState();
    // Animation controller will be initialized after we get the data
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only initialize once
    if (_isInitialized) return;

    // Get the response data
    Map<String, dynamic> response =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    List<dynamic> rawECG = response['waveform_xy'];
    List<dynamic> beats = response['beats'];
    double heartRate = response['BPM'];

    // Calculate total duration from ECG data
    if (rawECG.isNotEmpty) {
      _totalDuration = rawECG.last[0].toDouble();
    }

    // Initialize animation controller
    _animationController = AnimationController(
      duration: Duration(
        milliseconds: ((_totalDuration / scrollSpeed) * 1000).round(),
      ),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: _totalDuration).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.linear),
    );

    // Listen to animation changes to update instant BPM
    _animation!.addListener(() {
      _updateInstantBPM(_animation!.value, beats, heartRate);
    });

    // Start the animation
    _animationController!.repeat();

    _isInitialized = true;
  }

  void _updateInstantBPM(
    double currentTime,
    List<dynamic> beats,
    double defaultBPM,
  ) {
    // Handle wrap-around when animation loops
    double actualTime = currentTime;
    if (actualTime >= _totalDuration) {
      actualTime = actualTime % _totalDuration;
    }

    // Find the closest beat data for the current time
    double closestBPM = defaultBPM;
    double minTimeDiff = double.infinity;

    for (var beat in beats) {
      double beatTime = beat['time'].toDouble();
      double timeDiff = (beatTime - actualTime).abs();

      if (timeDiff < minTimeDiff) {
        minTimeDiff = timeDiff;
        closestBPM = beat['instant_BPM'].toDouble();
      }
    }

    // Update the instant BPM if it changed
    if (_currentInstantBPM != closestBPM) {
      setState(() {
        _currentInstantBPM = closestBPM;
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> response =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    String classification = response['predicted_class'];
    List<dynamic> rawECG = response['waveform_xy'];
    double heartRate = response['BPM'];
    String recordId = response['name'];

    List<FlSpot> flSpots = rawECG
        .map((point) => FlSpot(point[0].toDouble(), point[1].toDouble()))
        .toList();

    FlSpot maxYSpot = flSpots.reduce((a, b) => a.y > b.y ? a : b);
    FlSpot minYSpot = flSpots.reduce((a, b) => a.y < b.y ? a : b);
    double positivePeak = maxYSpot.y;
    double negativePeak = minYSpot.y;

    final Map<String, MaterialColor> conditionColorMap = {
      "Normal Beat": Colors.green,
      "Atrial premature beat (APB)": Colors.orange,
      "Aberrated atrial premature beat": Colors.deepOrange,
      "Nodal (junctional) premature beat": Colors.amber,
      "Supraventricular premature beat": Colors.orange,
      "Premature ventricular contraction (PVC)": Colors.red,
      "Ventricular escape beat": Colors.red,
      "Fusion of ventricular and normal beat": Colors.purple,
      "Left bundle branch block beat (LBBB)": Colors.indigo,
      "Right bundle branch block beat (RBBB)": Colors.indigo,
      "Atrial escape beat": Colors.blue,
      "Paced beat": Colors.teal,
      "Signal artifact / noise": Colors.grey,
      "Unknown beat / Unclassified": Colors.blueGrey,
    };

    final MaterialColor conditionColor =
        conditionColorMap[classification] ?? Colors.blueGrey;

    // Use instant BPM if available, otherwise use default
    double displayBPM = _currentInstantBPM > 0 ? _currentInstantBPM : heartRate;

    return RootLayout(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 8,
          children: [
            IntrinsicHeight(
              child: Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: InfoCard(
                      icon: Icons.medical_information,
                      title: "Record ID",
                      value: 'CASE-$recordId',
                      iconColor: Colors.blue,
                      backgroundColor: Colors.blue[200],
                    ),
                  ),
                  Expanded(
                    child: InfoCard(
                      icon: Icons.favorite,
                      title: "Heart Rate",
                      value: '${displayBPM.toStringAsFixed(0)} BPM',
                      iconColor: Colors.red,
                      backgroundColor: Colors.red[200],
                    ),
                  ),
                  Expanded(
                    child: InfoCard(
                      icon: Icons.analytics,
                      title: "Condition",
                      value: classification,
                      iconColor: conditionColor,
                      backgroundColor: conditionColor[200],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_heart,
                          color: Colors.green,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Live ECG Monitor',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: _animation != null
                          ? AnimatedECGLineChart(
                              flSpots: flSpots,
                              positivePeak: positivePeak,
                              negativePeak: negativePeak,
                              windowDuration: windowDuration,
                              animation: _animation!,
                              totalDuration: _totalDuration,
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                color: Colors.green,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
