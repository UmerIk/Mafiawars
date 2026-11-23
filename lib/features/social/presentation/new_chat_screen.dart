import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});

  @override
  ConsumerState<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends ConsumerState<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _agents = const [
    {
      'uid': 'agentx_1',
      'name': 'AgentX',
      'online': true,
      'image': 'assets/images/avatar_agentx.png'
    },
    {
      'uid': 'ajax_2',
      'name': 'Ajax',
      'online': true,
      'image': 'assets/images/avatar_ajax.png'
    },
    {
      'uid': 'cypork_3',
      'name': 'Cypork',
      'online': true,
      'image': 'assets/images/avatar_cypork.png'
    },
    {
      'uid': 'friday13_4',
      'name': 'Friday13',
      'online': true,
      'image': 'assets/images/avatar_friday13.png'
    },
    {
      'uid': 'pandared_5',
      'name': 'PandaRed',
      'online': true,
      'image': 'assets/images/avatar_pandared.png'
    },
    {
      'uid': 'rayven_6',
      'name': 'Rayven',
      'online': true,
      'image': 'assets/images/avatar_rayven.png'
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _agents.where((agent) {
      final name = (agent['name'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background Skyline Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg_skyline.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF43275A),
                      Color(0xFF301C40),
                      Color(0xFF191024),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top App Bar
                  Row(
                    children: [
                      InkWell(
                        onTap: () => context.pop(),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF689EEA), Color(0x8043275A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: const Color(0xFF7DD6FC), width: 1.5),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFFEF0E6),
                            size: 24,
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
                      const SizedBox(width: 50),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Search Field
                  Container(
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
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
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
                  const SizedBox(height: 20),

                  // Agent List
                  Expanded(
                    child: ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final agent = filtered[index];
                        return InkWell(
                          onTap: () {
                            context.push(
                              '/social/chat/${agent['uid']}?name=${Uri.encodeComponent(agent['name'])}',
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0x8043275A), Color(0x80301C40)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF7DD6FC), width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF43275A),
                                        border: Border.all(
                                            color: const Color(0xFF7DD6FC)),
                                      ),
                                      child: ClipOval(
                                        child: Image.asset(
                                          agent['image'] as String,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.person,
                                            color: Color(0xFFFEF0E6),
                                            size: 26,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (agent['online'] == true)
                                      Positioned(
                                        right: 2,
                                        bottom: 2,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF34C759),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                                color: Colors.black, width: 2),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  agent['name'] as String,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFEF0E6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
