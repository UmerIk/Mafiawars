import 'package:flutter/material.dart';

class MafiaUi {
  MafiaUi._();

  static const background = Color(0xFF301C40);
  static const surface = Color(0x8043275A);
  static const field = Color(0xFF301C40);
  static const cyan = Color(0xFF7DD6FC);
  static const pink = Color(0xFFED77ED);
  static const white = Color(0xFFFEF0E6);
  static const blue = Color(0xFF689EEA);

  static const gradient = LinearGradient(
    colors: [cyan, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static Widget backgroundStack({required Widget child}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/bg_skyline.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
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
        Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.12))),
        SafeArea(child: child),
      ],
    );
  }

  static Widget backButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).maybePop(),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [blue.withOpacity(0.9), surface],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cyan, width: 1.5),
          boxShadow: const [
            BoxShadow(
                color: Colors.black38, blurRadius: 10, offset: Offset(0, 5))
          ],
        ),
        child: const Icon(Icons.arrow_back, color: white, size: 32),
      ),
    );
  }

  static Widget searchField(
    TextEditingController controller, {
    required ValueChanged<String> onChanged,
    String hint = 'Search Codename',
  }) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: field,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cyan, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(color: white, fontSize: 16),
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: blue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget gradientButton({
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : gradient,
        color: onPressed == null ? const Color(0xFF44395E) : null,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white54),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(label,
                    style: const TextStyle(
                        color: white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  static Widget panel(
      {required Widget child,
      EdgeInsetsGeometry? padding,
      double radius = 18}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: cyan, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: child,
    );
  }
}
