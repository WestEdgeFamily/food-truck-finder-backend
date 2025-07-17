import 'package:flutter/material.dart';

class PostComposerScreen extends StatefulWidget {
  final String truckId;

  const PostComposerScreen({Key? key, required this.truckId}) : super(key: key);

  @override
  State<PostComposerScreen> createState() => _PostComposerScreenState();
}

class _PostComposerScreenState extends State<PostComposerScreen> {
  final _contentController = TextEditingController();
  List<String> _selectedPlatforms = [];
  DateTime _scheduledTime = DateTime.now();
  bool _isScheduled = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        backgroundColor: const Color(0xFF4ECDC4),
        actions: [
          TextButton(
            onPressed: _selectedPlatforms.isNotEmpty && _contentController.text.isNotEmpty
                ? _publishPost
                : null,
            child: const Text(
              'Post',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content input
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'What would you like to share?',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            // Platform selection
            const Text(
              'Select Platforms',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: [
                _buildPlatformChip('Facebook', Icons.facebook),
                _buildPlatformChip('Instagram', Icons.camera_alt),
                _buildPlatformChip('Twitter', Icons.flutter_dash),
              ],
            ),
            const SizedBox(height: 20),

            // Schedule toggle
            SwitchListTile(
              title: const Text('Schedule Post'),
              value: _isScheduled,
              onChanged: (value) {
                setState(() {
                  _isScheduled = value;
                });
              },
            ),

            if (_isScheduled) ...[
              const SizedBox(height: 10),
              ListTile(
                title: const Text('Schedule Date & Time'),
                subtitle: Text(_scheduledTime.toString().split('.')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformChip(String platform, IconData icon) {
    final isSelected = _selectedPlatforms.contains(platform);
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(platform),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedPlatforms.add(platform);
          } else {
            _selectedPlatforms.remove(platform);
          }
        });
      },
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledTime),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _publishPost() {
    // TODO: Implement post publishing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post scheduled successfully!')),
    );
    Navigator.pop(context);
  }
}