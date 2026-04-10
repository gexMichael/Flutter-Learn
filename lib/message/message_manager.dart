import 'package:flutter/material.dart';
import './message_model.dart';
import './message_api.dart';
import './message_detail.dart';

class MessageManager extends StatefulWidget {
  final String currentUserId;
  const MessageManager({required this.currentUserId, super.key});

  @override
  State<MessageManager> createState() => _MessageManagerState();
}

class _MessageManagerState extends State<MessageManager> {
  late MessageApiService _apiService;
  late Future<List<EipMessage>> _messageFuture;

  @override
  void initState() {
    super.initState();
    _apiService = MessageApiService();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _messageFuture = _apiService.fetchMessages(widget.currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知訊息'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshList,
          )
        ],
      ),
      body: FutureBuilder<List<EipMessage>>(
        future: _messageFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('近 30 天內無任何通知訊息'));
          }
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, i) => _buildMessageCard(snapshot.data![i]),
          );
        },
      ),
      // 此為唯讀功能，因此移除 FloatingActionButton
    );
  }

  Widget _buildMessageCard(EipMessage item) {
    return Card(
      elevation: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        onTap: () async {
          // 點擊進入詳情
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => MessageDetail(message: item)),
          );
          // 若在詳情頁有觸發「已讀」，返回時可重新整理列表
          _refreshList();
        },
        leading: CircleAvatar(
          backgroundColor: item.statusColor.withOpacity(0.1),
          child: Icon(
            item.isRead ? Icons.mark_email_read : Icons.mark_email_unread,
            color: item.statusColor,
          ),
        ),
        title: Text(
          item.subjectLine, //
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(item.formattedDate),
      ),
    );
  }
}