import 'package:flutter/material.dart';

class LanguageService extends ChangeNotifier {
  static String _currentLanguage = "en";

  static final LanguageService _instance = LanguageService._internal();

  factory LanguageService() => _instance;

  LanguageService._internal();

  String get currentLanguage => _currentLanguage;

  void setLanguage(String languageCode) {
    if (_currentLanguage != languageCode) {
      _currentLanguage = languageCode;
      notifyListeners();
    }
  }

  static String getText(String key) {
    return translations[_currentLanguage]?[key] ?? key;
  }

  // 📚 Complete translation map for all screens
  static final Map<String, Map<String, String>> translations = {
    "en": {
      // Language Selection Screen
      "choose_language": "Choose Your Language",
      "hindi": "Hindi",
      "marathi": "Marathi",
      "telugu": "Telugu",
      "start_with_voice": "Start with Voice",

      // Onboarding Screen (Tell us about yourself)
      "tell_us_about_yourself": "Tell us about yourself",
      "progress": "Progress",
      "what_is_your_occupation": "What is your occupation?",
      "what_is_your_age": "What is your age?",
      "what_is_your_income": "What is your monthly income?",
      "do_you_have_dependents": "Do you have dependents?",
      "any_existing_health_conditions": "Any existing health conditions?",
      "tap_to_speak": "Tap to speak",
      "or_type_your_answer": "Or type your answer below",
      "type_here": "Type here...",
      "next": "Next",
      "previous": "Previous",
      "skip": "Skip",

      // Recommendation Screen
      "recommended_for_you": "Recommended for You",
      "based_on_your_profile": "Based on your profile",
      "pradhan_mantri_suraksha_bima": "Pradhan Mantri Suraksha Bima",
      "jeevan_jyoti_bima_yojana": "Jeevan Jyoti Bima Yojana",
      "premium": "Premium",
      "per_year": "/year",
      "key_benefits": "Key Benefits:",
      "accidental_death_coverage": "Accidental death coverage ₹2 lakh",
      "permanent_disability_coverage": "Permanent disability coverage ₹2 lakh",
      "partial_disability_coverage": "Partial disability coverage ₹1 lakh",
      "life_cover": "Life cover of ₹2 lakh",
      "renewable_every_year": "Renewable every year",
      "tax_benefits_80c": "Tax benefits under 80C",
      "why_this_policy": "Why this policy?",
      "continue": "Continue",
      "exclusions": "Exclusions",
      "self_inflicted_injuries": "Self-inflicted injuries, war, nuclear risks",

      // Consent Screen
      "please_confirm_consent": "Please Confirm Your Consent",
      "record_voice_approval": "Record your voice approval",
      "coverage": "Coverage",
      "accidental_death_disability": "Accidental Death & Disability - ₹2 Lakh",
      "tap_to_record_consent": "Tap to record consent",
      "please_say":
          "Please say: \"I, [Your Name], agree to purchase this policy with the stated terms and conditions\"",
      "submit_consent": "Submit Consent",
      "recording": "Recording...",
      "recorded": "Recorded",

      // KYC Verification Screen
      "kyc_verification": "KYC Verification",
      "upload_your_aadhar_card": "Upload your Aadhar card",
      "position_aadhar_card": "Position your Aadhar card",
      "front_side_first": "Front side first",
      "upload_aadhar_photo": "Upload Aadhar Photo",
      "automatically_captured": "Automatically captured:",
      "gps_location": "GPS Location",
      "timestamp": "Timestamp",
      "instructions": "Instructions:",
      "ensure_all_details_visible": "1. Ensure all details are clearly visible",
      "avoid_glare_shadows": "2. Avoid glare and shadows",
      "upload_both_sides": "3. Upload both front and back sides",
      "continue_upload_photo_first": "Continue (Upload photo first)",
      "verified_via_blockchain": "Verified via Blockchain",

      // Policy Success Screen
      "your_policy_is_active": "Your Policy is Active",
      "policy_successfully_issued": "Policy successfully issued",
      "policy_name": "Policy Name",
      "policy_number": "Policy Number",
      "start_date": "Start Date",
      "download_policy": "Download Policy",
      "share_policy": "Share Policy",
      "view_details": "View Details",
      "go_to_home": "Go to Home",

      // Common
      "yes": "Yes",
      "no": "No",
      "back": "Back",
      "submit": "Submit",
      "cancel": "Cancel",
      "ok": "OK",
      "error": "Error",
      "success": "Success",
      "loading": "Loading...",

      // Occupations
      "farmer": "Farmer",
      "shopkeeper": "Shopkeeper",
      "daily_wage_worker": "Daily Wage Worker",
      "government_employee": "Government Employee",
      "private_employee": "Private Employee",
      "self_employed": "Self Employed",
      "student": "Student",
      "homemaker": "Homemaker",
      "other": "Other",

      // AI Assistant
      "ai_assistant": "BimaMitra Assistant",
      "how_can_i_help": "How can I help you today?",
      "listening": "Listening...",
      "processing": "Processing your request...",
      "speak_now": "Speak now",
    },

    "hi": {
      // Language Selection Screen
      "choose_language": "अपनी भाषा चुनें",
      "hindi": "हिंदी",
      "marathi": "मराठी",
      "telugu": "తెలుగు",
      "start_with_voice": "आवाज़ से शुरू करें",

      // Onboarding Screen
      "tell_us_about_yourself": "अपने बारे में बताएं",
      "progress": "प्रगति",
      "what_is_your_occupation": "आपका पेशा क्या है?",
      "what_is_your_age": "आपकी उम्र क्या है?",
      "what_is_your_income": "आपकी मासिक आय क्या है?",
      "do_you_have_dependents": "क्या आपके आश्रित हैं?",
      "any_existing_health_conditions": "कोई मौजूदा स्वास्थ्य समस्या?",
      "tap_to_speak": "बोलने के लिए टैप करें",
      "or_type_your_answer": "या नीचे अपना उत्तर टाइप करें",
      "type_here": "यहाँ टाइप करें...",
      "next": "आगे",
      "previous": "पिछला",
      "skip": "छोड़ें",

      // Recommendation Screen
      "recommended_for_you": "आपके लिए सुझाव",
      "based_on_your_profile": "आपकी प्रोफ़ाइल के आधार पर",
      "pradhan_mantri_suraksha_bima": "प्रधानमंत्री सुरक्षा बीमा",
      "jeevan_jyoti_bima_yojana": "जीवन ज्योति बीमा योजना",
      "premium": "प्रीमियम",
      "per_year": "/वर्ष",
      "key_benefits": "मुख्य लाभ:",
      "accidental_death_coverage": "दुर्घटना मृत्यु कवरेज ₹2 लाख",
      "permanent_disability_coverage": "स्थायी विकलांगता कवरेज ₹2 लाख",
      "partial_disability_coverage": "आंशिक विकलांगता कवरेज ₹1 लाख",
      "life_cover": "₹2 लाख का जीवन बीमा",
      "renewable_every_year": "हर साल नवीनीकरण योग्य",
      "tax_benefits_80c": "80C के तहत कर लाभ",
      "why_this_policy": "यह पॉलिसी क्यों?",
      "continue": "जारी रखें",
      "exclusions": "बहिष्करण",
      "self_inflicted_injuries": "स्व-प्रेरित चोटें, युद्ध, परमाणु जोखिम",

      // Consent Screen
      "please_confirm_consent": "कृपया अपनी सहमति की पुष्टि करें",
      "record_voice_approval": "अपनी आवाज़ की स्वीकृति रिकॉर्ड करें",
      "coverage": "कवरेज",
      "accidental_death_disability": "दुर्घटना मृत्यु और विकलांगता - ₹2 लाख",
      "tap_to_record_consent": "सहमति रिकॉर्ड करने के लिए टैप करें",
      "please_say":
          "कृपया कहें: \"मैं, [आपका नाम], बताई गई शर्तों के साथ इस पॉलिसी को खरीदने के लिए सहमत हूं\"",
      "submit_consent": "सहमति जमा करें",
      "recording": "रिकॉर्डिंग...",
      "recorded": "रिकॉर्ड किया गया",

      // KYC Verification Screen
      "kyc_verification": "KYC सत्यापन",
      "upload_your_aadhar_card": "अपना आधार कार्ड अपलोड करें",
      "position_aadhar_card": "अपने आधार कार्ड को रखें",
      "front_side_first": "पहले सामने की तरफ",
      "upload_aadhar_photo": "आधार फोटो अपलोड करें",
      "automatically_captured": "स्वचालित रूप से कैप्चर:",
      "gps_location": "GPS स्थान",
      "timestamp": "समय चिह्न",
      "instructions": "निर्देश:",
      "ensure_all_details_visible":
          "1. सुनिश्चित करें कि सभी विवरण स्पष्ट रूप से दिखाई दें",
      "avoid_glare_shadows": "2. चमक और छाया से बचें",
      "upload_both_sides": "3. आगे और पीछे दोनों तरफ अपलोड करें",
      "continue_upload_photo_first": "जारी रखें (पहले फोटो अपलोड करें)",
      "verified_via_blockchain": "ब्लॉकचेन द्वारा सत्यापित",

      // Policy Success Screen
      "your_policy_is_active": "आपकी पॉलिसी सक्रिय है",
      "policy_successfully_issued": "पॉलिसी सफलतापूर्वक जारी की गई",
      "policy_name": "पॉलिसी का नाम",
      "policy_number": "पॉलिसी नंबर",
      "start_date": "शुरुआत की तारीख",
      "download_policy": "पॉलिसी डाउनलोड करें",
      "share_policy": "पॉलिसी साझा करें",
      "view_details": "विवरण देखें",
      "go_to_home": "होम पर जाएं",

      // Common
      "yes": "हाँ",
      "no": "नहीं",
      "back": "वापस",
      "submit": "जमा करें",
      "cancel": "रद्द करें",
      "ok": "ठीक है",
      "error": "त्रुटि",
      "success": "सफलता",
      "loading": "लोड हो रहा है...",

      // Occupations
      "farmer": "किसान",
      "shopkeeper": "दुकानदार",
      "daily_wage_worker": "दैनिक मजदूरी कर्मचारी",
      "government_employee": "सरकारी कर्मचारी",
      "private_employee": "निजी कर्मचारी",
      "self_employed": "स्व-रोजगार",
      "student": "छात्र",
      "homemaker": "गृहिणी",
      "other": "अन्य",

      // AI Assistant
      "ai_assistant": "बीमामित्र सहायक",
      "how_can_i_help": "आज मैं आपकी कैसे मदद कर सकता हूं?",
      "listening": "सुन रहे हैं...",
      "processing": "आपके अनुरोध को संसाधित कर रहा है...",
      "speak_now": "अब बोलें",
    },

    "mr": {
      // Language Selection Screen
      "choose_language": "तुमची भाषा निवडा",
      "hindi": "हिंदी",
      "marathi": "मराठी",
      "telugu": "తెలుగు",
      "start_with_voice": "आवाजाने सुरू करा",

      // Onboarding Screen
      "tell_us_about_yourself": "तुमच्याबद्दल सांगा",
      "progress": "प्रगती",
      "what_is_your_occupation": "तुमचा व्यवसाय काय आहे?",
      "what_is_your_age": "तुमचे वय किती आहे?",
      "what_is_your_income": "तुमचे मासिक उत्पन्न किती आहे?",
      "do_you_have_dependents": "तुमच्यावर अवलंबून असलेले आहेत का?",
      "any_existing_health_conditions": "कोणतीही आरोग्य समस्या आहे का?",
      "tap_to_speak": "बोलण्यासाठी टॅप करा",
      "or_type_your_answer": "किंवा खाली तुमचे उत्तर टाइप करा",
      "type_here": "येथे टाइप करा...",
      "next": "पुढे",
      "previous": "मागे",
      "skip": "वगळा",

      // Recommendation Screen
      "recommended_for_you": "तुमच्यासाठी शिफारस",
      "based_on_your_profile": "तुमच्या प्रोफाइलवर आधारित",
      "pradhan_mantri_suraksha_bima": "प्रधानमंत्री सुरक्षा बीमा",
      "jeevan_jyoti_bima_yojana": "जीवन ज्योती बीमा योजना",
      "premium": "प्रीमियम",
      "per_year": "/वर्ष",
      "key_benefits": "मुख्य फायदे:",
      "accidental_death_coverage": "अपघाती मृत्यू कव्हरेज ₹2 लाख",
      "permanent_disability_coverage": "कायमस्वरूपी अपंगत्व कव्हरेज ₹2 लाख",
      "partial_disability_coverage": "आंशिक अपंगत्व कव्हरेज ₹1 लाख",
      "life_cover": "₹2 लाखाचा जीवन विमा",
      "renewable_every_year": "दरवर्षी नूतनीकरण करण्यायोग्य",
      "tax_benefits_80c": "80C अंतर्गत कर लाभ",
      "why_this_policy": "ही पॉलिसी का?",
      "continue": "पुढे चला",
      "exclusions": "वगळणे",
      "self_inflicted_injuries": "स्वयं-प्रेरित दुखापती, युद्ध, आण्विक जोखीम",

      // Consent Screen
      "please_confirm_consent": "कृपया तुमची संमती पुष्टी करा",
      "record_voice_approval": "तुमची आवाज मंजुरी रेकॉर्ड करा",
      "coverage": "कव्हरेज",
      "accidental_death_disability": "अपघाती मृत्यू आणि अपंगत्व - ₹2 लाख",
      "tap_to_record_consent": "संमती रेकॉर्ड करण्यासाठी टॅप करा",
      "please_say":
          "कृपया म्हणा: \"मी, [तुमचे नाव], सांगितलेल्या अटी व शर्तींसह ही पॉलिसी खरेदी करण्यास सहमत आहे\"",
      "submit_consent": "संमती सबमिट करा",
      "recording": "रेकॉर्डिंग...",
      "recorded": "रेकॉर्ड केले",

      // KYC Verification Screen
      "kyc_verification": "KYC पडताळणी",
      "upload_your_aadhar_card": "तुमचे आधार कार्ड अपलोड करा",
      "position_aadhar_card": "तुमचे आधार कार्ड ठेवा",
      "front_side_first": "प्रथम समोरची बाजू",
      "upload_aadhar_photo": "आधार फोटो अपलोड करा",
      "automatically_captured": "स्वयंचलितपणे कॅप्चर:",
      "gps_location": "GPS स्थान",
      "timestamp": "वेळ चिन्ह",
      "instructions": "सूचना:",
      "ensure_all_details_visible":
          "1. सर्व तपशील स्पष्टपणे दिसत असल्याची खात्री करा",
      "avoid_glare_shadows": "2. चकाकी आणि सावल्या टाळा",
      "upload_both_sides": "3. समोर आणि मागे दोन्ही बाजू अपलोड करा",
      "continue_upload_photo_first": "पुढे चला (प्रथम फोटो अपलोड करा)",
      "verified_via_blockchain": "ब्लॉकचेन द्वारे सत्यापित",

      // Policy Success Screen
      "your_policy_is_active": "तुमची पॉलिसी सक्रिय आहे",
      "policy_successfully_issued": "पॉलिसी यशस्वीरित्या जारी केली",
      "policy_name": "पॉलिसीचे नाव",
      "policy_number": "पॉलिसी क्रमांक",
      "start_date": "सुरुवातीची तारीख",
      "download_policy": "पॉलिसी डाउनलोड करा",
      "share_policy": "पॉलिसी शेअर करा",
      "view_details": "तपशील पहा",
      "go_to_home": "होमवर जा",

      // Common
      "yes": "होय",
      "no": "नाही",
      "back": "परत",
      "submit": "सबमिट करा",
      "cancel": "रद्द करा",
      "ok": "ठीक आहे",
      "error": "त्रुटी",
      "success": "यश",
      "loading": "लोड होत आहे...",

      // Occupations
      "farmer": "शेतकरी",
      "shopkeeper": "दुकानदार",
      "daily_wage_worker": "दैनिक मजुरी कामगार",
      "government_employee": "सरकारी कर्मचारी",
      "private_employee": "खाजगी कर्मचारी",
      "self_employed": "स्वयंरोजगार",
      "student": "विद्यार्थी",
      "homemaker": "गृहिणी",
      "other": "इतर",

      // AI Assistant
      "ai_assistant": "बीमामित्र सहाय्यक",
      "how_can_i_help": "आज मी तुम्हाला कशी मदत करू शकतो?",
      "listening": "ऐकत आहे...",
      "processing": "तुमची विनंती प्रक्रिया करत आहे...",
      "speak_now": "आता बोला",
    },
  };

  /// Get translated text with language code parameter
  static String getTextWithLang(String key, String lang) {
    return translations[lang]?[key] ?? key;
  }

  /// Check if a translation exists
  static bool hasTranslation(String key) {
    return translations[_currentLanguage]?.containsKey(key) ?? false;
  }

  /// Get all available languages
  static List<Map<String, String>> getAvailableLanguages() {
    return [
      {
        "code": "en",
        "name": "English",
        "nativeName": "English",
        "flag": "🇬🇧",
      },
      {"code": "hi", "name": "Hindi", "nativeName": "हिंदी", "flag": "🇮🇳"},
      {"code": "mr", "name": "Marathi", "nativeName": "मराठी", "flag": "🇮🇳"},
    ];
  }
}
