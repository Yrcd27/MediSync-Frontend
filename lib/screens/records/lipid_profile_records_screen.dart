import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_records_provider.dart';
import '../../models/lipid_profile.dart';

class LipidProfileRecordsScreen extends StatefulWidget {
  const LipidProfileRecordsScreen({super.key});

  @override
  State<LipidProfileRecordsScreen> createState() =>
      _LipidProfileRecordsScreenState();
}

class _LipidProfileRecordsScreenState extends State<LipidProfileRecordsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testDateController = TextEditingController();
  final _totalCholesterolController = TextEditingController();
  final _hdlController = TextEditingController();
  final _ldlController = TextEditingController();
  final _triglyceridesController = TextEditingController();
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
    _totalCholesterolController.dispose();
    _hdlController.dispose();
    _ldlController.dispose();
    _triglyceridesController.dispose();
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

        final record = LipidProfile(
          id: 0,
          testDate: _testDateController.text,
          totalCholesterol: double.parse(_totalCholesterolController.text),
          hdl: double.parse(_hdlController.text),
          ldl: double.parse(_ldlController.text),
          vldl:
              double.parse(_triglyceridesController.text) /
              5, // VLDL is typically calculated as triglycerides/5
          triglycerides: double.parse(_triglyceridesController.text),
          imageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
        );

        final success = await healthProvider.addLipidRecord(
          record,
          authProvider.currentUser!.id,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lipid profile record added successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            _totalCholesterolController.clear();
            _hdlController.clear();
            _ldlController.clear();
            _triglyceridesController.clear();
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
                            'Add Lipid Profile Record',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
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
                                controller: _totalCholesterolController,
                                label: 'Total Cholesterol (mg/dL)',
                                hint: '200',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 100 || val > 400)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _hdlController,
                                label: 'HDL (mg/dL)',
                                hint: '50',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 20 || val > 100)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _ldlController,
                                label: 'LDL (mg/dL)',
                                hint: '100',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 50 || val > 300)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _triglyceridesController,
                                label: 'Triglycerides (mg/dL)',
                                hint: '150',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 50 || val > 500)
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
                                backgroundColor: Colors.blue,
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
                    if (healthProvider.lipidRecords.isEmpty) {
                      return Card(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.favorite,
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
                      itemCount: healthProvider.lipidRecords.length,
                      itemBuilder: (context, index) {
                        final record =
                            healthProvider.lipidRecords[healthProvider
                                    .lipidRecords
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

  Widget _buildCompactRecordCard(LipidProfile record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getCholesterolColor(record.totalCholesterol),
          child: const Icon(Icons.favorite, color: Colors.white, size: 16),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Total: ${record.totalCholesterol.toStringAsFixed(0)} mg/dL',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCholesterolColor(
                  record.totalCholesterol,
                ).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getCholesterolStatus(record.totalCholesterol),
                style: TextStyle(
                  color: _getCholesterolColor(record.totalCholesterol),
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
                        'HDL: ${record.hdl.toStringAsFixed(0)} mg/dL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'LDL: ${record.ldl.toStringAsFixed(0)} mg/dL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Triglycerides: ${record.triglycerides.toStringAsFixed(0)} mg/dL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'TC/HDL: ${(record.totalCholesterol / record.hdl).toStringAsFixed(1)}',
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

  Color _getCholesterolColor(double cholesterol) {
    if (cholesterol < 200) return Colors.green;
    if (cholesterol < 240) return Colors.orange;
    return Colors.red;
  }

  String _getCholesterolStatus(double cholesterol) {
    if (cholesterol < 200) return 'Normal';
    if (cholesterol < 240) return 'Borderline';
    return 'High';
  }
}
