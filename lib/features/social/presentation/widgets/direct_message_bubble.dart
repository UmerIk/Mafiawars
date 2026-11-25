// Created by Hamza Ali on 2026-11-25.
import 'package:flutter/material.dart';
import '../../../../core/widgets/design/design_components.dart';
import '../../../game/domain/entities/chat_message_entity.dart';

class DirectMessageBubble extends StatelessWidget {
  const DirectMessageBubble(
      {super.key, required this.message, required this.isMine});
  final ChatMessageEntity message;
  final bool isMine;
  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(message.timestamp.toLocal()));
    return Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
            widthFactor: .79,
            child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: isMine ? AppColors.publicBlue : AppColors.figmaPink,
                    borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isMine ? 20 : 0),
                        bottomRight: Radius.circular(isMine ? 0 : 20))),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(message.message, style: AppTypography.uiBody),
                      const SizedBox(height: 10),
                      Align(
                          alignment: isMine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Text(time,
                              style: AppTypography.uiCaption
                                  .copyWith(fontSize: 10)))
                    ]))));
  }
}

class ChatDateDivider extends StatelessWidget {
  const ChatDateDivider({super.key, required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) {
    final local = date.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    final label = day == today
        ? 'Today'
        : day == today.subtract(const Duration(days: 1))
            ? 'Yesterday'
            : MaterialLocalizations.of(context).formatMediumDate(local);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(children: [
          const Expanded(child: Divider(color: AppColors.figmaWhite)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(label,
                  style: AppTypography.uiCaption
                      .copyWith(fontWeight: FontWeight.w700))),
          const Expanded(child: Divider(color: AppColors.figmaWhite))
        ]));
  }
}
