// 底部标签
          if (showBottomLabel)
            Positioned(
              right: 10,
              bottom: 11,
              child: Transform.translate(
                offset: const Offset(20, 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xff046AE4),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Text(
                    bottomLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),