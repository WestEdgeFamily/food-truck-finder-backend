import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'dart:convert';

class ScheduleManagementScreen extends StatefulWidget {
  const ScheduleManagementScreen({super.key});

  @override
  State<ScheduleManagementScreen> createState() => _ScheduleManagementScreenState();
}

class _ScheduleManagementScreenState extends State<ScheduleManagementScreen> {
  Map<String, Map<String, dynamic>> _schedule = {
    'monday': {'isOpen': true, 'open': '11:00', 'close': '21:00'},
    'tuesday': {'isOpen': true, 'open': '11:00', 'close': '21:00'},
    'wednesday': {'isOpen': true, 'open': '11:00', 'close': '21:00'},
    'thursday': {'isOpen': true, 'open': '11:00', 'close': '21:00'},
    'friday': {'isOpen': true, 'open': '11:00', 'close': '22:00'},
    'saturday': {'isOpen': true, 'open': '10:00', 'close': '22:00'},
    'sunday': {'isOpen': false, 'open': '12:00', 'close': '20:00'},
  };

  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentTruckId;

  @override
  void initState() {
    super.initState();
    _loadCurrentSchedule();
  }

  Future<void> _loadCurrentSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final businessName = authProvider.user?.businessName;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      debugPrint('🔍 Looking for truck with owner ID: $userId or business name: $businessName');
      
      // Get user's food truck ID from API
      final trucks = await ApiService.getFoodTrucks();
      Map<String, dynamic>? userTruck;
      
      for (var truck in trucks) {
        if (truck is Map<String, dynamic>) {
          final ownerId = truck['ownerId'] ?? truck['owner'];
          final truckBusinessName = truck['businessName'] ?? truck['name'];
          
          debugPrint('🔍 Checking truck - Owner ID: $ownerId, Business Name: $truckBusinessName');
          
          if (ownerId == userId || 
              (businessName != null && truckBusinessName == businessName)) {
            userTruck = truck;
            debugPrint('✅ Found matching truck: ${truck['name']} (ID: ${truck['id'] ?? truck['_id']})');
            break;
          }
        }
      }

      if (userTruck == null) {
        throw Exception('No food truck found. Please register a food truck first.');
      }

      final truckId = userTruck['id'] ?? userTruck['_id'];
      if (truckId == null) {
        throw Exception('Truck ID not found');
      }

      debugPrint('📅 Loading schedule for truck ID: $truckId');
      
      // Load schedule using truck ID
      final scheduleResponse = await ApiService.getSchedule(truckId.toString());
      debugPrint('📅 Schedule response: $scheduleResponse');
      
      if (scheduleResponse['success'] == true) {
        var scheduleData = scheduleResponse['schedule'];
        
        // Handle different schedule data formats
        if (scheduleData is String) {
          try {
            scheduleData = jsonDecode(scheduleData);
          } catch (e) {
            debugPrint('❌ Failed to parse schedule string: $e');
            scheduleData = {};
          }
        }
        
        if (scheduleData is Map<String, dynamic>) {
          // Convert the schedule data to the correct format
          _schedule = {};
          for (var day in ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday']) {
            if (scheduleData[day] is Map<String, dynamic>) {
              _schedule[day] = Map<String, dynamic>.from(scheduleData[day] as Map<String, dynamic>);
            } else if (scheduleData[day] is String) {
              try {
                final dayData = jsonDecode(scheduleData[day] as String);
                if (dayData is Map<String, dynamic>) {
                  _schedule[day] = dayData;
                } else {
                  _schedule[day] = _getDefaultDaySchedule();
                }
              } catch (e) {
                debugPrint('❌ Failed to parse day schedule string: $e');
                _schedule[day] = _getDefaultDaySchedule();
              }
            } else {
              _schedule[day] = _getDefaultDaySchedule();
            }
            
            // Ensure all required fields exist
            _schedule[day]!.putIfAbsent('isOpen', () => false);
            _schedule[day]!.putIfAbsent('open', () => '11:00');
            _schedule[day]!.putIfAbsent('close', () => '21:00');
          }
        } else {
          debugPrint('⚠️ Invalid schedule format, using default schedule');
          _setDefaultSchedule();
        }
        
        debugPrint('✅ Successfully loaded schedule: $_schedule');
      } else {
        debugPrint('⚠️ Schedule response not successful, using default schedule');
        _setDefaultSchedule();
      }
      
