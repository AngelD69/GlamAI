import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/api_service.dart';
import '../utils/exceptions.dart';
import '../utils/logger.dart';
import 'book_appointment_screen.dart';

class ServicesScreen extends StatefulWidget {
  final int userId;
  const ServicesScreen({super.key, required this.userId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  static const _tag = 'ServicesScreen';

  List<Service> _services = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    AppLogger.info(_tag, 'Loading services');
    setState(() { _loading = true; _error = null; });
    try {
      final services = await ApiService.getServices();
      setState(() { _services = services; _loading = false; });
      AppLogger.debug(_tag, 'Loaded ${services.length} services');
    } on NetworkException catch (e) {
      AppLogger.error(_tag, 'Network error loading services', e);
      setState(() { _error = e.message; _loading = false; });
    } on AppException catch (e) {
      AppLogger.error(_tag, 'Error loading services', e);
      setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Our Services')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadServices,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _services.isEmpty
                  ? const Center(child: Text('No services available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final s = _services[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE91E8C),
                              child: Icon(Icons.spa, color: Colors.white),
                            ),
                            title: Text(s.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: s.description != null
                                ? Text(s.description!)
                                : null,
                            trailing: Text('NPR ${s.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: Color(0xFFE91E8C),
                                    fontWeight: FontWeight.bold)),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookAppointmentScreen(
                                  userId: widget.userId,
                                  service: s,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
