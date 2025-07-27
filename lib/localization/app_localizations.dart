import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final languageCode = prefs.getString('language') ?? 'en';
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(Locale(languageCode));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
  ];
  static Future<AppLocalizations> save(Locale locale) async {
    await prefs.setString('language', locale.languageCode);
    if (!localizedValues.containsKey(locale.languageCode)) {
      return AppLocalizations(Locale('en'));
    }
    return AppLocalizations(locale);
  }

  static Future<AppLocalizations> load(Locale locale) async {
    final languageCode = prefs.getString('language') ?? 'en';
    return AppLocalizations(Locale(languageCode));
  }

  static Map<String, Map<String, String>> localizedValues = {
    'en': {
      'appTitle': 'Nagar Vikas',
      'welcome': 'Welcome',
      'about': 'About',
      'adminDashboard': 'Admin Dashboard',
      'analyticsDashboard': 'Analytics Dashboard',
      'animals': 'Animals',
      'complaintDetail': 'Complaint Detail',
      'contact': 'Contact',
      'discussion': 'Discussion',
      'done': 'Done',
      'drainage': 'Drainage',
      'facingIssues': 'Facing Issues',
      'feedback': 'Feedback',
      'forgotPassword': 'Forgot Password',
      'garbage': 'Garbage',
      'home': 'Home',
      'language': 'Language',
      'myComplaints': 'My Complaints',
      'newComplaint': 'New Complaint',
      'profile': 'Profile',
      'referAndEarn': 'Refer and Earn',
      'register': 'Register',
      'road': 'Road',
      'settings': 'Settings',
      'submit': 'Submit',
      'thankYou': 'Thank You',
      'version': 'Version',
      'water': 'Water',
      'changeLanguage': 'Change Language',
      'selectLanguage': 'Select Language',
      'complaints': 'Complaints',
      'noComplaintsYet': 'No complaints yet.',
      'descriptionHint': 'Enter complaint description',
      'addressHint': 'Enter address',
      'pincodeHint': 'Enter pincode',
      'cityHint': 'Enter city',
      'stateHint': 'Enter state',
      'nameHint': 'Enter your name',
      'emailHint': 'Enter your email',
      'passwordHint': 'Enter your password',
      'confirmPasswordHint': 'Confirm your password',
      'phoneHint': 'Enter your phone number',
      'registerButton': 'Register',
      'alreadyHaveAccount': 'Already have an account? Login',
      'registerSuccess': 'Registration Successful!',
      'registerFailed': 'Registration Failed',
      'passwordMismatch': 'Passwords do not match.',
      'enterAllFields': 'Please enter all fields.',
      'welcomeToAdminDashboard': 'Welcome to Admin Dashboard',
      'complaintId': 'Complaint ID',
      'noComplaintData': 'No Complaint Data',
      'fetchingDetails': 'Fetching Complaint Details...',
      'updateStatusSuccess': 'Complaint status updated successfully!',
      'updateStatusFailed': 'Failed to update complaint status.',
      'errorUpdatingStatus': 'Error updating status:',
      'location': '📍 Location',
      'cityTitle': '🏙️ City',
      'stateTitle': '🗺️ State',
      'dateAndTime': '📅 Date and Time',
      'user': '👤 User',
      'description': '📝 Description',
      'updateStatus': '🔄 Update Status',
      'inProgress': 'In Progress',
      'delete': 'Delete',
      'confirmDeletion': 'Confirm Deletion',
      'areYouSureDeleteComplaint':
          'Are you sure you want to delete this complaint?',
      'no': 'No',
      'yes': 'Yes',
      'deletedSuccessfully': 'Deleted Successfully!',
      'aboutApp': 'About the App',
      'aboutDescription':
          'Nagar Vikas is an initiative to bring transparency and efficiency to urban complaint management. Our goal is to empower citizens to report issues effortlessly and track their resolution in real-time, fostering a more responsive and accountable local administration.',
      'versionInfo': 'Version 1.0.0',
      'contactInfo': 'Contact Information',
      'contactEmail': 'Email: support@nagarvikas.com',
      'contactPhone': 'Phone: +91-1234567890',
      'contactUsMessage':
          'For more information or assistance, feel free to reach out to us at support@nagarvikas.com. We value your feedback and are always here to help.',
      'analytics': 'Analytics',
      'logout': 'Logout',
      'confirmLogout': 'Confirm Logout',
      'areYouSureLogout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'adminPanel': 'Admin Panel',
      'searchComplaints': 'Search Complaints...',
      'noComplaintsFound': 'No complaints found.',
      'status': 'Status',
      'city': 'City',
      'state': 'State',
      'complaintsOverview': 'Complaints Overview',
      'monthlyComplaintTrends': 'Monthly Complaint Trends',
      'resolved': 'Resolved',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'total': 'Total',
      'complaintsSummary': 'Complaints Summary',
      'complaint': 'Complaint',
      'contactUsDescription':
          'If you have any questions or need assistance, feel free to contact us:',
      'couldNotLaunch': 'Could not launch ',
      'supportRequestNagarVikas': 'Support Request - Nagar Vikas',
      'emailBody': 'Hi team,\n\nI need help with ',
      'noEmailAppOrGmailAvailable': 'No email app or Gmail available.',
      'contactUs': 'Contact Us',
      'contactUsInfo':
          'If you have any questions or need assistance, feel free to contact us:',
      'hiTeamNeedHelp': 'Hi team,\n\nI need help with ',
      'discussionForum': 'Discussion Forum',
      'noMessagesYet': 'No messages yet!',
      'typeAMessage': 'Type a message...',
      'complaintRegistered': 'Complaint Registered!',
      'complaintRegisteredMessage':
          'Your complaint has been successfully registered. We will work on it soon.',
      'drainageIssue': 'Drainage Issue',
      'drainageIssueType': 'Drainage Issue',
      'drainageIssueSelected': 'Drainage issue selected',
      'doneScreenTitle': 'Done!',
      'doneScreenMessage':
          'We will get in touch with you if more information is required.',
      'doneScreenInfo':
          'Please note that the estimated time for your issue to be resolved will be 10 to 12 hours. And if you placed complaint between 12PM-8AM then resolving time will start from the next morning ie. After 8AM.\nYou can check your issue status in the My Complaints tab.',
      'commonIssues': 'Common Issues',
      'appNotOpening': 'App not opening',
      'appNotOpeningDescription':
          'If the app is not opening, try restarting your phone or reinstalling the app. Ensure you have a stable internet connection.',
      'loginIssues': 'Login issues',
      'loginIssuesDescription':
          'If you’re facing issues with logging in, make sure your internet connection is stable and you are using the correct login credentials. If you forgot your password, use the "Forgot Password" option.',
      'errorSubmittingComplaint': 'Error in submitting complaint',
      'errorSubmittingComplaintDescription':
          'If the complaint submission fails, please check your internet connection and ensure all required fields are filled. Try restarting the app and submitting again.',
      'troubleshootingSteps': 'Troubleshooting Steps',
      'step1RestartApp': 'Step 1: Restart the app',
      'step1RestartAppDescription': 'Close the app completely and reopen it.',
      'step2CheckInternet': 'Step 2: Check Internet Connection',
      'step2CheckInternetDescription':
          'Ensure you have a stable and active internet connection (Wi-Fi or mobile data).',
      'step3ClearCache': 'Step 3: Clear App Cache',
      'step3ClearCacheDescription':
          'Go to your phone settings > Apps > Nagar Vikas > Storage > Clear Cache.',
      'contactSupport': 'Contact Support',
      'contactSupportMessage':
          'If the issue persists, please contact our support team for further assistance.',
      'feedbackHint': 'Share your thoughts here...',
      'feedbackSubmitted': 'Feedback submitted successfully!',
      'submitFeedback': 'Submit Feedback',
      'garbageIssue': 'Garbage Issue',
      'garbageLiftingIssueSelected': 'Garbage lifting issue selected',
      'noUserFound': 'No user found for that email.',
      'wrongPassword': 'Wrong password provided for that user.',
      'loginFailed': 'Login Failed',
      'anErrorOccurred': 'An error occurred',
      'email': 'Email',
      'password': 'Password',
      'dontHaveAccountRegister': 'Don\'t have an account? Register',
      'pleaseLoginToViewComplaints': 'Please login to view your complaints.',
      'error': 'Error',
      'unknown': 'Unknown',
      'noDescription': 'No description provided.',
      'unknownDate': 'Unknown date',
      'issue': 'Issue',
      'date': 'Date',
      'noImageSelected': 'No image selected.',
      'pleaseSelectAnImage': 'Please select an image.',
      'pleaseFillAllFields': 'Please fill all fields.',
      'userNotLoggedIn': 'User not logged in.',
      'complaintSubmittedSuccessfully': 'Complaint submitted successfully!',
      'failedToSubmitComplaint': 'Failed to submit complaint.',
      'newEntryFor': 'New entry for',
      'uploadImageForComplaint': 'Upload image for complaint',
      'selectImage': 'Select Image',
      'descriptionOfIssue': 'Description of issue',
      'submitComplaint': 'Submit Complaint',
      'newIssue': 'New Issue',
      "enterNewIssue": "Enter new issue",
      "provideAccurateInfo":
          "Please give accurate and correct information for a faster solution.",
      "fullName": "Full Name",
      "userId": "User ID",
      "loading": "Loading...",
      "inviteFriends": "Invite Your Friends!",
      "earnRewardsDescription":
          "Earn rewards by referring your friends to NagarVikas. Share your referral code now!",
      "referralCodeCopied": "Referral code copied! Share it with your friends.",
      "shareReferralCode": "Share Referral Code",
      "roadIssue": "Road Issue",
      "roadDamageIssueSelected": "Road damage issue selected",
      "streetLightIssue": "Street Lights Issue",
      "streetLights": "Street Lights",
      "streetLightsIssueSelected": "Street Lights issue selected",
      "waterIssue": "Water Issue",
      "waterSupplyIssueSelected": "Water supply issue selected",
      "termsAgreement":
          "By using this app, you agree to the following terms:\n",
      "reportTruthfully": "• Report issues truthfully and accurately.",
      "consentNotifications":
          "• Consent to receive notifications from the app.",
      "noMisusePlatform": "• Do not misuse the platform for false complaints.",
      "dataUsedImproveServices": "• Data may be used to improve services.",
      "agreeTapAccept": "If you agree, tap **Accept** to proceed.",
      "strayAnimalsIssueTitle": "Stray Animals Issue",
      "strayAnimalsIssueType": "Stray Animals",
      "strayAnimalsHeadingText": "Stray animals issue selected",
      "selectNuisance": "Select the nuisance you wish to vanish",
      "callingMinistry": "Calling Ministry...",
      "referearn": "Refer and Earn",
      "facingissues": "Facing Issues",
      "shareapp": "Share App",
      "followus": "Follow Us",
      "offer": "offer",
      "userfeedback": "User Feedback",
      "spellRecords": "Spell Records"
    },
    'hi': {
      'appTitle': 'नगर विकास',
      'welcome': 'स्वागत है',
      'about': 'हमारे बारे में',
      'adminDashboard': 'एडमिन डैशबोर्ड',
      'analyticsDashboard': 'विश्लेषण डैशबोर्ड',
      'animals': 'जानवर',
      'complaintDetail': 'शिकायत विवरण',
      'contact': 'संपर्क करें',
      'discussion': 'चर्चा',
      'done': 'हो गया',
      'drainage': 'जल निकासी',
      'facingIssues': 'समस्याओं का सामना कर रहे हैं',
      'feedback': 'प्रतिक्रिया',
      'forgotPassword': 'पासवर्ड भूल गए',
      'garbage': 'कचरा',
      'home': 'होम',
      'language': 'भाषा',
      'myComplaints': 'मेरी शिकायतें',
      'newComplaint': 'नई शिकायत',
      'profile': 'प्रोफ़ाइल',
      'referAndEarn': 'रेफर करें और कमाएं',
      'register': 'रजिस्टर करें',
      'road': 'सड़क',
      'settings': 'सेटिंग्स',
      'submit': 'सबमिट करें',
      'thankYou': 'धन्यवाद',
      'version': 'संस्करण',
      'water': 'पानी',
      'changeLanguage': 'भाषा बदलें',
      'selectLanguage': 'भाषा चुनें',
      'complaints': 'शिकायतें',
      'noComplaintsYet': 'अभी तक कोई शिकायत नहीं है।',
      'descriptionHint': 'शिकायत विवरण दर्ज करें',
      'addressHint': 'पता दर्ज करें',
      'pincodeHint': 'पिनकोड दर्ज करें',
      'cityHint': 'शहर दर्ज करें',
      'stateHint': 'राज्य दर्ज करें',
      'nameHint': 'अपना नाम दर्ज करें',
      'emailHint': 'अपना ईमेल दर्ज करें',
      'passwordHint': 'अपना पासवर्ड दर्ज करें',
      'confirmPasswordHint': 'अपना पासवर्डCी पुष्टि करें',
      'phoneHint': 'अपना फ़ोन नंबर दर्ज करें',
      'registerButton': 'रजिस्टर करें',
      'alreadyHaveAccount': 'पहले से ही खाता है? लॉगिन करें',
      'registerSuccess': 'पंजीकरण सफल!',
      'registerFailed': 'पंजीकरण विफल',
      'passwordMismatch': 'पासवर्ड मेल नहीं खाते।',
      'enterAllFields': 'कृपया सभी फ़ील्ड भरें।',
      'welcomeToAdminDashboard': 'एडमिन डैशबोर्ड में आपका स्वागत है',
      'complaintId': 'शिकायत आईडी',
      'noComplaintData': 'कोई शिकायत डेटा नहीं',
      'fetchingDetails': 'शिकायत विवरण प्राप्त कर रहा है...',
      'updateStatusSuccess': 'शिकायत स्थिति सफलतापूर्वक अपडेट की गई!',
      'updateStatusFailed': 'शिकायत स्थिति अपडेट करने में विफल।',
      'errorUpdatingStatus': 'स्थिति अपडेट करने में त्रुटि:',
      'location': '📍 स्थान',
      'cityTitle': '🏙️ शहर',
      'stateTitle': '🗺️ राज्य',
      'dateAndTime': '📅 दिनांक और समय',
      'user': '👤 उपयोगकर्ता',
      'description': '📝 विवरण',
      'updateStatus': '🔄 स्थिति अपडेट करें',
      'inProgress': 'प्रगति में',
      'delete': 'मिटाना',
      'confirmDeletion': 'हटाने की पुष्टि करें',
      'areYouSureDeleteComplaint': 'क्या आप वाकई इस शिकायत को हटाना चाहते हैं?',
      'no': 'नहीं',
      'yes': 'हाँ',
      'deletedSuccessfully': 'सफलतापूर्वक हटा दिया गया!',
      'aboutApp': 'ऐप के बारे में',
      'aboutDescription':
          'नगर विकास शहरी शिकायत प्रबंधन में पारदर्शिता और दक्षता लाने की एक पहल है। हमारा लक्ष्य नागरिकों को आसानी से मुद्दों की रिपोर्ट करने और वास्तविक समय में उनके समाधान को ट्रैक करने के लिए सशक्त बनाना है, जिससे एक अधिक प्रतिक्रियाशील और जवाबदेह स्थानीय प्रशासन को बढ़ावा मिले।',
      'versionInfo': 'संस्करण 1.0.0',
      'contactInfo': 'संपर्क जानकारी',
      'contactEmail': 'ईमेल: support@nagarvikas.com',
      'contactPhone': 'फ़ोन: +91-1234567890',
      'contactUsMessage':
          'अधिक जानकारी या सहायता के लिए, support@nagarvikas.com पर हमसे संपर्क करने में संकोच न करें। हम आपकी प्रतिक्रिया को महत्व देते हैं और हमेशा मदद के लिए यहां हैं।',
      'analytics': 'विश्लेषण',
      'logout': 'लॉगआउट',
      'confirmLogout': 'लॉगआउट की पुष्टि करें',
      'areYouSureLogout': 'क्या आप वाकई लॉगआउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'adminPanel': 'एडमिन पैनल',
      'searchComplaints': 'शिकायतों में खोजें...',
      'noComplaintsFound': 'कोई शिकायत नहीं मिली।',
      'status': 'स्थिति',
      'city': 'शहर',
      'state': 'राज्य',
      'complaintsOverview': 'शिकायतों का अवलोकन',
      'monthlyComplaintTrends': 'मासिक शिकायत रुझान',
      'resolved': 'हल की गई',
      'pending': 'लंबित',
      'rejected': 'खारिज की गई',
      'total': 'कुल',
      'complaintsSummary': 'शिकायतों का सारांश',
      'complaint': 'शिकायत',
      'contactUsDescription':
          'यदि आपके कोई प्रश्न हैं या सहायता की आवश्यकता है, तो बेझिझक हमसे संपर्क करें:',
      'couldNotLaunch': 'लॉन्च नहीं किया जा सका ',
      'supportRequestNagarVikas': 'सहायता अनुरोध - नगर विकास',
      'emailBody': 'नमस्ते टीम,\n\nमुझे इसमें सहायता चाहिए ',
      'noEmailAppOrGmailAvailable': 'कोई ईमेल ऐप या जीमेल उपलब्ध नहीं है।',
      'contactUs': 'हमसे संपर्क करें',
      'contactUsInfo':
          'यदि आपके कोई प्रश्न हैं या सहायता की आवश्यकता है, तो बेझिझक हमसे संपर्क करें:',
      'hiTeamNeedHelp': 'नमस्ते टीम,\n\nमुझे इसमें सहायता चाहिए ',
      'discussionForum': 'चर्चा मंच',
      'noMessagesYet': 'अभी कोई संदेश नहीं है!',
      'typeAMessage': 'एक संदेश लिखें...',
      'complaintRegistered': 'शिकायत दर्ज की गई!',
      'complaintRegisteredMessage':
          'आपकी शिकायत सफलतापूर्वक दर्ज कर ली गई है। हम इस पर जल्द ही काम करेंगे।',
      'drainageIssue': 'जल निकासी समस्या',
      'drainageIssueType': 'जल निकासी समस्या',
      'drainageIssueSelected': 'जल निकासी समस्या चयनित',
      'doneScreenTitle': 'हो गया!',
      'doneScreenMessage':
          'यदि अधिक जानकारी की आवश्यकता होगी तो हम आपसे संपर्क करेंगे।',
      'doneScreenInfo':
          'कृपया ध्यान दें कि आपके मुद्दे को हल करने का अनुमानित समय 10 से 12 घंटे होगा। और यदि आपने दोपहर 12 बजे से सुबह 8 बजे के बीच शिकायत दर्ज की है तो समाधान का समय अगली सुबह यानी सुबह 8 बजे के बाद से शुरू होगा।\nआप अपनी शिकायत की स्थिति "मेरी शिकायतें" टैब में देख सकते हैं।',
      'commonIssues': 'सामान्य मुद्दे',
      'appNotOpening': 'ऐप नहीं खुल रहा है',
      'appNotOpeningDescription':
          'यदि ऐप नहीं खुल रहा है, तो अपने फोन को पुनरारंभ करने या ऐप को फिर से इंस्टॉल करने का प्रयास करें। सुनिश्चित करें कि आपके पास एक स्थिर इंटरनेट कनेक्शन है।',
      'loginIssues': 'लॉगिन समस्याएँ',
      'loginIssuesDescription':
          'यदि आपको लॉग इन करने में समस्या आ रही है, तो सुनिश्चित करें कि आपका इंटरनेट कनेक्शन स्थिर है और आप सही लॉगिन क्रेडेंशियल का उपयोग कर रहे हैं। यदि आप अपना पासवर्ड भूल गए हैं, तो "पासवर्ड भूल गए" विकल्प का उपयोग करें।',
      'errorSubmittingComplaint': 'शिकायत सबमिट करने में त्रुटि',
      'errorSubmittingComplaintDescription':
          'यदि शिकायत सबमिशन विफल रहता है, तो कृपया अपना इंटरनेट कनेक्शन जांचें और सुनिश्चित करें कि सभी आवश्यक फ़ील्ड भरे गए हैं। ऐप को पुनरारंभ करने और फिर से सबमिट करने का प्रयास करें।',
      'troubleshootingSteps': 'समस्या निवारण चरण',
      'step1RestartApp': 'चरण 1: ऐप को पुनरारंभ करें',
      'step1RestartAppDescription':
          'ऐप को पूरी तरह बंद करें और इसे फिर से खोलें।',
      'step2CheckInternet': 'चरण 2: इंटरनेट कनेक्शन जांचें',
      'step2CheckInternetDescription':
          'सुनिश्चित करें कि आपके पास एक स्थिर और सक्रिय इंटरनेट कनेक्शन (वाई-फाई या मोबाइल डेटा) है।',
      'step3ClearCache': 'चरण 3: ऐप कैश साफ़ करें',
      'step3ClearCacheDescription':
          'अपने फ़ोन सेटिंग्स> ऐप्स> नगर विकास> स्टोरेज> कैश साफ़ करें पर जाएं।',
      'contactSupport': 'सहायता से संपर्क करें',
      'contactSupportMessage':
          'यदि समस्या बनी रहती है, तो कृपया आगे की सहायता के लिए हमारी सहायता टीम से संपर्क करें।',
      'feedbackHint': 'अपने विचार यहाँ साझा करें...',
      'feedbackSubmitted': 'प्रतिक्रिया सफलतापूर्वक सबमिट की गई!',
      'submitFeedback': 'प्रतिक्रिया जमा करें',
      'garbageIssue': 'कचरा समस्या',
      'garbageLiftingIssueSelected': 'कचरा उठाने की समस्या चयनित',
      'noUserFound': 'उस ईमेल के लिए कोई उपयोगकर्ता नहीं मिला।',
      'wrongPassword': 'उस उपयोगकर्ता के लिए गलत पासवर्ड प्रदान किया गया।',
      'loginFailed': 'लॉगिन विफल',
      'anErrorOccurred': 'एक त्रुटि हुई',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'dontHaveAccountRegister': 'खाता नहीं है? रजिस्टर करें',
      'pleaseLoginToViewComplaints':
          'अपनी शिकायतें देखने के लिए कृपया लॉगिन करें।',
      'error': 'त्रुटि',
      'unknown': 'अज्ञात',
      'noDescription': 'कोई विवरण प्रदान नहीं किया गया।',
      'unknownDate': 'अज्ञात तिथि',
      'issue': 'मुद्दा',
      'date': 'दिनांक',
      'noImageSelected': 'कोई छवि नहीं चुनी गई।',
      'pleaseSelectAnImage': 'कृपया एक छवि चुनें।',
      'pleaseFillAllFields': 'कृपया सभी फ़ील्ड भरें।',
      'userNotLoggedIn': 'उपयोगकर्ता लॉग इन नहीं है।',
      'complaintSubmittedSuccessfully': 'शिकायत सफलतापूर्वक सबमिट की गई!',
      'failedToSubmitComplaint': 'शिकायत सबमिट करने में विफल।',
      'newEntryFor': 'के लिए नई प्रविष्टि',
      'uploadImageForComplaint': 'शिकायत के लिए छवि अपलोड करें',
      'selectImage': 'छवि चुनें',
      'descriptionOfIssue': 'समस्या का विवरण',
      'submitComplaint': 'शिकायत सबमिट करें',
      'newIssue': 'नई समस्या',
      "enterNewIssue": "नई समस्या दर्ज करें",
      "provideAccurateInfo":
          "कृपया तेज़ समाधान के लिए सटीक और सही जानकारी प्रदान करें।",
      "fullName": "पूरा नाम",
      "userId": "उपयोगकर्ता आईडी",
      "loading": "लोड हो रहा है...",
      "inviteFriends": "अपने दोस्तों को आमंत्रित करें!",
      "earnRewardsDescription":
          "अपने दोस्तों को नगर विकास में रेफर करें और पुरस्कार कमाएँ! अभी अपना रेफरल कोड साझा करें!",
      "referralCodeCopied":
          "रेफरल कोड कॉपी हो गया! इसे अपने दोस्तों के साथ साझा करें.",
      "shareReferralCode": "रेफरल कोड साझा करें",
      "roadIssue": "सड़क समस्या",
      "roadDamageIssueSelected": "सड़क क्षति समस्या चयनित",
      "streetLightIssue": "स्ट्रीट लाइट समस्या",
      "streetLights": "स्ट्रीट लाइट्स",
      "streetLightsIssueSelected": "स्ट्रीट लाइट्स समस्या चयनित",
      "waterIssue": "पानी की समस्या",
      "waterSupplyIssueSelected": "पानी की आपूर्ति समस्या चयनित",
      "termsAgreement":
          "इस ऐप का उपयोग करके, आप निम्नलिखित शर्तों से सहमत हैं:\n",
      "reportTruthfully": "• मुद्दों की सच्चाई और सटीकता से रिपोर्ट करें।",
      "consentNotifications": "• ऐप से सूचनाएं प्राप्त करने के लिए सहमति दें।",
      "noMisusePlatform":
          "• झूठी शिकायतों के लिए प्लेटफ़ॉर्म का दुरुपयोग न करें।",
      "dataUsedImproveServices":
          "• डेटा का उपयोग सेवाओं को बेहतर बनाने के लिए किया जा सकता है।",
      "agreeTapAccept":
          "यदि आप सहमत हैं, तो आगे बढ़ने के लिए **स्वीकार करें** पर टैप करें।",
      "strayAnimalsIssueTitle": "आवारा पशु समस्या",
      "strayAnimalsIssueType": "आवारा पशु",
      "strayAnimalsHeadingText": "आवारा पशु समस्या चयनित",
      "selectNuisance": "आप जिस परेशानी को समाप्त करना चाहते हैं उसे चुनें",
      "callingMinistry": "मंत्रालय को कॉल कर रहे हैं...",
      "referearn": "रेफर और कमाएं",
      "facingissues": "सामना कर रहे मुद्दे",
      "shareapp": "ऐप साझा करें",
      "followus": "हमारा अनुसरण करें",
      "offer": "ऑफ़र",
      "userfeedback": "उपयोगकर्ता प्रतिक्रिया",
      "spellRecords": "स्पेल रिकॉर्ड्स"
    },
  };

  String get(String key) {
    return localizedValues[locale.languageCode]?[key] ??
        localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
