import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PredictionScreen extends StatefulWidget {
  const PredictionScreen({super.key});

  @override
  State<PredictionScreen> createState() => _PredictionScreenState();
}

class _PredictionScreenState extends State<PredictionScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final TextEditingController _mileageController = TextEditingController();
  final TextEditingController _engineCapacityController = TextEditingController();

  // Dropdown values
  String? _selectedModelYear;
  String? _selectedEngineType;
  String? _selectedTransmission;
  String? _selectedRegisteredIn;
  String? _selectedBodyType;
  String? _selectedCarName;
  
  bool _isLoading = false;
  bool _isFetchingOptions = true;

  // Lists for dropdowns
  List<String> _modelYears = [];
  List<String> _engineTypes = [];
  List<String> _transmissions = [];
  List<String> _registeredInList = [];
  List<String> _bodyTypes = [];
  List<String> _carNames = [];

  @override
  void initState() {
    super.initState();
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final uri = Uri.parse('http://127.0.0.1:8000/options');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _modelYears = (data['model_year'] as List).map((e) => e.toString()).toList();
          _engineTypes = (data['engine_type'] as List).map((e) => e.toString()).toList();
          _transmissions = (data['transmission'] as List).map((e) => e.toString()).toList();
          _registeredInList = (data['registered_in'] as List).map((e) => e.toString()).toList();
          _bodyTypes = (data['body_type'] as List).map((e) => e.toString()).toList();
          _carNames = (data['title'] as List).map((e) => e.toString()).toList();
          _isFetchingOptions = false;
        });
      } else {
        setState(() => _isFetchingOptions = false);
      }
    } catch (e) {
      setState(() => _isFetchingOptions = false);
    }
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _engineCapacityController.dispose();
    super.dispose();
  }

  Future<void> _predictPrice() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // For Android emulators, typically 10.0.2.2 is used to access host localhost.
      // For Windows/Web, 127.0.0.1 is used.
      final uri = Uri.parse('http://127.0.0.1:8000/predict');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'car_name': _selectedCarName,
          'model_year': int.tryParse(_selectedModelYear ?? "0") ?? 0,
          'mileage': double.tryParse(_mileageController.text) ?? 0.0,
          'engine_type': _selectedEngineType,
          'engine_capacity': double.tryParse(_engineCapacityController.text) ?? 0.0,
          'transmission': _selectedTransmission,
          'registered_in': _selectedRegisteredIn,
          'body_type': _selectedBodyType,
          
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String predictedValue = data['prediction']?.toString() ?? 
                                data['predicted_price']?.toString() ?? 
                                data.toString();
        _showReportDialog(predictedValue);
      } else {
        _showResultDialog('Server Error', 'Status code: ${response.statusCode}\n${response.body}', isSuccess: false);
      }
    } catch (e) {
      _showResultDialog('Connection Error', 'Could not connect to the server at 127.0.0.1:8000.\n\nMake sure your FastAPI backend is running.\n\nDetails: $e', isSuccess: false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResultDialog(String title, String message, {bool isSuccess = true}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1E1E2C),
        title: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.greenAccent : Colors.redAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          message, 
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE50000), // PakWheels red
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(String predictedValue) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.assignment, color: Color(0xFF38BDF8), size: 28),
                      const SizedBox(width: 10),
                      const Text(
                        'Prediction Summary',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildReportRow('Car Name', _selectedCarName ?? 'N/A'),
                        _buildReportRow('Model Year', _selectedModelYear ?? 'N/A'),
                        _buildReportRow('Body Type', _selectedBodyType ?? 'N/A'),
                        _buildReportRow('Engine Type', _selectedEngineType ?? 'N/A'),
                        _buildReportRow('Engine Capacity', '${_engineCapacityController.text} cc'),
                        _buildReportRow('Transmission', _selectedTransmission ?? 'N/A'),
                        _buildReportRow('Mileage', '${_mileageController.text} km'),
                        _buildReportRow('Registered In', _selectedRegisteredIn ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE50000), Color(0xFFB30000)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50000).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Estimated Market Value',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Rs. $predictedValue',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF38BDF8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CLOSE SUMMARY',
                        style: TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchableModal(String title, List<String> items, void Function(String?) onChanged) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _SearchableList(title: title, items: items, onChanged: onChanged);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 700;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, color: Color(0xFFE50000), size: 28),
            const SizedBox(width: 12),
            Text(
              'PakWheels AI Predictor',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: isMobile ? 20 : 26,
                letterSpacing: 1.2,
                shadows: const [
                  Shadow(color: Colors.black45, offset: Offset(0, 2), blurRadius: 6),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isFetchingOptions 
          ? const Center(child: CircularProgressIndicator()) 
          : Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A), // Slate 900
              Color(0xFF1E293B), // Slate 800
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Description Area
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: [
                          Text(
                            'Discover the true value of your car',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isMobile ? 24 : 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Powered by advanced XGBoost Machine Learning',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Main Form Card
                    Container(
                      padding: EdgeInsets.all(isMobile ? 24 : 40),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(Icons.info_outline, 'Basic Information'),
                            const SizedBox(height: 20),
                            if (isMobile)
                              Column(
                                children: [
                                  _buildDropdown(label: 'Car Name', icon: Icons.branding_watermark, value: _selectedCarName, items: _carNames, onChanged: (val) => setState(() => _selectedCarName = val)),
                                  _buildDropdown(label: 'Model Year', icon: Icons.calendar_today, value: _selectedModelYear, items: _modelYears, onChanged: (val) => setState(() => _selectedModelYear = val)),
                                  _buildDropdown(label: 'Body Type', icon: Icons.category, value: _selectedBodyType, items: _bodyTypes, onChanged: (val) => setState(() => _selectedBodyType = val)),
                                ],
                              )
                            else
                              Wrap(
                                spacing: 20, runSpacing: 20,
                                children: [
                                  _halfWidth(_buildDropdown(label: 'Car Name', icon: Icons.branding_watermark, value: _selectedCarName, items: _carNames, onChanged: (val) => setState(() => _selectedCarName = val))),
                                  _halfWidth(_buildDropdown(label: 'Model Year', icon: Icons.calendar_today, value: _selectedModelYear, items: _modelYears, onChanged: (val) => setState(() => _selectedModelYear = val))),
                                  _halfWidth(_buildDropdown(label: 'Body Type', icon: Icons.category, value: _selectedBodyType, items: _bodyTypes, onChanged: (val) => setState(() => _selectedBodyType = val))),
                                ],
                              ),

                            const SizedBox(height: 30),
                            _buildSectionHeader(Icons.engineering, 'Engine & Performance'),
                            const SizedBox(height: 20),
                            if (isMobile)
                              Column(
                                children: [
                                  _buildDropdown(label: 'Engine Type', icon: Icons.local_gas_station, value: _selectedEngineType, items: _engineTypes, onChanged: (val) => setState(() => _selectedEngineType = val)),
                                  _buildTextField(label: 'Engine Capacity (cc)', controller: _engineCapacityController, icon: Icons.settings_suggest, hint: 'e.g. 1800'),
                                  _buildDropdown(label: 'Transmission', icon: Icons.settings, value: _selectedTransmission, items: _transmissions, onChanged: (val) => setState(() => _selectedTransmission = val)),
                                  _buildTextField(label: 'Mileage (km)', controller: _mileageController, icon: Icons.speed, hint: 'e.g. 45000'),
                                ],
                              )
                            else
                              Wrap(
                                spacing: 20, runSpacing: 20,
                                children: [
                                  _halfWidth(_buildDropdown(label: 'Engine Type', icon: Icons.local_gas_station, value: _selectedEngineType, items: _engineTypes, onChanged: (val) => setState(() => _selectedEngineType = val))),
                                  _halfWidth(_buildTextField(label: 'Engine Capacity (cc)', controller: _engineCapacityController, icon: Icons.settings_suggest, hint: 'e.g. 1800')),
                                  _halfWidth(_buildDropdown(label: 'Transmission', icon: Icons.settings, value: _selectedTransmission, items: _transmissions, onChanged: (val) => setState(() => _selectedTransmission = val))),
                                  _halfWidth(_buildTextField(label: 'Mileage (km)', controller: _mileageController, icon: Icons.speed, hint: 'e.g. 45000')),
                                ],
                              ),

                            const SizedBox(height: 30),
                            _buildSectionHeader(Icons.location_on, 'Location & Registration'),
                            const SizedBox(height: 20),
                            if (isMobile)
                              Column(
                                children: [
                                  _buildDropdown(label: 'Registered In', icon: Icons.map, value: _selectedRegisteredIn, items: _registeredInList, onChanged: (val) => setState(() => _selectedRegisteredIn = val)),
                                 
                                ],
                              )
                            else
                              Wrap(
                                spacing: 20, runSpacing: 20,
                                children: [
                                  _halfWidth(_buildDropdown(label: 'Registered In', icon: Icons.map, value: _selectedRegisteredIn, items: _registeredInList, onChanged: (val) => setState(() => _selectedRegisteredIn = val))),
                                  ],
                              ),

                            const SizedBox(height: 40),
                            
                            // Predict Button
                            SizedBox(
                              width: double.infinity,
                              height: 65,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _predictPrice,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE50000), // PakWheels primary red
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(0xFFE50000).withOpacity(0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 8,
                                  shadowColor: const Color(0xFFE50000).withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 28,
                                        width: 28,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.auto_graph, size: 24),
                                          SizedBox(width: 10),
                                          Text(
                                            'CALCULATE PRICE',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                            ),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF38BDF8), size: 22),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _halfWidth(Widget child) {
    return LayoutBuilder(builder: (context, constraints) {
      return SizedBox(
        width: (constraints.maxWidth - 20) / 2,
        child: child,
      );
    });
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: _inputDecoration(label, hint, icon),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          if (double.tryParse(value) == null) {
            return 'Invalid number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String>? items,
    required void Function(String?) onChanged,
  }) {
    final List<String> safeItems = items ?? [];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: FormField<String>(
        initialValue: value,
        validator: (val) {
          if (value == null || value.isEmpty) {
            return 'Required';
          }
          return null;
        },
        builder: (FormFieldState<String> state) {
          return InkWell(
            onTap: () {
              _showSearchableModal(label, safeItems, (selectedValue) {
                onChanged(selectedValue);
                state.didChange(selectedValue);
              });
            },
            child: InputDecorator(
              decoration: _inputDecoration(label, 'Select $label', icon).copyWith(
                errorText: state.errorText,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      value ?? 'Select $label',
                      style: TextStyle(
                        color: value == null ? Colors.white.withOpacity(0.3) : Colors.white,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration(String label, String hint, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      prefixIcon: Icon(icon, color: const Color(0xFF38BDF8).withOpacity(0.8)),
      filled: true,
      fillColor: const Color(0xFF0F172A).withOpacity(0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

class _SearchableList extends StatefulWidget {
  final String title;
  final List<String> items;
  final void Function(String?) onChanged;

  const _SearchableList({required this.title, required this.items, required this.onChanged});

  @override
  State<_SearchableList> createState() => _SearchableListState();
}

class _SearchableListState extends State<_SearchableList> {
  late List<String> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterList);
  }

  void _filterList() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) => item.toLowerCase().contains(query)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Select ${widget.title}',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                return ListTile(
                  title: Text(item, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    widget.onChanged(item);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
