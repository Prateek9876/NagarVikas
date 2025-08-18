import 'dart:io';
import 'package:nagarvikas/service/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../screen/done_screen.dart';
import '../service/local_status_storage.dart';
import '../theme/theme_provider.dart';

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
      setState(() {});
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
      await openAppSettings();
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
        title: Text("Remove ${isVideo ? 'video' : 'image'}?"),
        content:
        Text("Do you want to remove the ${isVideo ? 'video' : 'image'}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
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
            child: const Text("Yes"),
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

      // Get current user's name for admin notification
      final currentUser = FirebaseAuth.instance.currentUser;
      String userName = 'Unknown User';
      if (currentUser != null) {
        final userSnapshot = await FirebaseDatabase.instance
            .ref('users/${currentUser.uid}')
            .get();
        if (userSnapshot.exists) {
          final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
          userName = userData['name'] ?? 'Unknown User';
        }
      }

      // Save notification in local storage for admin
      await LocalStatusStorage.saveAdminNotification({
        'message':
        'New ${widget.issueType} complaint submitted by $userName from $_selectedCity, $_selectedState and is pending review.',
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

  InputDecoration _inputDecoration(String hint,
      {required bool isFilled, required ThemeProvider themeProvider}) =>
      InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: themeProvider.isDarkMode
            ? Colors.grey[800]
            : const Color.fromARGB(255, 251, 250, 250),
        hintStyle: TextStyle(
          color: themeProvider.isDarkMode ? Colors.white70 : null,
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isFilled ? Colors.grey[400]! : Colors.red, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
          BorderSide(color: isFilled ? Colors.blue : Colors.red, width: 2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 360;

    // Responsive padding and sizing
    final horizontalPadding = isVerySmallScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
    final cardPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 24.0);
    final iconSize = isVerySmallScreen ? 24.0 : 28.0;
    final headerImageHeight = isVerySmallScreen ? 140.0 : (isSmallScreen ? 160.0 : 200.0);
    final videoHeight = isVerySmallScreen ? 120.0 : (isSmallScreen ? 140.0 : 180.0);
    final imagePreviewHeight = isVerySmallScreen ? 120.0 : (isSmallScreen ? 140.0 : 160.0);

    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: themeProvider.isDarkMode
                ? [
              Colors.grey[900]!,
              Colors.grey[850]!,
            ]
                : [
              const Color(0xFFF8F9FA),
              const Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(horizontalPadding),
          child: Column(
            children: [
              // Header Section
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header row with responsive layout
                      isVerySmallScreen
                          ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.report_problem,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                widget.headingText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isVerySmallScreen ? 16 : 18,
                                  color: themeProvider.isDarkMode
                                      ? Colors.white
                                      : Colors.black87,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.infoText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[300]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF42A5F5).withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.report_problem,
                              size: iconSize,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.headingText,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSmallScreen ? 18 : 20,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.infoText,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 13 : 14,
                                    color: themeProvider.isDarkMode
                                        ? Colors.grey[300]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 16 : 20),
                      ZoomIn(
                        child: Container(
                          height: 180, // Add height constraint to reduce image size
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.asset(
                              widget.imageAsset,
                              fit: BoxFit.scaleDown,
                              // Scales down if too large, but shows full image
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 180, // Match the container height
                                  width: double.infinity,
                                  color: Colors.grey[100],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey,
                                    size: 48,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 16 : 24),

              // Location Section
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Color(0xFF4CAF50),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Location Details",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 16 : 20),

                      // State Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _selectedState != null
                                ? const Color(0xFF42A5F5)
                                : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                            width: _selectedState != null ? 2 : 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedState,
                          hint: Text(
                            isVerySmallScreen ? "Select Region" : "Select the Wizarding Region",
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 13 : 14,
                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          items: _states.keys
                              .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(
                                s,
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 13 : 14,
                                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )))
                              .toList(),
                          onChanged: (value) => setState(() {
                            _selectedState = value;
                            _selectedCity = null;
                          }),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 12 : 16,
                              vertical: isVerySmallScreen ? 12 : 16,
                            ),
                            prefixIcon: Icon(
                              Icons.map,
                              color: _selectedState != null
                                  ? const Color(0xFF42A5F5)
                                  : (themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                            ),
                          ),
                          dropdownColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      // City Dropdown
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _selectedCity != null
                                ? const Color(0xFF42A5F5)
                                : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                            width: _selectedCity != null ? 2 : 1,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedCity,
                          hint: Text(
                            isVerySmallScreen ? "Select District" : "Select the Nearest Magical District",
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 13 : 14,
                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                          items: _selectedState != null
                              ? _states[_selectedState]!
                              .map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(
                                city,
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 13 : 14,
                                  color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )))
                              .toList()
                              : [],
                          onChanged: (value) => setState(() => _selectedCity = value),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 12 : 16,
                              vertical: isVerySmallScreen ? 12 : 16,
                            ),
                            prefixIcon: Icon(
                              Icons.location_city,
                              color: _selectedCity != null
                                  ? const Color(0xFF42A5F5)
                                  : (themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                            ),
                          ),
                          dropdownColor: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
                          isExpanded: true,
                        ),
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      // Location Input
                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _locationController.text.trim().isNotEmpty
                                ? const Color(0xFF42A5F5)
                                : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                            width: _locationController.text.trim().isNotEmpty ? 2 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _locationController,
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 13 : 14,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: isVerySmallScreen ? "Secret Location" : "Reveal the Secret Location",
                            labelStyle: TextStyle(
                              fontSize: isVerySmallScreen ? 13 : 14,
                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 12 : 16,
                              vertical: isVerySmallScreen ? 12 : 16,
                            ),
                            prefixIcon: Icon(
                              Icons.place,
                              color: _locationController.text.trim().isNotEmpty
                                  ? const Color(0xFF42A5F5)
                                  : (themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                            ),
                            suffixIcon: Container(
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF42A5F5).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.my_location, color: Color(0xFF42A5F5)),
                                onPressed: _getCurrentLocation,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 16 : 24),

              // Description Section
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.description,
                              color: Color(0xFFFF9800),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isVerySmallScreen ? "Description" : "Incident Description",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 16 : 20),

                      Container(
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[700]!.withOpacity(0.3)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _descriptionController.text.trim().isNotEmpty
                                ? const Color(0xFF42A5F5)
                                : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
                            width: _descriptionController.text.trim().isNotEmpty ? 2 : 1,
                          ),
                        ),
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: isVerySmallScreen ? 2 : 3,
                          maxLength: 250,
                          buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                          style: TextStyle(
                            fontSize: isVerySmallScreen ? 13 : 14,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          decoration: InputDecoration(
                            labelText: isVerySmallScreen
                                ? "Describe the Occurrence"
                                : "Describe the Strange Occurence or Speak a spell",
                            labelStyle: TextStyle(
                              fontSize: isVerySmallScreen ? 13 : 14,
                              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isVerySmallScreen ? 12 : 16,
                              vertical: isVerySmallScreen ? 12 : 16,
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: isVerySmallScreen ? 20 : 40),
                              child: Icon(
                                Icons.edit,
                                color: _descriptionController.text.trim().isNotEmpty
                                    ? const Color(0xFF42A5F5)
                                    : (themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[400]),
                              ),
                            ),
                            suffixIcon: Padding(
                              padding: EdgeInsets.only(bottom: isVerySmallScreen ? 20 : 40),
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isListening
                                      ? const Color(0xFFf44336).withOpacity(0.1)
                                      : const Color(0xFF42A5F5).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    _isListening ? Icons.mic : Icons.mic_none,
                                    color: _isListening ? const Color(0xFFf44336) : const Color(0xFF42A5F5),
                                  ),
                                  onPressed: _isListening ? _stopListening : _startListening,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "${_remainingCharacters.clamp(0, 250)} characters remaining",
                            style: TextStyle(
                              fontSize: isVerySmallScreen ? 11 : 12,
                              color: _remainingCharacters <= 0
                                  ? const Color(0xFFf44336)
                                  : (themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              fontWeight: _remainingCharacters <= 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isVerySmallScreen ? 16 : 24),

              // Media Upload Section
              FadeInUp(
                duration: const Duration(milliseconds: 1200),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 16 : 20),
                    boxShadow: [
                      BoxShadow(
                        color: (themeProvider.isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE91E63).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.cloud_upload,
                              color: Color(0xFFE91E63),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              isVerySmallScreen ? "Evidence" : "Upload Evidence",
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 16 : 20),

                      // Upload Image button
                      _buildModernUploadButton(
                        isVerySmallScreen ? "Upload Image 📷" : "Reveal a Magical Proof 📷",
                        Icons.image,
                        _selectedImage != null,
                        _pickImage,
                        themeProvider,
                        const Color(0xFF2196F3),
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      // Show selected image preview
                      if (_selectedImage != null)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight: imagePreviewHeight,
                                    maxWidth: double.infinity,
                                  ),
                                  child: Image.file(
                                    _selectedImage!,
                                    height: imagePreviewHeight,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _confirmMediaRemoval(isVideo: false),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.close, color: Color(0xFFf44336), size: 16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (_selectedImage != null) SizedBox(height: isVerySmallScreen ? 12 : 16),

                      // Centered "or" text with dividers
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              "or",
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w500,
                                color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      // Upload Video button
                      _buildModernUploadButton(
                        isVerySmallScreen ? "Upload Video" : "Upload Video (max 10s)",
                        Icons.videocam,
                        _selectedVideo != null,
                        _pickVideo,
                        themeProvider,
                        const Color(0xFFFF9800),
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      if (_videoController != null && _videoController!.value.isInitialized)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              SizedBox(
                                height: videoHeight,
                                width: double.infinity,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
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
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                                        color: Colors.white,
                                        size: isVerySmallScreen ? 30 : 40,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _videoController!.value.isPlaying
                                              ? _videoController!.pause()
                                              : _videoController!.play();
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),

                              // Close Button
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _confirmMediaRemoval(isVideo: true),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.close, color: Color(0xFFf44336), size: 16),
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
              SizedBox(height: isVerySmallScreen ? 24 : 30),

              // Submit Button
              FadeInUp(
                duration: const Duration(milliseconds: 1400),
                child: Container(
                  width: double.infinity,
                  height: isVerySmallScreen ? 48 : 56,
                  decoration: BoxDecoration(
                    gradient: !_canSubmit
                        ? LinearGradient(
                      colors: [Colors.grey[400]!, Colors.grey[500]!],
                    )
                        : const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF42A5F5), Color(0xFF1565C0)],
                    ),
                    borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : 16),
                    boxShadow: !_canSubmit
                        ? []
                        : [
                      BoxShadow(
                        color: const Color(0xFF42A5F5).withOpacity(0.3),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(isVerySmallScreen ? 12 : 16),
                      onTap: (!_canSubmit || _isUploading) ? null : _submitForm,
                      child: Center(
                        child: _isUploading
                            ? CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: isVerySmallScreen ? 1.5 : 2,
                        )
                            : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.send,
                              color: Colors.white,
                              size: isVerySmallScreen ? 18 : 20,
                            ),
                            SizedBox(width: isVerySmallScreen ? 6 : 8),
                            Flexible(
                              child: Text(
                                isVerySmallScreen ? "Send" : "Send via Owl Post",
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom padding for safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      );
    });
  }


  Widget _buildModernUploadButton(String text, IconData icon, bool isSelected, VoidCallback onPressed, ThemeProvider themeProvider, Color accentColor) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withOpacity(0.1)
            : (themeProvider.isDarkMode ? Colors.grey[700]!.withOpacity(0.3) : Colors.grey[50]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isSelected
              ? accentColor
              : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[300]!),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? accentColor
                          : (themeProvider.isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: accentColor, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(
      String label, IconData icon, bool filled, VoidCallback onTap) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? Colors.black
                : const Color.fromARGB(255, 253, 253, 253),
            borderRadius: BorderRadius.circular(8),
            border: filled ? null : Border.all(color: Colors.grey),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon,
                color:
                themeProvider.isDarkMode ? Colors.white70 : Colors.black54),
            const SizedBox(width: 10),
            Text(filled ? "Change" : label,
                style: TextStyle(
                    color: themeProvider.isDarkMode
                        ? Colors.white70
                        : Colors.black54))
          ]),
        ),
      );
    });
  }
}
