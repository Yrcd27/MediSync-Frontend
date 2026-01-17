import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_records_provider.dart';
import '../../models/full_blood_count.dart';

class FbcRecordsScreen extends StatefulWidget {
  const FbcRecordsScreen({super.key});

  @override
  State<FbcRecordsScreen> createState() => _FbcRecordsScreenState();
}

class _FbcRecordsScreenState extends State<FbcRecordsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testDateController = TextEditingController();
  final _haemoglobinController = TextEditingController();
  final _wbcController = TextEditingController();
  final _plateletController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _testDateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _testDateController.dispose();
    _haemoglobinController.dispose();
    _wbcController.dispose();
    _plateletController.dispose();
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

        final record = FullBloodCount(
          id: 0,
          testDate: _testDateController.text,
          haemoglobin: double.parse(_haemoglobinController.text),
          totalLeucocyteCount: double.parse(_wbcController.text),
          plateletCount: double.parse(_plateletController.text),
          imageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
        );

        final success = await healthProvider.addFBCRecord(
          record,
          authProvider.currentUser!.id,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('FBC record added successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            _haemoglobinController.clear();
            _wbcController.clear();
            _plateletController.clear();
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

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: const TextStyle(fontSize: 14),
      validator: validator,
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
                            'Add Full Blood Count Record',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple,
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
                              _buildCompactField(
                                controller: _haemoglobinController,
                                label: 'Haemoglobin (g/dL)',
                                hint: '14.5',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 5 || val > 20)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _wbcController,
                                label: 'WBC (cells/mcL)',
                                hint: '7500',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 3000 || val > 15000)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _plateletController,
                                label: 'Platelet (cells/mcL)',
                                hint: '250000',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null ||
                                      val < 100000 ||
                                      val > 500000)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                            ],
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
                                backgroundColor: Colors.purple,
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
                    if (healthProvider.fbcRecords.isEmpty) {
                      return Card(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bloodtype,
                                size: 48,
                                color: Colors.grey,
                              ),
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
                      itemCount: healthProvider.fbcRecords.length,
                      itemBuilder: (context, index) {
                        final record =
                            healthProvider.fbcRecords[healthProvider
                                    .fbcRecords
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

  Widget _buildCompactRecordCard(FullBloodCount record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getHemoglobinColor(record.haemoglobin),
          child: const Icon(Icons.bloodtype, color: Colors.white, size: 16),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Hb: ${record.haemoglobin.toStringAsFixed(1)} g/dL',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getHemoglobinColor(record.haemoglobin).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getHemoglobinStatus(record.haemoglobin),
                style: TextStyle(
                  color: _getHemoglobinColor(record.haemoglobin),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy').format(DateTime.parse(record.testDate)),
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'WBC: ${record.totalLeucocyteCount.toStringAsFixed(0)} cells/mcL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Platelets: ${record.plateletCount.toStringAsFixed(0)} cells/mcL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getHemoglobinColor(double hemoglobin) {
    if (hemoglobin >= 12.0) return Colors.green;
    if (hemoglobin >= 10.0) return Colors.orange;
    return Colors.red;
  }

  String _getHemoglobinStatus(double hemoglobin) {
    if (hemoglobin >= 12.0) return 'Normal';
    if (hemoglobin >= 10.0) return 'Low';
    return 'Very Low';
  }
}
