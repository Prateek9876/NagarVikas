import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:NagarVikas/screen/done_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:dio/dio.dart';
import 'package:animate_do/animate_do.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key});

  @override
  _NewEntryPageState createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  String? _selectedState;
  String? _selectedCity;
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;
  stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

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
    _requestPermissions();
  }

  void _requestPermissions() async {
    var status = await Permission.microphone.request();
    if (status.isDenied) {
      Fluttertoast.showToast(
          msg: "Microphone permission is required for voice input.");
    }
  }

  // Function to Start Listening
  void _startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);

      _speech.listen(
        onResult: (result) {
          setState(() {
            _descriptionController.text = result.recognizedWords;
          });
        },
      );
    }
  }

  // Function to Stop Listening
  void _stopListening() {
    _speech.stop();
    setState(() => _isListening = false);
  }

  // Pick Image from Gallery
  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: "Please enable location services.");
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: "Location permissions are denied.");
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg: "Location permissions are permanently denied.");
      return;
    }
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      String address =
          "${place.subLocality}, ${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}, ${place.isoCountryCode}";

      setState(() {
        _locationController.text = address;
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed to get address.");
      setState(() {
        _locationController.text =
            "${position.latitude}, ${position.longitude}";
      });
    }
  }

  // Upload Image to Cloudinary
  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    String cloudName = "dved2q851";
    String uploadPreset = "flutter_uploads";
    String cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload";

    

    FormData formData = FormData.fromMap({
      "file": await MultipartFile.fromFile(imageFile.path),
      "upload_preset": uploadPreset,
    });

    try {
      Response response = await Dio().post(cloudinaryUrl, data: formData);
      return response.data["secure_url"];
    } catch (e) {
      return null;
    }
  }




  //added
    Future<String?> _predictIssueFromImage(String imageUrl) async {      //new
  const String apiUrl = "https://api-inference.huggingface.co/models/google/vit-base-patch16-224";
  const String token = "Bearer ${dotenv.env['HUGGINGFACE_API_KEY']}";

  
  try {
    final response = await Dio().post(
      apiUrl,
      options: Options(
        headers: {"Authorization": token},
      ),
      data: {"inputs": imageUrl},
    );

    final predictions = response.data as List;
    print("Predicted Label from HuggingFace: $predictions"); //   THIS LINE to print to image label
    if (predictions.isNotEmpty && predictions[0]['label'] != null) {
      return predictions[0]['label'];
    } else {
      return "New Issue";
    }
  } catch (e) {
    print("Prediction error: $e");
    return "New Issue";
  }
}

<<<<<<< HEAD

=======
>>>>>>> eacc589 (Add AI-based image validation in new_entry.dart)
  // Submit Form & Upload Data to Firebase
  Future<void> _submitForm() async {
    if (_selectedImage == null) {
      Fluttertoast.showToast(msg: "Please upload an image.");
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      String? predictedLabel = await _predictIssueFromImage(imageUrl!);   //new

      if (imageUrl == null) {
        throw Exception("Image upload failed.");
      }

       // Check if prediction is a civic issue
    List<String> validLabels = [
      "streetlight", "pothole", "garbage", "trash", "road", "manhole"
    ];
    if (!validLabels.contains(predictedLabel?.toLowerCase())) {
      Fluttertoast.showToast(
        msg: "The uploaded image doesn't seem to be related to a civic issue. Please upload a relevant image.",
      );
      setState(() => _isUploading = false);
      return;
    }

      DatabaseReference complaintsRef =
          FirebaseDatabase.instance.ref("complaints");
      await complaintsRef.push().set({
        'user_id': FirebaseAuth.instance.currentUser?.uid,
        'issue_type':  predictedLabel ?? "New Issue",    //new
        'state': _selectedState,
        'city': _selectedCity,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'image_url': imageUrl,
        'timestamp': DateTime.now().toIso8601String(),
        'status': "Pending",
      });

      Fluttertoast.showToast(msg: "Complaint submitted successfully!");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => DoneScreen()));
    } catch (e) {
      Fluttertoast.showToast(msg: "Error submitting complaint.");
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          duration: Duration(milliseconds: 1000),
          child: const Text(
            "Enter new issue",
            style: TextStyle(
                color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Please give accurate and correct information for a faster solution.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            ZoomIn(
              duration: const Duration(milliseconds: 1200),
              child:
                  Image.asset("assets/selected.png", height: 210, width: 210),
            ),
            SizedBox(height: 10),

            // State Dropdown
            DropdownButtonFormField<String>(
              value: _selectedState,
              hint: Text("Select State"),
              items: _states.keys.map((state) {
                return DropdownMenuItem(value: state, child: Text(state));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedState = value;
                  _selectedCity = null;
                });
              },
              decoration: _inputDecoration(),
            ),
            SizedBox(height: 10),

            // City Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCity,
              hint: Text("Select City"),
              items: _selectedState != null
                  ? _states[_selectedState]!.map((city) {
                      return DropdownMenuItem(value: city, child: Text(city));
                    }).toList()
                  : [],
              onChanged: (value) {
                setState(() {
                  _selectedCity = value;
                });
              },
              decoration: _inputDecoration(),
            ),
            SizedBox(height: 10),

            TextField(
              controller: _locationController,
              decoration: _inputDecoration().copyWith(
                hintText: "Enter location manually or click icon",
                suffixIcon: IconButton(
                  icon: Icon(Icons.my_location, color: const Color.fromARGB(255, 5, 5, 5)),
                  onPressed: _getCurrentLocation,
                ),
              ),
            ),

            SizedBox(height: 10),

            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: _inputDecoration().copyWith(
                hintText: "Enter description with contact number or speak",
                suffixIcon: IconButton(
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none,
                      color: const Color.fromARGB(255, 8, 8, 8)),
                  onPressed: _isListening ? _stopListening : _startListening,
                ),
              ),
            ),

            SizedBox(height: 10),

            GestureDetector(
              onTap: _pickImage,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: _selectedImage == null
                      ? Border.all(color: Colors.red, width: 2)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: Colors.black54),
                    SizedBox(width: 10),
                    Text(
                      _selectedImage == null ? "Upload Image" : "Change Image",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            // Show Selected Image Preview
            if (_selectedImage != null)
              Padding(
                padding: EdgeInsets.only(top: 10),
                child: Image.file(_selectedImage!, height: 100),
              ),

            SizedBox(height: 10),
            // Submit Button
           FadeInUp(
              duration: const Duration(milliseconds: 1400),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isUploading ? Colors.grey : (_selectedImage == null ? Colors.grey : Colors.black),
                  padding: EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _selectedImage == null || _isUploading ? null : () async {
                  _submitForm();
                },
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                      : Text("Submit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Decoration
  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );
  }
}
