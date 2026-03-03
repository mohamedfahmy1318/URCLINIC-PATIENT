import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:nb_utils/nb_utils.dart';

import '../../../components/app_scaffold.dart';
import '../../../utils/colors.dart';

const _geminiApiKey = 'AIzaSyB-TH7mvv6kf1lBdNXmwrA7RNSZb_p688k';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final RxList<ChatMessage> _messages = <ChatMessage>[].obs;
  final RxBool _isTyping = false.obs;

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();

    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _geminiApiKey,
      systemInstruction: Content.system(
        'أنت مساعد طبي ذكي في تطبيق عيادة URCLINIC. '
        'ساعد المرضى بالإجابة عن أسئلتهم الطبية العامة، '
        'ونصائح صحية، ومعلومات عن الخدمات الطبية. '
        'أجب دائماً بلطف واحترافية. '
        'إذا كان السؤال يتطلب تشخيصاً طبياً دقيقاً، '
        'انصح المريض بزيارة الطبيب. '
        'أجب باللغة التي يستخدمها المريض.',
      ),
    );
    _chat = _model.startChat();

    _messages.add(ChatMessage(
      text: 'مرحباً! أنا المساعد الذكي لعيادة URCLINIC 🏥\n'
          'كيف يمكنني مساعدتك اليوم؟',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isTyping.value) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _messageController.clear();
    _scrollToBottom();

    _isTyping.value = true;

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply = response.text ?? 'عذراً، لم أتمكن من الرد. حاول مرة أخرى.';

      _messages.add(ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: 'حدث خطأ في الاتصال. تأكد من اتصالك بالإنترنت وحاول مرة أخرى.',
        isUser: false,
        timestamp: DateTime.now(),
        isError: true,
      ));
    } finally {
      _isTyping.value = false;
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldNew(
      appBartitleText: 'AI Chat',
      scaffoldBackgroundColor: context.scaffoldBackgroundColor,
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Obx(
              () => ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
          ),

          // Typing indicator
          Obx(
            () => _isTyping.value
                ? Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: boxDecorationDefault(
                        color: context.cardColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _TypingDot(delay: 0),
                          6.width,
                          _TypingDot(delay: 200),
                          6.width,
                          _TypingDot(delay: 400),
                          12.width,
                          Text('يكتب...', style: secondaryTextStyle(size: 12)),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: context.cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        hintStyle: secondaryTextStyle(),
                        filled: true,
                        fillColor: context.scaffoldBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  12.width,
                  Obx(
                    () => GestureDetector(
                      onTap: _isTyping.value ? null : _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: boxDecorationDefault(
                          color: _isTyping.value
                              ? appColorPrimary.withOpacity(0.5)
                              : appColorPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationDefault(
                color: appColorPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy,
                color: appColorPrimary,
                size: 20,
              ),
            ),
            8.width,
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: message.text));
                toast('تم نسخ الرسالة');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: boxDecorationDefault(
                  color: message.isError
                      ? Colors.red.withOpacity(0.1)
                      : message.isUser
                          ? appColorPrimary
                          : context.cardColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: primaryTextStyle(
                        color: message.isError
                            ? Colors.red
                            : message.isUser
                                ? Colors.white
                                : null,
                        size: 14,
                      ),
                    ),
                    4.height,
                    Text(
                      _formatTime(message.timestamp),
                      style: secondaryTextStyle(
                        color: message.isUser ? Colors.white70 : null,
                        size: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            8.width,
            Container(
              padding: const EdgeInsets.all(8),
              decoration: boxDecorationDefault(
                color: appColorPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: appColorPrimary,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Animated typing dot
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: appColorPrimary.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
