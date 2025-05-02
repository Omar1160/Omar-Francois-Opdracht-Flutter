import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:toesteldelen_project/constants/colors.dart';
import 'package:toesteldelen_project/models/appliance.dart';
import 'package:toesteldelen_project/providers/auth_provider.dart';
import 'package:toesteldelen_project/providers/appliance_provider.dart'; // Corrected package name
import 'package:geolocator/geolocator.dart';

class AddApplianceScreen extends StatefulWidget {
  final Appliance? appliance; // For editing

  const AddApplianceScreen({Key? key, this.appliance}) : super(key: key);

  @override
  State<AddApplianceScreen> createState() => _AddApplianceScreenState();
}

class _AddApplianceScreenState extends State<AddApplianceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  String _category = 'Cleaning';
  File? _image;
  final picker = ImagePicker();
  List<String> _availability = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.appliance != null) {
      _titleController.text = widget.appliance!.title;
      _descriptionController.text = widget.appliance!.description;
      _priceController.text = widget.appliance!.pricePerDay.toString();
      _category = widget.appliance!.category;
      _availability = List.from(widget.appliance!.availability);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 7)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _availability.clear();

        DateTime current = picked.start;
        while (current.isBefore(picked.end) ||
            current.isAtSameMomentAs(picked.end)) {
          _availability.add(current.toIso8601String().split('T')[0]);
          current = current.add(const Duration(days: 1));
        }
      });
    }
  }

  Future<Position?> _getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<void> _addOrUpdateAppliance() async {
    final user = Provider.of<AppAuthProvider>(context, listen: false).user;
    if (user == null || _availability.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields.')),
      );
      return;
    }

    if (widget.appliance == null && _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = widget.appliance?.imageUrl ?? '';
      Position? position = await _getCurrentPosition();
      String location = widget.appliance?.location ??
          (position != null
              ? '${position.latitude}, ${position.longitude}'
              : '50.8503, 4.3517');

      if (widget.appliance == null) {
        // Add new appliance
        imageUrl = await Provider.of<ApplianceProvider>(context, listen: false)
            .addAppliance(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          pricePerDay: double.parse(_priceController.text),
          category: _category,
          ownerId: user.id,
          image: _image!,
          location: location,
          availability: _availability,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appliance added successfully!')),
        );
      } else {
        // Update existing appliance
        Appliance updatedAppliance = Appliance(
          id: widget.appliance!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          pricePerDay: double.parse(_priceController.text),
          category: _category,
          ownerId: user.id,
          imageUrl: imageUrl,
          location: location,
          availability: _availability,
        );

        await Provider.of<ApplianceProvider>(context, listen: false)
            .updateAppliance(updatedAppliance);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appliance updated successfully!')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(widget.appliance == null ? 'Add Appliance' : 'Edit Appliance'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: _image == null && widget.appliance == null
                          ? const Center(child: Text('Add Photo'))
                          : _image != null
                              ? Image.file(_image!, fit: BoxFit.cover)
                              : Image.network(widget.appliance!.imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (€/day)',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: ['Cleaning', 'Gardening', 'Cooking', 'Tools']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Availability:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: _availability.map((date) {
                      return Chip(
                        label: Text(date),
                        onDeleted: () {
                          setState(() {
                            _availability.remove(date);
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _pickDateRange,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Select Availability Dates',
                        style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _addOrUpdateAppliance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 100, vertical: 16),
                    ),
                    child: Text(
                      widget.appliance == null ? 'Add Appliance' : 'Update Appliance',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}