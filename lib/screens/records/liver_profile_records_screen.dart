import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/health_records_provider.dart';
import '../../models/liver_profile.dart';

class LiverProfileRecordsScreen extends StatefulWidget {
  const LiverProfileRecordsScreen({super.key});

  @override
  State<LiverProfileRecordsScreen> createState() =>
      _LiverProfileRecordsScreenState();
}

class _LiverProfileRecordsScreenState extends State<LiverProfileRecordsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _testDateController = TextEditingController();
  final _totalProteinController = TextEditingController();
  final _albuminController = TextEditingController();
  final _bilirubinController = TextEditingController();
  final _sgptController = TextEditingController();
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
    _totalProteinController.dispose();
    _albuminController.dispose();
    _bilirubinController.dispose();
    _sgptController.dispose();
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

        final record = LiverProfile(
          id: 0,
          testDate: _testDateController.text,
          proteinTotalSerum: double.parse(_totalProteinController.text),
          albuminSerum: double.parse(_albuminController.text),
          bilirubinTotalSerum: double.parse(_bilirubinController.text),
          sgpt: double.parse(_sgptController.text),
          imageUrl: _imageUrlController.text.isEmpty
              ? null
              : _imageUrlController.text,
        );

        final success = await healthProvider.addLiverRecord(
          record,
          authProvider.currentUser!.id,
        );

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Liver profile record added successfully!'),
                backgroundColor: Colors.green,
              ),
            );

            _totalProteinController.clear();
            _albuminController.clear();
            _bilirubinController.clear();
            _sgptController.clear();
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
                            'Add Liver Profile Record',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
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
                                controller: _totalProteinController,
                                label: 'Total Protein (g/dL)',
                                hint: '7.0',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 4 || val > 10)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _albuminController,
                                label: 'Albumin (g/dL)',
                                hint: '4.0',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 2 || val > 6)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _bilirubinController,
                                label: 'Bilirubin (mg/dL)',
                                hint: '1.0',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 0 || val > 5)
                                    return 'Invalid range';
                                  return null;
                                },
                              ),
                              _buildCompactField(
                                controller: _sgptController,
                                label: 'SGPT/ALT (U/L)',
                                hint: '30',
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Required';
                                  final val = double.tryParse(value);
                                  if (val == null || val < 5 || val > 200)
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
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _addRecord,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
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
                                      style: TextStyle(fontSize: 16),
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
                    if (healthProvider.liverRecords.isEmpty) {
                      return Card(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.science, size: 48, color: Colors.grey),
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
                      itemCount: healthProvider.liverRecords.length,
                      itemBuilder: (context, index) {
                        final record =
                            healthProvider.liverRecords[healthProvider
                                    .liverRecords
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

  Widget _buildCompactRecordCard(LiverProfile record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getSGPTColor(record.sgpt),
          child: const Icon(Icons.science, color: Colors.white, size: 16),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'SGPT: ${record.sgpt.toStringAsFixed(0)} U/L',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getSGPTColor(record.sgpt).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getSGPTStatus(record.sgpt),
                style: TextStyle(
                  color: _getSGPTColor(record.sgpt),
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
                        'Total Protein: ${record.proteinTotalSerum.toStringAsFixed(1)} g/dL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Albumin: ${record.albuminSerum.toStringAsFixed(1)} g/dL',
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
                        'Bilirubin: ${record.bilirubinTotalSerum.toStringAsFixed(1)} mg/dL',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const Expanded(child: SizedBox()), // Empty space
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSGPTColor(double sgpt) {
    if (sgpt <= 40) return Colors.green;
    if (sgpt <= 80) return Colors.orange;
    return Colors.red;
  }

  String _getSGPTStatus(double sgpt) {
    if (sgpt <= 40) return 'Normal';
    if (sgpt <= 80) return 'Elevated';
    return 'High';
  }
}
