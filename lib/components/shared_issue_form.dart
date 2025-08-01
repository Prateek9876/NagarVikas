// lib/widgets/shared_issue_form.dart

import 'dart:io';
import 'package:nagarvikas/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../screen/done_screen.dart';
import '../service/local_status_storage.dart';

class SharedIssueForm extends StatefulWidget {
  final String issueType;
  final String headingText;
  final String infoText;
  final String imageAsset;

  const SharedIssueForm({
    super.key,
    required this.issueType,
    required this.headingText,
    required this.infoText,
    required this.imageAsset,
  });

  @override
  State<SharedIssueForm> createState() => _SharedIssueFormState();
}

class _SharedIssueFormState extends State<SharedIssueForm> {
  String? _selectedState;
  String? _selectedCity;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  File? _selectedVideo;
  VideoPlayerController? _videoController;
  bool _isUploading = false;
  late stt.SpeechToText _speech;
  bool _isListening = false;
  final NotificationService _notificationService =
      NotificationService(); // Add this

  int get _remainingCharacters => 250 - _descriptionController.text.length;
  bool get _canSubmit {
    return _selectedState != null &&
        _selectedCity != null &&
        _locationController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        (_selectedImage != null || _selectedVideo != null);
  }

  final Map<String, List<String>> _states = {
    'Andhra Pradesh': [
      'Visakhapatnam',
      'Vijayawada',
      'Guntur',
      'Nellore',
      'Tirupati'
    ],
    'Arunachal Pradesh': [
      'Itanagar',
      'Tawang',
      'Naharlagun',
      'Ziro',
      'Pasighat'
    ],
    'Assam': ['Guwahati', 'Silchar', 'Dibrugarh', 'Jorhat', 'Tezpur'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg'],
    'Goa': ['Panaji', 'Vasco da Gama', 'Margao', 'Mapusa', 'Ponda'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Bhavnagar'],
    'Haryana': ['Chandigarh', 'Faridabad', 'Gurugram', 'Panipat', 'Ambala'],
    'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Solan', 'Mandi'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro', 'Hazaribagh'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubballi', 'Mangaluru', 'Belagavi'],
    'Kerala': [
      'Thiruvananthapuram',
      'Kochi',
      'Kozhikode',
      'Thrissur',
      'Kannur'
    ],
    'Madhya Pradesh': ['Bhopal', 'Indore', 'Jabalpur', 'Gwalior', 'Ujjain'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad'],
    'Manipur': ['Imphal', 'Bishnupur', 'Thoubal', 'Ukhrul', 'Senapati'],
    'Meghalaya': ['Shillong', 'Tura', 'Nongstoin', 'Jowai', 'Baghmara'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai', 'Serchhip', 'Kolasib'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Tuensang', 'Wokha'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Sambalpur', 'Puri'],
    'Punjab': ['Amritsar', 'Ludhiana', 'Chandigarh', 'Jalandhar', 'Patiala'],
    'Rajasthan': ['Jaipur', 'Udaipur', 'Jodhpur', 'Kota', 'Bikaner'],
    'Sikkim': ['Gangtok', 'Namchi', 'Mangan', 'Gyalshing', 'Ravangla'],
    'Tamil Nadu': [
      'Chennai',
      'Coimbatore',
      'Madurai',
      'Tiruchirappalli',
      'Salem'
    ],
    'Telangana': [
      'Hyderabad',
      'Warangal',
      'Nizamabad',
      'Karimnagar',
      'Khammam'
    ],
    'Tripura': ['Agartala', 'Dharmanagar', 'Udaipur', 'Ambassa', 'Kailashahar'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Agra', 'Varanasi', 'Prayagraj'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Rishikesh', 'Nainital', 'Almora'],
    'West Bengal': ['Kolkata', 'Howrah', 'Durgapur', 'Siliguri', 'Asansol'],
  };

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeServices();
    _descriptionController.addListener(() {
      setState(() {}); // rebuild when text changes
    });
    _locationController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _initializeServices() async {
    await _requestPermissions();
    await _notificationService.initialize();
  }

  Future<void> _requestPermissions() async {
    await Permission.microphone.request();
    await Permission.notification.request();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permission denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              "Location permission permanently denied. Please enable it from settings.");
      await openAppSettings(); // from permission_handler
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          // ignore: deprecated_member_use
          desiredAccuracy: LocationAccuracy.high);
      final placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      final place = placemarks.first;
      setState(() {
        _locationController.text =
            "${place.subLocality}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.isoCountryCode}";
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get location: $e");
    }
  }

  void _confirmMediaRemoval({required bool isVideo}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Remove ${isVideo ? 'video' : 'image'}?"),
        content:
            Text("Do you want to remove the ${isVideo ? 'video' : 'image'}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                if (isVideo) {
                  _videoController?.dispose();
                  _videoController = null;
                  _selectedVideo = null;
                } else {
                  _selectedImage = null;
                }
              });
            },
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_selectedVideo != null) {
      Fluttertoast.showToast(msg: "Remove the video to upload image.");
      return;
    }

    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    if (_selectedImage != null) {
      setState(() {
        _selectedImage = null;
      });
    }

    final pickedFile =
        await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final controller = VideoPlayerController.file(File(pickedFile.path));
      await controller.initialize();
      if (controller.value.duration.inSeconds > 10) {
        Fluttertoast.showToast(msg: "Video must be under 10s");
        return;
      }
      setState(() {
        _selectedVideo = File(pickedFile.path);
        _videoController?.dispose();
        _videoController = controller;
      });
    }
  }

  Future<String?> _uploadToCloudinary(File file, bool isVideo) async {
    const cloudName = 'dved2q851';
    const uploadPreset = 'flutter_uploads';
    final url =
        'https://api.cloudinary.com/v1_1/$cloudName/${isVideo ? "video" : "image"}/upload';

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'upload_preset': uploadPreset,
      });
      final response = await Dio().post(url, data: formData);
      return response.data['secure_url'];
    } catch (_) {
      return null;
    }
  }

  void _startListening() async {
    if (await _speech.initialize()) {
      setState(() => _isListening = true);
      _speech.listen(
        onResult: (result) {
          setState(() => _descriptionController.text = result.recognizedWords);
        },
      );
    }
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  Future<void> _submitForm() async {
    if (_selectedImage == null && _selectedVideo == null) {
      Fluttertoast.showToast(msg: "Please upload image or video.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      final file = _selectedVideo ?? _selectedImage!;
      final isVideo = _selectedVideo != null;
      final url = await _uploadToCloudinary(file, isVideo);

      if (url == null) {
        Fluttertoast.showToast(msg: "Upload failed.");

        await _notificationService.showSubmissionFailedNotification(
          issueType: widget.issueType,
        );

        setState(() => _isUploading = false);
        return;
      }

      final DatabaseReference ref =
          FirebaseDatabase.instance.ref("complaints").push();
      await ref.set({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'issue_type': widget.issueType,
        'state': _selectedState,
        'city': _selectedCity,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'media_url': url,
        'media_type': isVideo ? 'video' : 'image',
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'Pending',
      });

      // Save notification in local storage for admin
      await LocalStatusStorage.saveAdminNotification({
        'message':
            'A new complaint (ID: ${ref.key}) has been submitted and is pending review.',
        'timestamp': DateTime.now().toIso8601String(),
        'complaint_id': ref.key,
        'status': 'Pending',
        'issue_type': widget.issueType,
      });

      await _notificationService.showComplaintSubmittedNotification(
        issueType: widget.issueType,
        complaintId: ref.key,
      );

      Fluttertoast.showToast(msg: "Submitted Successfully");
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const DoneScreen()));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Submission failed: $e");

      await _notificationService.showSubmissionFailedNotification(
        issueType: widget.issueType,
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String hint, {required bool isFilled}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isFilled ? const Color(0xFF4CAF50) : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isFilled ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      widget.headingText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.infoText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image Section
            ZoomIn(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Form Section
            FadeInUp(
              duration: const Duration(milliseconds: 1000),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Section Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4CAF50).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Color(0xFF4CAF50),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Location Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // State Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      hint: const Text("Select the Wizarding Region"),
                      items: _states.keys
                          .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedState = value;
                        _selectedCity = null;
                      }),
                      decoration: _inputDecoration("State", isFilled: _selectedState != null),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // City Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      hint: const Text("Select the Nearest Magical District"),
                      items: _selectedState != null
                          ? _states[_selectedState]!
                              .map((city) =>
                                  DropdownMenuItem(value: city, child: Text(city)))
                              .toList()
                          : [],
                      onChanged: (value) => setState(() => _selectedCity = value),
                      decoration: _inputDecoration("City", isFilled: _selectedCity != null),
                      dropdownColor: Colors.white,
                      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    // Location Input
                    TextField(
                      controller: _locationController,
                      style: const TextStyle(fontSize: 16),
                      decoration: _inputDecoration("Reveal the Secret Location",
                              isFilled: _locationController.text.trim().isNotEmpty)
                          .copyWith(
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.my_location, color: Colors.white),
                            onPressed: _getCurrentLocation,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Description Section Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9C27B0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Color(0xFF9C27B0),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Description Input
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: 250,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                      decoration: _inputDecoration(
                              "Describe the Strange Occurence or Speak a spell",
                              isFilled: _descriptionController.text.trim().isNotEmpty)
                          .copyWith(
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.red : const Color(0xFF9C27B0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                            ),
                            onPressed: _isListening ? _stopListening : _startListening,
                          ),
                        ),
                      ),
                    ),
                    
                    // Character counter
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _remainingCharacters <= 0
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${_remainingCharacters.clamp(0, 250)} characters remaining",
                              style: TextStyle(
                                fontSize: 12,
                                color: _remainingCharacters <= 0
                                    ? Colors.red
                                    : Colors.grey[600],
                                fontWeight: _remainingCharacters <= 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Media Section Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.photo_camera,
                            color: Color(0xFFFF9800),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Upload Media",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Upload Image button
                    _buildUploadButton(
                      "Reveal a Magical Proof 📷",
                      Icons.image,
                      _selectedImage != null,
                      _pickImage,
                      const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 16),

                    // Show selected image preview
                    if (_selectedImage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.black87,
                                  builder: (_) => GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.black,
                                      alignment: Alignment.center,
                                      child: InteractiveViewer(
                                        child: Image.file(
                                          _selectedImage!,
                                          width: MediaQuery.of(context).size.width,
                                          height: MediaQuery.of(context).size.height,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _selectedImage!,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _confirmMediaRemoval(isVideo: false),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Centered "or" text with dividers
                    Row(
                      children: [
                        Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "or",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                        Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Upload Video button
                    _buildUploadButton(
                      "Upload Video (max 10s)",
                      Icons.videocam,
                      _selectedVideo != null,
                      _pickVideo,
                      const Color(0xFF2196F3),
                    ),
                    const SizedBox(height: 16),

                    // Show selected video preview
                    if (_videoController != null && _videoController!.value.isInitialized)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                height: 200,
                                width: double.infinity,
                                child: AspectRatio(
                                  aspectRatio: _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                            ),
                            // Play/Pause Button
                            Positioned.fill(
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      });
                                    },
                                    child: Icon(
                                      _videoController!.value.isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Close Button
                            Positioned(
                              top: 12,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _confirmMediaRemoval(isVideo: true),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            FadeInUp(
              duration: const Duration(milliseconds: 1200),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _canSubmit && !_isUploading
                      ? const LinearGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: !_canSubmit || _isUploading ? Colors.grey[400] : null,
                  boxShadow: _canSubmit && !_isUploading
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1A1A1A).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: ElevatedButton(
                  onPressed: (!_canSubmit || _isUploading) ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isUploading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "Sending...",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "Send via Owl Post",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(
    String label,
    IconData icon,
    bool filled,
    VoidCallback onTap,
    Color color,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: filled ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: filled ? color : Colors.grey[300]!,
            width: filled ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: filled ? color : Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              filled ? "Change" : label,
              style: TextStyle(
                color: filled ? color : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}