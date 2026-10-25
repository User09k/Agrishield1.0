import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/chatbot_controller.dart';

class ChatbotView extends StatelessWidget {
  const ChatbotView({super.key});

  static const _primary = Color(0xFF1B5E20);
  static const _accent = Color(0xFF00E676);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChatbotController());

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AgriBot',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Agriculture AI Assistant',
                    style: TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ],
        ),
        actions: [
          // Language Toggle
          Obx(() => GestureDetector(
                onTap: () => c.toggleLanguage(),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.translate, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        c.language.value == 'hi' ? 'हिंदी' : 'EN',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
      body: Column(
        children: [
          // ── Quick Actions ──
          _buildQuickActions(c),

          // ── Chat Messages ──
          Expanded(
            child: Obx(() => ListView.builder(
                  controller: c.scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: c.messages.length + (c.isTyping.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == c.messages.length && c.isTyping.value) {
                      return _buildTypingIndicator();
                    }
                    final msg = c.messages[index];
                    return _buildMessageBubble(msg);
                  },
                )),
          ),

          // ── Input Bar ──
          _buildInputBar(c),
        ],
      ),
    );
  }

  /// Quick action chips
  Widget _buildQuickActions(ChatbotController c) {
    final actions = c.language.value == 'hi'
        ? [
            '🌾 फसल की बीमारी',
            '💰 मंडी भाव',
            '🌧️ मौसम सलाह',
            '🧪 खाद कितनी डालें',
            '🐛 कीट नियंत्रण',
          ]
        : [
            '🌾 Crop Disease',
            '💰 Market Price',
            '🌧️ Weather Tips',
            '🧪 Fertilizer Guide',
            '🐛 Pest Control',
          ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() => Row(
              children: (c.language.value == 'hi'
                      ? [
                          '🌾 फसल की बीमारी',
                          '💰 मंडी भाव',
                          '🌧️ मौसम सलाह',
                          '🧪 खाद कितनी डालें',
                          '🐛 कीट नियंत्रण',
                        ]
                      : [
                          '🌾 Crop Disease',
                          '💰 Market Price',
                          '🌧️ Weather Tips',
                          '🧪 Fertilizer Guide',
                          '🐛 Pest Control',
                        ])
                  .map((action) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(action,
                              style: const TextStyle(fontSize: 12)),
                          backgroundColor: _primary.withOpacity(0.08),
                          side: BorderSide(color: _primary.withOpacity(0.2)),
                          onPressed: () => c.sendMessage(action),
                        ),
                      ))
                  .toList(),
            )),
      ),
    );
  }

  /// Chat message bubble
  Widget _buildMessageBubble(ChatMessage msg) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: msg.isUser ? 50 : 0,
        right: msg.isUser ? 0 : 50,
      ),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Text('🌱', style: TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: msg.isUser ? _primary : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                  bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: msg.isUser
                          ? Colors.white.withOpacity(0.6)
                          : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 16)),
            ),
          ],
        ],
      ),
    );
  }

  /// Typing indicator
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, right: 50),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🌱', style: TextStyle(fontSize: 16))),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bouncingDot(0),
                _bouncingDot(150),
                _bouncingDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bouncingDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  /// Input bar with mic and send
  Widget _buildInputBar(ChatbotController c) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(Get.context!).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mic button with real speech_to_text
          Obx(() => GestureDetector(
                onTap: () => c.toggleListening(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: c.isListening.value
                        ? Colors.red.withOpacity(0.18)
                        : _primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: c.isListening.value
                          ? Colors.red
                          : _primary.withOpacity(0.2),
                      width: c.isListening.value ? 2.0 : 1.0,
                    ),
                  ),
                  child: Icon(
                    c.isListening.value ? Icons.mic : Icons.mic_none,
                    color: c.isListening.value ? Colors.red : _primary,
                    size: 22,
                  ),
                ),
              )),
          const SizedBox(width: 8),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4F0),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: c.textController,
                decoration: InputDecoration(
                  hintText: c.language.value == 'hi'
                      ? 'अपना सवाल पूछें...'
                      : 'Ask your question...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (v) => c.sendMessage(v),
                maxLines: 3,
                minLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          Obx(() => GestureDetector(
                onTap: c.isTyping.value
                    ? null
                    : () => c.sendMessage(c.textController.text),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primary, _primary.withOpacity(0.8)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
