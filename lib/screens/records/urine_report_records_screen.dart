import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_records_provider.dart';
import '../../models/urine_report.dart';

class UrineReportRecordsScreen extends StatefulWidget {
  const UrineReportRecordsScreen({super.key});

  @override
  State<UrineReportRecordsScreen> createState() =>
      _UrineReportRecordsScreenState();
}

class _UrineReportRecordsScreenState extends State<UrineReportRecordsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testDateController = TextEditingController();
  final _specificGravityController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String _selectedColor = 'Yellow';
  String _selectedAppearance = 'Clear';
  String _selectedProtein = 'Negative';
  String _selectedSugar = 'Negative';

  bool _isSubmitting = false;

  final List<String> _colorOptions = [
    'Pale Yellow',
    'Yellow',
    'Dark Yellow',
    'Amber',
    'Red',
    'Brown',
    'Clear',
  ];

  final List<String> _appearanceOptions = ['Clear', 'Cloudy', 'Turbid', 'Hazy'];

  final List<String> _proteinOptions = [
    'Negative',
    'Trace',
    '1+',
    '2+',
    '3+',
    '4+',
  ];

  final List<String> _sugarOptions = [
    'Negative',
    'Trace',
    '1+',
    '2+',
    '3+',
    '4+',
  ];

  @override
  void initState() {
    super.initState();
    _testDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _testDateController.dispose();
    _specificGravityController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      _testDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  void _addRecord() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final authProvider = context.read<AuthProvider>();
        final healthProvider = context.read<HealthRecordsProvider>();

        if (authProvider.currentUser == null) return;

        final record = UrineReport(
          id: 0,
          testDate: _testDateController.text,
          color: _selectedColor,
          appearance: _selectedAppearance,
          protein: _selectedProtein,
          sugar: _selectedSugar,
          specificGravity: _specificGravityController.text.isNotEmpty
              ? double.parse(_specificGravityController.text)
              : 1.020, // Default value if not provided
          imageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
        );

        final success = await healthProvider.addUrineRecord(
          record,
          authProvider.currentUser!.id,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Urine report record added successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            _selectedColor = 'Yellow';
            _selectedAppearance = 'Clear';
            _selectedProtein = 'Negative';
            _selectedSugar = 'Negative';
            _specificGravityController.clear();
            _imageUrlController.clear();
            _testDateController.text = DateFormat(
              'yyyy-MM-dd',
            ).format(DateTime.now());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  healthProvider.errorMessage ?? 'Error adding record',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      value: value,
      style: const TextStyle(fontSize: 14, color: Colors.black),
      items: options.map((String option) {
        return DropdownMenuItem<String>(value: option, child: Text(option));
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final columnCount = isWide ? 2 : 1;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth * 0.02,
              vertical: 8.0,
            ),
            child: Column(
              children: [
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Add Urine Report Record',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber[700],
                                ),
                          ),
                          const SizedBox(height: 12),

                          InkWell(
                            onTap: _selectDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Test Date',
                                suffixIcon: const Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                _testDateController.text,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          GridView.count(
                            crossAxisCount: columnCount,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: isWide ? 4.0 : 5.5,
                            children: [
                              _buildDropdownField(
                                label: 'Color',
                                value: _selectedColor,
                                options: _colorOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedColor = value ?? 'Yellow';
                                  });
                                },
                              ),
                              _buildDropdownField(
                                label: 'Appearance',
                                value: _selectedAppearance,
                                options: _appearanceOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedAppearance = value ?? 'Clear';
                                  });
                                },
                              ),
                              _buildDropdownField(
                                label: 'Protein',
                                value: _selectedProtein,
                                options: _proteinOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedProtein = value ?? 'Negative';
                                  });
                                },
                              ),
                              _buildDropdownField(
                                label: 'Sugar',
                                value: _selectedSugar,
                                options: _sugarOptions,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedSugar = value ?? 'Negative';
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _specificGravityController,
                            decoration: InputDecoration(
                              labelText: 'Specific Gravity (Optional)',
                              hintText: '1.020',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: 'Report Image (Optional)',
                              hintText: 'URL or file path',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _addRecord,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Add Record',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Consumer<HealthRecordsProvider>(
                  builder: (context, healthProvider, child) {
                    if (healthProvider.urineRecords.isEmpty) {
                      return Card(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.opacity, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                'No records yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: healthProvider.urineRecords.length,
                      itemBuilder: (context, index) {
                        final record =
                            healthProvider.urineRecords[healthProvider
                                    .urineRecords
                                    .length -
                                1 -
                                index];
                        return _buildCompactRecordCard(record);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactRecordCard(UrineReport record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getUrineColor(record.color),
          child: const Icon(Icons.opacity, color: Colors.white, size: 16),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Color: ${record.color}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            if (record.protein != 'Negative' || record.sugar != 'Negative')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Abnormal',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat(
                'MMM dd, yyyy',
              ).format(DateTime.parse(record.testDate)),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 2),
            Text(
              'Protein: ${record.protein}, Sugar: ${record.sugar}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrineColor(String color) {
    switch (color.toLowerCase()) {
      case 'pale yellow':
      case 'yellow':
        return Colors.yellow[700]!;
      case 'dark yellow':
      case 'amber':
        return Colors.amber[800]!;
      case 'red':
        return Colors.red;
      case 'brown':
        return Colors.brown;
      case 'clear':
        return Colors.blue[200]!;
      default:
        return Colors.amber[700]!;
    }
  }
}
