import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as material;
import '../models/faq_item.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedItems = {};
  FAQCategory? _selectedCategory;
  String _searchQuery = '';

  String _getCategoryDisplayName(FAQCategory category) {
    switch (category) {
      case FAQCategory.general:
        return 'General';
      case FAQCategory.detection:
        return 'Detection';
      case FAQCategory.aroma:
        return 'Aroma';
      case FAQCategory.bluetooth:
        return 'Bluetooth';
      case FAQCategory.privacy:
        return 'Privacy & Security';
      case FAQCategory.troubleshooting:
        return 'Troubleshooting';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FAQItem> get _filteredFAQs {
    var faqs = FAQRepository.getAllFAQs();

    // Filter by category if selected
    if (_selectedCategory != null) {
      faqs = faqs.where((faq) => faq.category == _selectedCategory).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      faqs = faqs.where((faq) {
        final query = _searchQuery.toLowerCase();
        return faq.question.toLowerCase().contains(query) ||
            faq.answer.toLowerCase().contains(query) ||
            faq.tags.any((tag) => tag.toLowerCase().contains(query));
      }).toList();
    }

    return faqs;
  }

  void _toggleExpansion(String id) {
    setState(() {
      _expandedItems[id] = !(_expandedItems[id] ?? false);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _selectCategory(FAQCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1B2E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'FAQ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            child: Material(
              color: const Color(0xFF2D3250),
              borderRadius: BorderRadius.circular(16),
              elevation: 0,
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search questions...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF7C3AED),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.grey,
                          ),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          // Category Filter Chips
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: FAQCategory.values.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildCategoryChip(null, 'All');
                }
                final category = FAQCategory.values[index - 1];
                return _buildCategoryChip(
                    category, _getCategoryDisplayName(category));
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results Count
          if (_filteredFAQs.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 64,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No results found',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search or filters',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredFAQs.length,
                itemBuilder: (context, index) {
                  final faq = _filteredFAQs[index];
                  final isExpanded = _expandedItems[faq.id] ?? false;
                  return _buildFAQItem(faq, isExpanded);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(FAQCategory? category, String label) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          _selectCategory(selected ? category : null);
        },
        selectedColor: const Color(0xFFFFD700),
        backgroundColor: const Color(0xFF2D3250),
        checkmarkColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQItem faq, bool isExpanded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3250),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? const Color(0xFFFFD700).withOpacity(0.3)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: PageStorageKey<String>(faq.id),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          onExpansionChanged: (expanded) {
            if (expanded != isExpanded) {
              _toggleExpansion(faq.id);
            }
          },
          initiallyExpanded: isExpanded,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.2),
                  const Color(0xFF7C3AED).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getCategoryIcon(faq.category),
              color: const Color(0xFF7C3AED),
              size: 20,
            ),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                faq.question,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getCategoryDisplayName(faq.category),
                  style: const TextStyle(
                    color: Color(0xFF7C3AED),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          iconColor: const Color(0xFFFFD700),
          collapsedIconColor: const Color(0xFFFFD700),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.keyboard_arrow_down,
              color: Color(0xFFFFD700),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Answer
                  Text(
                    faq.answer,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),

                  // Tags
                  if (faq.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: faq.tags
                          .map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A1B2E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: Color(0xFF7C3AED),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                  ],

                  // Helpful Actions
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showHelpfulDialog(faq, true);
                          },
                          icon: const Icon(
                            Icons.thumb_up_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Helpful',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            side: const BorderSide(
                              color: Color(0xFF7C3AED),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showHelpfulDialog(faq, false);
                          },
                          icon: const Icon(
                            Icons.thumb_down_outlined,
                            size: 18,
                          ),
                          label: const Text(
                            'Not Helpful',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey,
                            side: const BorderSide(
                              color: Colors.grey,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(FAQCategory category) {
    switch (category) {
      case FAQCategory.general:
        return Icons.info_outline;
      case FAQCategory.detection:
        return Icons.visibility_outlined;
      case FAQCategory.aroma:
        return Icons.spa_outlined;
      case FAQCategory.bluetooth:
        return Icons.bluetooth_outlined;
      case FAQCategory.privacy:
        return Icons.security_outlined;
      case FAQCategory.troubleshooting:
        return Icons.build_outlined;
    }
  }

  void _showHelpfulDialog(FAQItem faq, bool wasHelpful) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D3250),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              wasHelpful ? Icons.check_circle : Icons.feedback_outlined,
              color: wasHelpful ? Colors.green : const Color(0xFFFFD700),
            ),
            const SizedBox(width: 12),
            Text(
              wasHelpful ? 'Thank you!' : 'Feedback',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Text(
          wasHelpful
              ? 'We\'re glad this was helpful!'
              : 'We\'re sorry this wasn\'t helpful. Would you like to contact support?',
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        actions: [
          if (!wasHelpful)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'No thanks',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to help/contact screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening support...'),
                  backgroundColor: Color(0xFF7C3AED),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Text(
              wasHelpful ? 'Continue' : 'Contact Support',
              style: const TextStyle(color: Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }
}