      setState(() {
        _currentTruckId = truckId.toString();
      });
    } catch (e) {
      debugPrint('❌ Error loading schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Network error')
                ? 'Unable to connect to server. Please check your internet connection and try again.'
                : 'Error loading schedule: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadCurrentSchedule,
            ),
          ),
        );
      }
      _setDefaultSchedule();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setDefaultSchedule() {
    _schedule = {
      'monday': _getDefaultDaySchedule(),
      'tuesday': _getDefaultDaySchedule(),
      'wednesday': _getDefaultDaySchedule(),
      'thursday': _getDefaultDaySchedule(),
      'friday': _getDefaultDaySchedule(),
      'saturday': _getDefaultDaySchedule(),
      'sunday': _getDefaultDaySchedule(),
    };
  }

  Map<String, dynamic> _getDefaultDaySchedule() {
    return {
      'isOpen': false,
      'open': '11:00',
      'close': '21:00'
    };
  }

  Future<void> _selectTime(String day, String timeType) async {
    // Convert 24-hour format to TimeOfDay
    final currentTimeStr = _schedule[day]![timeType] as String;
    final timeParts = currentTimeStr.split(':');
    final currentTime = TimeOfDay(
      hour: int.parse(timeParts[0]),
      minute: int.parse(timeParts[1]),
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );
    
    if (picked != null) {
      setState(() {
        // Convert TimeOfDay back to 24-hour format string
        final hour = picked.hour.toString().padLeft(2, '0');
        final minute = picked.minute.toString().padLeft(2, '0');
        _schedule[day]![timeType] = '$hour:$minute';
      });
    }
  }

  String _formatTime(String timeStr) {
    final timeParts = timeStr.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final time = TimeOfDay(hour: hour, minute: minute);
    
    final hourDisplay = time.hourOfPeriod;
    final minuteDisplay = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hourDisplay == 0 ? 12 : hourDisplay}:$minuteDisplay $period';
  }

  Future<void> _saveSchedule() async {
    setState(() => _isSaving = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final businessName = authProvider.user?.businessName;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Get user's food truck ID
      final trucks = await ApiService.getFoodTrucks();
      Map<String, dynamic>? userTruck;
      
      for (var truck in trucks) {
        if (truck is Map<String, dynamic>) {
          final ownerId = truck['ownerId'] ?? truck['owner'];
          final truckBusinessName = truck['businessName'] ?? truck['name'];
          
          if (ownerId == userId || 
              (businessName != null && truckBusinessName == businessName)) {
            userTruck = truck;
            break;
          }
        }
      }

      if (userTruck == null) {
        throw Exception('No food truck found. Please register a food truck first.');
      }

      final truckId = userTruck['id'] ?? userTruck['_id'];
      if (truckId == null) {
        throw Exception('Truck ID not found');
      }

      // Update schedule using truck ID
      final result = await ApiService.updateSchedule(truckId.toString(), _schedule);
      
      if (result['success'] == true || result['schedule'] != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Schedule saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to save schedule');
      }
    } catch (e) {
      debugPrint('❌ Error saving schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().contains('Network error')
                ? 'Unable to connect to server. Please check your internet connection and try again.'
                : 'Error saving schedule: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _saveSchedule,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Management'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading) ...[
            if (_isSaving) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ] else ...[
              TextButton(
                onPressed: _saveSchedule,
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading schedule...'),
                ],
              ),
            )
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Operating Hours',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set your food truck\'s operating hours for each day of the week. Customers will see these hours when viewing your truck.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          ..._schedule.entries.map((entry) {
            final day = entry.key;
            final daySchedule = entry.value;
            final isOpen = daySchedule['isOpen'] as bool;
            final openTime = daySchedule['open'] as String;
            final closeTime = daySchedule['close'] as String;
            final dayDisplay = day[0].toUpperCase() + day.substring(1);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            dayDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: isOpen,
                          onChanged: (value) {
                            setState(() {
                              _schedule[day]!['isOpen'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    if (isOpen) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Open Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectTime(day, 'open'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 8),
                                        Text(_formatTime(openTime)),
                                      ],
                                    ),
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
                                const Text(
                                  'Close Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () => _selectTime(day, 'close'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey[300]!),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time, size: 16),
                                        const SizedBox(width: 8),
                                        Text(_formatTime(closeTime)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Closed',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveSchedule,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Saving...'),
                      ],
                    )
                  : const Text('Save Schedule'),
            ),
          ),
        ],
      ),
    );
  }
} 