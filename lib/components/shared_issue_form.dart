// lib/widgets/shared_issue_form.dart

import 'dart:io';
import 'package:NagarVikas/components/image_compression_util.dart';
import 'package:NagarVikas/service/notification_service.dart';
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

    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Compressing image..."),
              ],
            ),
          ),
        );

        final originalFile = File(pickedFile.path);
        final compressedFile = await ImageCompressionUtil.compressImage(
          originalFile,
          quality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
          maxFileSizeKB: 500,
        );

        Navigator.of(context).pop();

        if (compressedFile != null) {
          final imageInfo =
              await ImageCompressionUtil.getImageInfo(compressedFile);
          final fileSizeKB =
              imageInfo['fileSizeKB']?.toStringAsFixed(1) ?? 'Unknown';

          setState(() {
            _selectedImage = compressedFile;
          });

          Fluttertoast.showToast(
            msg: "Image compressed successfully! Size: ${fileSizeKB}KB",
            toastLength: Toast.LENGTH_LONG,
          );
        } else {
          setState(() {
            _selectedImage = originalFile;
          });

          Fluttertoast.showToast(
            msg: "Compression failed, using original image",
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      Fluttertoast.showToast(msg: "Failed to pick image: $e");
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

      await _notificationService.showComplaintSubmittedNotification(
        issueType: widget.issueType,
        complaintId: ref.key,
      );

      Fluttertoast.showToast(msg: "Submitted Successfully");

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const DoneScreen()));
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

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color.fromARGB(255, 251, 250, 250),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 1000),
              child: Text(widget.headingText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(height: 8),
            Text(widget.infoText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            ZoomIn(child: Image.asset(widget.imageAsset, height: 200)),
            const SizedBox(height: 20),

            DropdownButtonFormField<String>(
              value: _selectedState,
              hint: const Text("Select State"),
              items: _states.keys
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => setState(() {
                _selectedState = value;
                _selectedCity = null;
              }),
              decoration: _inputDecoration("State"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCity,
              hint: const Text("Select City"),
              items: _selectedState != null
                  ? _states[_selectedState]!
                      .map((city) =>
                          DropdownMenuItem(value: city, child: Text(city)))
                      .toList()
                  : [],
              onChanged: (value) => setState(() => _selectedCity = value),
              decoration: _inputDecoration("City"),
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _locationController,
              decoration:
                  _inputDecoration("Enter location manually or use icon")
                      .copyWith(
                suffixIcon: IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _getCurrentLocation),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 250,
              buildCounter: (_,
                      {required currentLength,
                      required isFocused,
                      maxLength}) =>
                  null,
              decoration:
                  _inputDecoration("Enter description or use mic").copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
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
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Upload image or video",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            // Upload Image button
            _buildUploadButton("Upload Image", Icons.image,
                _selectedImage != null, _pickImage),
            const SizedBox(height: 8),

// Show selected image preview
            if (_selectedImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_selectedImage!,
                        height: 160, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () => _confirmMediaRemoval(isVideo: false),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),

// Centered "or" text with dividers
            Row(
              children: const [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("or",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),

            const SizedBox(height: 12),

// Upload Video button
            _buildUploadButton("Upload Video (max 10s)", Icons.videocam,
                _selectedVideo != null, _pickVideo),
            const SizedBox(height: 8),

            if (_videoController != null &&
                _videoController!.value.isInitialized)
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  ),
                  // Play/Pause Button
                  Positioned.fill(
                    child: Center(
                      child: IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
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

                  // Close Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _confirmMediaRemoval(isVideo: true),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black,
                        child: Icon(Icons.close, color: Colors.red, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            FadeInUp(
              child: ElevatedButton(
                onPressed: (!_canSubmit || _isUploading) ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: !_canSubmit ? Colors.grey : Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadButton(
      String label, IconData icon, bool filled, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 253, 253, 253),
          borderRadius: BorderRadius.circular(8),
          border: filled ? null : Border.all(color: Colors.grey),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Text(filled ? "Change" : label,
              style: const TextStyle(color: Colors.black54))
        ]),
      ),
    );
  }
}
