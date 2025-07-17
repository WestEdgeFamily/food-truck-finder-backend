import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdvancedScheduleScreen extends StatefulWidget {
  const AdvancedScheduleScreen({super.key});

  @override
  State<AdvancedScheduleScreen> createState() => _AdvancedScheduleScreenState();
}

class _AdvancedScheduleScreenState extends State<AdvancedScheduleScreen> {
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isMonthlyView = false;
  String? _currentTruckId;
  
  // Calendar variables for monthly view
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  Map<DateTime, Map<String, dynamic>> _scheduleEvents = {};
  
  // Schedule data for each day
  Map<String, Map<String, dynamic>> _weeklySchedule = {
    'monday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
    'tuesday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
    'wednesday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
    'thursday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
    'friday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
    'saturday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
    'sunday': {'isOpen': false, 'open': '11:00', 'close': '21:00'},
  };
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }
  
  Future<void> _initializeScreen() async {
    await _findUserTruck();
    if (_currentTruckId != null) {
      await _loadCurrentSchedule();
    }
  }
  
  Future<void> _findUserTruck() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      final businessName = authProvider.user?.businessName;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

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

      if (userTruck != null) {
        setState(() {
          _currentTruckId = (userTruck!['id'] ?? userTruck['_id']).toString();
        });
      }
    } catch (e) {
      debugPrint('Error finding user truck: $e');
    }
  }
  
  Future<void> _loadCurrentSchedule() async {
    setState(() => _isLoading = true);
    
    try {
      final scheduleResponse = await ApiService.getSchedule(_currentTruckId!);
      
      if (scheduleResponse['success'] == true && 
          scheduleResponse['schedule'] != null) {
        final schedule = scheduleResponse['schedule'];
        
        setState(() {
          for (String day in _weeklySchedule.keys) {
            if (schedule[day] != null) {
              _weeklySchedule[day] = {
                'isOpen': schedule[day]['isOpen'] ?? false,
                'open': schedule[day]['open'] ?? '11:00',
                'close': schedule[day]['close'] ?? '21:00',
              };
            }
          }
        });
        
        // Generate calendar events for monthly view
        _generateMonthlyEvents();
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _generateMonthlyEvents() {
    _scheduleEvents.clear();
    final now = DateTime.now();
    
    // Generate events for the next 60 days based on weekly schedule
    for (int i = 0; i < 60; i++) {
      final date = now.add(Duration(days: i));
      final dayName = _getDayName(date.weekday);
      
      if (_weeklySchedule[dayName]!['isOpen'] == true) {
        _scheduleEvents[DateTime(date.year, date.month, date.day)] = {
          'isOpen': true,
          'openTime': _weeklySchedule[dayName]!['open'],
          'closeTime': _weeklySchedule[dayName]!['close'],
          'type': 'regular',
        };
      }
    }
  }
  
  String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[(weekday - 1) % 7];
  }
  
  Future<void> _saveSchedule() async {
    if (_currentTruckId == null) return;
    
    setState(() => _isSaving = true);
    
    try {
      final response = await ApiService.updateSchedule(_currentTruckId!, _weeklySchedule);
      
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to save schedule');
      }
    } catch (e) {
      debugPrint('Error saving schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving schedule: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }
  
  Future<void> _selectTime(String day, String type) async {
    final currentTime = _weeklySchedule[day]![type];
    final timeParts = currentTime.split(':');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );
    
    if (picked != null) {
      setState(() {
        _weeklySchedule[day]![type] = 
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      
      // Update monthly events if needed
      if (_isMonthlyView) {
        _generateMonthlyEvents();
      }
    }
  }
  
  String _formatTime(String time) {
    final timeParts = time.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Manager'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // View toggle
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ToggleButtons(
              isSelected: [!_isMonthlyView, _isMonthlyView],
              onPressed: (index) {
                setState(() {
                  _isMonthlyView = index == 1;
                  if (_isMonthlyView) {
                    _generateMonthlyEvents();
                  }
                });
              },
              borderRadius: BorderRadius.circular(8),
              fillColor: Colors.white.withOpacity(0.2),
              selectedColor: Colors.white,
              color: Colors.white70,
              constraints: const BoxConstraints(minHeight: 35, minWidth: 60),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Week', style: TextStyle(fontSize: 12)),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Month', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          
          // Save button
          TextButton.icon(
            onPressed: _isSaving ? null : _saveSchedule,
            icon: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: Text(
              _isSaving ? 'Saving...' : 'Save',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isMonthlyView ? _buildMonthlyView() : _buildWeeklyView(),
    );
  }
  
  Widget _buildWeeklyView() {
    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set your weekly hours. Toggle each day on/off and adjust times as needed.',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Days list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._weeklySchedule.entries.map((entry) => _buildDayCard(entry.key, entry.value)),
              
              const SizedBox(height: 20),
              
              // Quick actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openAllWeekdays,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Open Mon-Fri'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openAllDays,
                              icon: const Icon(Icons.calendar_month),
                              label: const Text('Open All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _closeAllDays,
                          icon: const Icon(Icons.cancel_outlined),
                          label: const Text('Close All Days'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
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
      ],
    );
  }
  
  Widget _buildMonthlyView() {
    return Column(
      children: [
        // Header info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Row(
            children: [
              Icon(Icons.calendar_month, color: Colors.green[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Monthly calendar view. Tap a date to add special events or modify hours.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Calendar
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                TableCalendar<Map<String, dynamic>>(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: (day) {
                    final normalizedDay = DateTime(day.year, day.month, day.day);
                    return _scheduleEvents[normalizedDay] != null ? [_scheduleEvents[normalizedDay]!] : [];
                  },
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  calendarStyle: const CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: Colors.red),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showDayScheduleDialog(selectedDay);
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.only(top: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Selected day info
                if (_scheduleEvents[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)] != null)
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Schedule for ${_formatDate(_selectedDay)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule, size: 16, color: Colors.green),
                              const SizedBox(width: 8),
                              Text('Open: ${_formatTime(_scheduleEvents[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!['openTime'])}'),
                              const SizedBox(width: 16),
                              const Icon(Icons.schedule, size: 16, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Close: ${_formatTime(_scheduleEvents[DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day)]!['closeTime'])}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDayCard(String day, Map<String, dynamic> dayData) {
    final bool isOpen = dayData['isOpen'];
    final String openTime = dayData['open'];
    final String closeTime = dayData['close'];
    
    final String displayDay = day[0].toUpperCase() + day.substring(1);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Day name
            SizedBox(
              width: 80,
              child: Text(
                displayDay,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Time inputs (only show if open)
            if (isOpen) ...[
              // Open time
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(day, 'open'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(openTime),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              const Text('to', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              
              // Close time
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(day, 'close'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(closeTime),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Closed message
              const Expanded(
                child: Text(
                  'Closed',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            const SizedBox(width: 16),
            
            // Open/Closed toggle
            Switch(
              value: isOpen,
              onChanged: (value) {
                setState(() {
                  _weeklySchedule[day]!['isOpen'] = value;
                  if (_isMonthlyView) {
                    _generateMonthlyEvents();
                  }
                });
              },
              activeColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
  
  void _openAllWeekdays() {
    setState(() {
      const weekdays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday'];
      for (String day in weekdays) {
        _weeklySchedule[day]!['isOpen'] = true;
      }
      if (_isMonthlyView) {
        _generateMonthlyEvents();
      }
    });
  }
  
  void _openAllDays() {
    setState(() {
      for (String day in _weeklySchedule.keys) {
        _weeklySchedule[day]!['isOpen'] = true;
      }
      if (_isMonthlyView) {
        _generateMonthlyEvents();
      }
    });
  }
  
  void _closeAllDays() {
    setState(() {
      for (String day in _weeklySchedule.keys) {
        _weeklySchedule[day]!['isOpen'] = false;
      }
      if (_isMonthlyView) {
        _generateMonthlyEvents();
      }
    });
  }
  
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  
  void _showDayScheduleDialog(DateTime day) {
    final dayName = _getDayName(day.weekday);
    final daySchedule = _weeklySchedule[dayName]!;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Schedule for ${_formatDate(day)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('This is a ${dayName[0].toUpperCase() + dayName.substring(1)}'),
            const SizedBox(height: 16),
            if (daySchedule['isOpen']) ...[
              Text('Currently scheduled:'),
              Text('${_formatTime(daySchedule['open'])} - ${_formatTime(daySchedule['close'])}'),
            ] else ...[
              const Text('Currently closed on this day'),
            ],
            const SizedBox(height: 16),
            const Text(
              'Special events and custom schedules coming soon!',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}