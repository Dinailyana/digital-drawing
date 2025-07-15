import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  List<JournalEntry> entries = [];
  bool isLoading = true;
  String selectedTimeframe = 'all';
  String? errorMessage;
  String? currentUsername; // Added for user authentication

  final List<String> stressEmojis = ["😌", "🙂", "😐", "😟", "😣"];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // Load user first before loading data
  }

  // Load current user from SharedPreferences
  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentUsername = prefs.getString('current_username');
    });
    
    // Only load journal data after we have the current user
    if (currentUsername != null) {
      loadJournalData();
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view your insights.';
      });
    }
  }

  Future<void> loadJournalData() async {
    // Don't proceed if no current user
    if (currentUsername == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Please log in to view your insights.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Simple query with just the where clause - no orderBy to avoid index issues
      Query query = FirebaseFirestore.instance
          .collection('journalEntries')
          .where('userId', isEqualTo: currentUsername); // Filter by current user

      final querySnapshot = await query.get();

      // Process documents and filter valid entries
      List<JournalEntry> validEntries = [];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Double-check user ownership (extra security layer)
        final entryUserId = data['userId'] as String?;
        if (entryUserId != currentUsername) {
          continue; // Skip entries that don't belong to current user
        }
        
        // Check if required fields exist and are valid
        final beforeStress = data['beforeStressLevel'];
        final afterStress = data['afterStressLevel'];
        final timestamp = data['timestamp'];
        
        if (beforeStress != null && 
            afterStress != null && 
            timestamp != null &&
            beforeStress is int && 
            afterStress is int) {
          
          validEntries.add(JournalEntry(
            id: doc.id,
            beforeStressLevel: beforeStress,
            afterStressLevel: afterStress,
            timestamp: (timestamp as Timestamp).toDate(),
          ));
        }
      }

      // Apply timeframe filter in code after getting all entries
      if (selectedTimeframe != 'all') {
        DateTime cutoffDate;
        switch (selectedTimeframe) {
          case 'week':
            cutoffDate = DateTime.now().subtract(const Duration(days: 7));
            break;
          case 'month':
            cutoffDate = DateTime.now().subtract(const Duration(days: 30));
            break;
          default:
            cutoffDate = DateTime(2020);
        }
        
        validEntries = validEntries.where((entry) => 
          entry.timestamp.isAfter(cutoffDate)
        ).toList();
      }

      // Sort entries by timestamp in ascending order (oldest first for chart progression)
      validEntries.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      setState(() {
        entries = validEntries;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error loading data: ${e.toString()}';
      });
    }
  }

  List<FlSpot> getBeforeStressData() {
    return entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.beforeStressLevel.toDouble());
    }).toList();
  }

  List<FlSpot> getAfterStressData() {
    return entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.afterStressLevel.toDouble());
    }).toList();
  }

  Map<String, int> getImprovementStats() {
    int improved = 0;
    int worsened = 0;
    int unchanged = 0;

    for (var entry in entries) {
      int change = entry.afterStressLevel - entry.beforeStressLevel;
      if (change < 0) {
        improved++;
      } else if (change > 0) {
        worsened++;
      } else {
        unchanged++;
      }
    }

    return {
      'improved': improved,
      'worsened': worsened,
      'unchanged': unchanged,
    };
  }

  double getAverageImprovement() {
    if (entries.isEmpty) return 0;
    
    double totalChange = 0;
    for (var entry in entries) {
      totalChange += (entry.beforeStressLevel - entry.afterStressLevel);
    }
    return totalChange / entries.length;
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while determining user authentication
    if (currentUsername == null && isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show login prompt if no user
    if (currentUsername == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Insights'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.person_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                "Please Log In",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You need to be logged in to view your insights.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Insights - ${currentUsername!}'), // Show current user
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                selectedTimeframe = value;
              });
              loadJournalData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'week', child: Text('This Week')),
              const PopupMenuItem(value: 'month', child: Text('This Month')),
              const PopupMenuItem(value: 'all', child: Text('All Time')),
            ],
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      const Text(
                        'Error Loading Data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: loadJournalData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.insights, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No journal entries found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start journaling to see your insights!\nMake sure to complete both before and after stress level ratings.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: loadJournalData,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMoodOverTimeChart(),
                          const SizedBox(height: 24),
                          _buildWeeklyMoodChart(),
                          const SizedBox(height: 24),
                          _buildStatsCards(),
                          const SizedBox(height: 24),
                          _buildImprovementInsights(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildMoodOverTimeChart() {
    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mood over time',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Icon(Icons.dark_mode_outlined, size: 20, color: Colors.grey[600]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < stressEmojis.length) {
                            return Text(stressEmojis[index], style: const TextStyle(fontSize: 16));
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < entries.length) {
                            return Text(
                              '${entries[index].timestamp.day}/${entries[index].timestamp.month}',
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: getBeforeStressData(),
                      isCurved: true,
                      color: Colors.orange[300],
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.orange[100]?.withValues(alpha: 0.3),
                      ),
                    ),
                    LineChartBarData(
                      spots: getAfterStressData(),
                      isCurved: true,
                      color: Colors.green[400],
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green[100]?.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Before', Colors.orange[300]!),
                const SizedBox(width: 20),
                _buildLegendItem('After', Colors.green[400]!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyMoodChart() {
    if (entries.isEmpty) return const SizedBox.shrink();

    Map<int, List<JournalEntry>> entriesByWeekday = {};
    for (int i = 0; i < 7; i++) {
      entriesByWeekday[i] = [];
    }

    for (var entry in entries) {
      int weekday = entry.timestamp.weekday - 1; // Convert to 0-6
      if (weekday < 0) weekday = 6; // Handle Sunday
      entriesByWeekday[weekday]!.add(entry);
    }

    List<String> weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly mood pattern',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (index) {
                  List<JournalEntry> dayEntries = entriesByWeekday[index]!;
                  double avgImprovement = 0;
                  
                  if (dayEntries.isNotEmpty) {
                    double totalImprovement = 0;
                    for (var entry in dayEntries) {
                      totalImprovement += (entry.beforeStressLevel - entry.afterStressLevel);
                    }
                    avgImprovement = totalImprovement / dayEntries.length;
                  }

                  String emoji = avgImprovement > 0 ? '😊' : 
                               avgImprovement < 0 ? '😔' : '😐';

                  return Column(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        weekdays[index],
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (dayEntries.isNotEmpty)
                        Text(
                          '(${dayEntries.length})',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = getImprovementStats();
    final avgImprovement = getAverageImprovement();

    return Row(
      children: [
        Expanded(
          child: Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${stats['improved']}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  const Text('Sessions\nImproved', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    avgImprovement.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                  const Text('Average\nImprovement', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    '${entries.length}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                  const Text('Total\nSessions', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementInsights() {
    final stats = getImprovementStats();
    final avgImprovement = getAverageImprovement();
    final improvementPercentage = entries.isEmpty ? 0 : (stats['improved']! / entries.length * 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (improvementPercentage >= 70)
              _buildInsightItem(
                '🎉',
                'Great job!',
                'You\'ve improved your mood in ${improvementPercentage.toInt()}% of your sessions. Keep up the excellent work!',
              )
            else if (improvementPercentage >= 50)
              _buildInsightItem(
                '👍',
                'Good progress!',
                'You\'ve improved in ${improvementPercentage.toInt()}% of sessions. You\'re on the right track!',
              )
            else
              _buildInsightItem(
                '💪',
                'Keep going!',
                'Every session is a step forward. Remember, healing takes time and consistency.',
              ),
            const SizedBox(height: 12),
            if (avgImprovement > 0)
              _buildInsightItem(
                '📈',
                'Positive trend',
                'On average, you feel ${avgImprovement.toStringAsFixed(1)} levels better after each session.',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class JournalEntry {
  final String id;
  final int beforeStressLevel;
  final int afterStressLevel;
  final DateTime timestamp;

  JournalEntry({
    required this.id,
    required this.beforeStressLevel,
    required this.afterStressLevel,
    required this.timestamp,
  });
}