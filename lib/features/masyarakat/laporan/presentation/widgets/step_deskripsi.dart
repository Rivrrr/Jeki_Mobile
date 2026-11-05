import 'package:flutter/material.dart';

class StepDeskripsi extends StatelessWidget {
  final TextEditingController deskripsiController;
  final String? selectedPrioritas;
  final ValueChanged<String> onSelectPrioritas;

  const StepDeskripsi({
    super.key,
    required this.deskripsiController,
    required this.selectedPrioritas,
    required this.onSelectPrioritas,
  });

  @override
  Widget build(BuildContext context) {
    final prioritasList = [
      {'title': 'Urgent', 'desc': 'Bahaya langsung / darurat', 'color': Colors.red},
      {'title': 'Tinggi', 'desc': 'Perlu segera ditangani', 'color': Colors.orange},
      {'title': 'Sedang', 'desc': 'Dalam 1-2 minggu', 'color': Colors.amber},
      {'title': 'Rendah', 'desc': 'Dapat dijadwalkan', 'color': Colors.green},
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Deskripsi Kondisi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: deskripsiController,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length}/500',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: deskripsiController,
            maxLines: 6,
            maxLength: 500,
            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null, // Hide default counter
            decoration: InputDecoration(
              hintText: 'Jelaskan kondisi infrastruktur yang Anda temukan. Semakin detail semakin cepat ditangani...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.5),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE91E63)),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: Color(0xFFE2E8F0), height: 1),
          ),
          
          const Text(
            'Tingkat Prioritas',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: prioritasList.length,
            itemBuilder: (context, index) {
              final prio = prioritasList[index];
              final isSelected = selectedPrioritas == prio['title'];
              
              return GestureDetector(
                onTap: () => onSelectPrioritas(prio['title'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE91E63) : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: const Color(0xFFE91E63).withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ] : [],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: prio['color'] as Color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (prio['color'] as Color).withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              prio['title'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFFE91E63) : const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              prio['desc'] as String,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
