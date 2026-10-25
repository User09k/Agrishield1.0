import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../config/app_config.dart';
import 'language_controller.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toApiFormat() => {
        'role': isUser ? 'user' : 'assistant',
        'content': content,
      };
}

class ChatbotController extends GetxController {
  var messages = <ChatMessage>[].obs;
  var isTyping = false.obs;
  var language = 'en'.obs; // hi = Hindi, en = English
  var isListening = false.obs;
  var isSpeechAvailable = false.obs;
  final textController = TextEditingController();
  final scrollController = ScrollController();
  late stt.SpeechToText _speech;

  String get baseUrl => AppConfig.baseUrl;

  @override
  void onInit() {
    super.onInit();
    language.value = LanguageController.currentLang;
    try {
      if (Get.isRegistered<LanguageController>()) {
        ever(Get.find<LanguageController>().currentLocale, (locale) {
          language.value = locale.languageCode;
        });
      }
    } catch (_) {}
    _speech = stt.SpeechToText();
    _initSpeech();
    // Welcome message
    messages.add(ChatMessage(
      content: language.value == 'hi'
          ? '🌾 नमस्ते! मैं AgriBot हूं — आपका कृषि सहायक।\n\nमुझसे फसल, बीमारी, कीटनाशक, मंडी भाव, मौसम, या खेती से जुड़ा कोई भी सवाल पूछें!'
          : '🌾 Hello! I\'m AgriBot — your agriculture assistant.\n\nAsk me anything about crops, diseases, pesticides, market prices, weather, or farming!',
      isUser: false,
    ));
  }

  Future<void> _initSpeech() async {
    try {
      isSpeechAvailable.value = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            isListening.value = false;
          }
        },
        onError: (err) {
          isListening.value = false;
        },
      );
    } catch (_) {
      isSpeechAvailable.value = false;
    }
  }

  void toggleListening() async {
    try {
      if (!isSpeechAvailable.value) {
        bool available = await _speech.initialize(
          onStatus: (status) {
            if (status == 'done' || status == 'notListening') {
              isListening.value = false;
            }
          },
          onError: (err) => isListening.value = false,
        );
        isSpeechAvailable.value = available;
        if (!available) {
          Get.snackbar(
            'Microphone',
            language.value == 'hi'
                ? 'कृपया माइक्रोफोन अनुमति दें या डिवाइस में स्पीच सपोर्ट चेक करें।'
                : 'Please grant microphone permission or check speech support.',
            backgroundColor: Colors.white,
          );
          return;
        }
      }

      if (isListening.value) {
        await _speech.stop();
        isListening.value = false;
      } else {
        isListening.value = true;
        final localeId = language.value == 'hi' ? 'hi_IN' : 'en_IN';

        await _speech.listen(
          onResult: (result) {
            textController.text = result.recognizedWords;
            if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
              isListening.value = false;
            }
          },
          localeId: localeId,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      isListening.value = false;
      Get.snackbar('Voice Input', 'Microphone error: $e', backgroundColor: Colors.white);
    }
  }

  @override
  void onClose() {
    textController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  /// Toggle language
  void toggleLanguage() {
    language.value = language.value == 'hi' ? 'en' : 'hi';
    if (Get.isRegistered<LanguageController>()) {
      Get.find<LanguageController>().changeLanguage(language.value);
    }
    messages.add(ChatMessage(
      content: language.value == 'hi'
          ? '🔄 भाषा बदली गई: हिंदी'
          : '🔄 Language changed: English',
      isUser: false,
    ));
    _scrollToBottom();
  }

  /// Send message to AgriBot
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    messages.add(ChatMessage(content: text.trim(), isUser: true));
    textController.clear();
    _scrollToBottom();

    // Show typing
    isTyping(true);

    try {
      // Build history from recent messages
      final history = messages
          .where((m) => !m.content.startsWith('🔄'))
          .take(20)
          .map((m) => m.toApiFormat())
          .toList();

      final lang = language.value;
      final response = await http
          .post(
            Uri.parse('$baseUrl/agri-chat'),
            headers: {
              'Content-Type': 'application/json',
              'Accept-Language': lang,
              'X-App-Language': lang,
            },
            body: json.encode({
              'message': text.trim(),
              'language': lang,
              'history': history,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'Success') {
          final reply = data['data']['reply']?.toString() ?? 'Sorry, I could not process that.';
          messages.add(ChatMessage(content: reply, isUser: false));
        } else {
          messages.add(ChatMessage(
            content: language.value == 'hi'
                ? '❌ माफ कीजिए, कोई समस्या हुई। कृपया दोबारा प्रयास करें।'
                : '❌ Sorry, something went wrong. Please try again.',
            isUser: false,
          ));
        }
      } else {
        messages.add(ChatMessage(
          content: language.value == 'hi'
              ? '❌ सर्वर से कनेक्ट नहीं हो पाया। इंटरनेट चेक करें।'
              : '❌ Could not connect to server. Check your internet.',
          isUser: false,
        ));
      }
    } catch (e) {
      messages.add(ChatMessage(
        content: language.value == 'hi'
            ? '❌ कनेक्शन में समस्या आई। कृपया दोबारा प्रयास करें।'
            : '❌ Connection error. Please try again.',
        isUser: false,
      ));
    } finally {
      isTyping(false);
      _scrollToBottom();
    }
  }

  /// Handle mic result
  void onSpeechResult(String text) {
    if (text.trim().isNotEmpty) {
      textController.text = text;
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
