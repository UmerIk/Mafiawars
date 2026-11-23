import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../domain/entities/friend_request_entity.dart';
import 'providers/social_providers.dart';

class SocialScreen extends ConsumerStatefulWidget {
  const SocialScreen({super.key});

  @override
  ConsumerState<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends ConsumerState<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<UserEntity> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    final results = await ref
        .read(socialControllerProvider.notifier)
        .searchUsers(query.trim());
    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _sendRequest(UserEntity user) async {
    await ref.read(socialControllerProvider.notifier).sendFriendRequest(user);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Friend request sent to ${user.displayName}')),
      );
    }
  }

  Future<void> _acceptRequest(FriendRequestEntity request) async {
    await ref
        .read(socialControllerProvider.notifier)
        .acceptFriendRequest(request);
  }

  Future<void> _rejectRequest(String requestId) async {
    await ref
        .read(socialControllerProvider.notifier)
        .rejectFriendRequest(requestId);
  }

  Future<void> _removeFriend(String friendId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F2833),
        title:
            Text('Remove $name?', style: const TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to remove this agent from your network?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('CANCEL', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF1E56)),
            child: const Text('REMOVE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(socialControllerProvider.notifier).removeFriend(friendId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsStreamProvider);
    final pendingRequestsAsync = ref.watch(pendingRequestsStreamProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_skyline.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF7D75D9),
                      Color(0xFF43275A),
                      Color(0xFF191024)
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: Container(color: const Color(0x4D191024))),
          Container(
            child: SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0x8043275A),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFF7DD6FC)),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFFFEF0E6),
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Messages',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFEF0E6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        InkWell(
                          onTap: () => context.push('/new_chat'),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0x8043275A),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFF7DD6FC)),
                            ),
                            child: const Icon(
                              Icons.edit_note,
                              color: Color(0xFFFEF0E6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 8.0),
                    child: Container(
                      height: 54,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF301C40),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFF7DD6FC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.search,
                              color: Color(0xFF689EEA), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _performSearch,
                              style: const TextStyle(
                                color: Color(0xFFFEF0E6),
                                fontSize: 16,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                hintText: 'Search Codename',
                                hintStyle: TextStyle(color: Color(0xFF689EEA)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tab Switcher
                  TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF7DD6FC),
                    labelColor: const Color(0xFFFEF0E6),
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      const Tab(text: 'FRIENDS'),
                      Tab(
                        text: pendingRequestsAsync.value?.isNotEmpty == true
                            ? 'REQUESTS (${pendingRequestsAsync.value!.length})'
                            : 'REQUESTS',
                      ),
                    ],
                  ),

                  if (_searchController.text.isNotEmpty)
                    Expanded(
                      child: _isSearching
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF7DD6FC)),
                            )
                          : _searchResults.isEmpty
                              ? const Center(
                                  child: Text('No agents found.',
                                      style: TextStyle(color: Colors.white54)))
                              : ListView.builder(
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = _searchResults[index];
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Color(0xFF43275A),
                                        child: Icon(Icons.person,
                                            color: Colors.white),
                                      ),
                                      title: Text(user.displayName,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.person_add_alt_1,
                                            color: Color(0xFF7DD6FC)),
                                        onPressed: () => _sendRequest(user),
                                      ),
                                    );
                                  },
                                ),
                    )
                  else
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // FRIENDS / CHATS LIST
                          friendsAsync.when(
                            data: (friends) => friends.isEmpty
                                ? const Center(
                                    child: Text('No friends added yet.',
                                        style:
                                            TextStyle(color: Colors.white54)))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: friends.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final friend = friends[index];
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0x8043275A),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: const Color(0xFF7DD6FC)),
                                        ),
                                        child: ListTile(
                                          leading: Stack(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor:
                                                    const Color(0xFF43275A),
                                                child: const Icon(Icons.person,
                                                    color: Colors.white),
                                              ),
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 10,
                                                  height: 10,
                                                  decoration: BoxDecoration(
                                                    color: friend.status ==
                                                            'online'
                                                        ? const Color(
                                                            0xFF34C759)
                                                        : Colors.grey,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          title: Text(
                                            friend.displayName,
                                            style: const TextStyle(
                                              color: Color(0xFFFEF0E6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          subtitle: Text(
                                            'Tap to chat with agent...',
                                            style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.6),
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.chat,
                                                    color: Color(0xFF7DD6FC)),
                                                onPressed: () => context.push(
                                                  '/social/chat/${friend.uid}?name=${Uri.encodeComponent(friend.displayName)}',
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.person_remove,
                                                    color: Colors.white38),
                                                onPressed: () => _removeFriend(
                                                    friend.uid,
                                                    friend.displayName),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF7DD6FC)),
                            ),
                            error: (err, _) => Center(
                              child: Text('Error: $err',
                                  style:
                                      const TextStyle(color: Colors.redAccent)),
                            ),
                          ),

                          // PENDING REQUESTS
                          pendingRequestsAsync.when(
                            data: (requests) => requests.isEmpty
                                ? const Center(
                                    child: Text('No pending requests.',
                                        style:
                                            TextStyle(color: Colors.white54)))
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: requests.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final request = requests[index];
                                      return Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0x8043275A),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                              color: const Color(0xFF7DD6FC)),
                                        ),
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Color(0xFF43275A),
                                            child: Icon(Icons.person,
                                                color: Colors.white),
                                          ),
                                          title: Text(
                                            request.senderDisplayName,
                                            style: const TextStyle(
                                              color: Color(0xFFFEF0E6),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.greenAccent),
                                                onPressed: () =>
                                                    _acceptRequest(request),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel,
                                                    color: Colors.redAccent),
                                                onPressed: () =>
                                                    _rejectRequest(request.id),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF7DD6FC)),
                            ),
                            error: (err, _) => Center(
                              child: Text('Error: $err',
                                  style:
                                      const TextStyle(color: Colors.redAccent)),
                            ),
                          ),
                        ],
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
}
