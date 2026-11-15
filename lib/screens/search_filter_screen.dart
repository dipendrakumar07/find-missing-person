import 'package:flutter/material.dart';
import '../models/missing_person.dart';
import '../services/missing_person_repository.dart';
import '../widgets/person_card.dart';

class SearchFilterScreen extends StatefulWidget {
  final String? initialCategory;

  const SearchFilterScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  late String _selectedCategory;
  String _selectedGender = 'All';
  PersonStatus? _selectedStatus;
  RangeValues _ageRange = const RangeValues(0, 100);
  bool _showFiltersPanel = false;

  final List<String> _categories = [
    'All',
    'Urgent Alert',
    'Children',
    'Adults',
    'Seniors',
    'Resolved',
    'Bookmarked',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'All';
      _selectedGender = 'All';
      _selectedStatus = null;
      _ageRange = const RangeValues(0, 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: MissingPersonRepository(),
      builder: (context, _) {
        final results = MissingPersonRepository().searchAndFilter(
          query: _searchController.text.trim(),
          category: _selectedCategory,
          gender: _selectedGender == 'All' ? null : _selectedGender,
          status: _selectedStatus,
          minAge: _ageRange.start > 0 ? _ageRange.start : null,
          maxAge: _ageRange.end < 100 ? _ageRange.end : null,
        );

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: const Text(
              'Search & Filters',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  _showFiltersPanel ? Icons.filter_list_off_rounded : Icons.tune_rounded,
                  color: const Color(0xFF2563EB),
                ),
                tooltip: 'Toggle Filter Panel',
                onPressed: () {
                  setState(() {
                    _showFiltersPanel = !_showFiltersPanel;
                  });
                },
              ),
              if (_selectedCategory != 'All' ||
                  _selectedGender != 'All' ||
                  _selectedStatus != null ||
                  _searchController.text.isNotEmpty ||
                  _ageRange.start > 0 ||
                  _ageRange.end < 100)
                IconButton(
                  icon: const Icon(Icons.restart_alt_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Reset Filters',
                  onPressed: _resetFilters,
                ),
            ],
          ),
          body: Column(
            children: [
              // Search Input Container
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by name, city, case number, marks...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
              ),

              // Categories Chips Horizontal Bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: const Color(0xFF2563EB),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedCategory = cat;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Expandable Advanced Filters Panel
              if (_showFiltersPanel)
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF8FAFC),
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status filters
                      const Text(
                        'Case Status',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All Statuses'),
                            selected: _selectedStatus == null,
                            onSelected: (val) => setState(() => _selectedStatus = null),
                          ),
                          ...PersonStatus.values.map(
                            (st) => ChoiceChip(
                              label: Text(st.displayName),
                              selected: _selectedStatus == st,
                              onSelected: (val) => setState(() => _selectedStatus = val ? st : null),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Gender filters
                      const Text(
                        'Gender',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: ['All', 'Female', 'Male', 'Other'].map((g) {
                          final isSel = _selectedGender == g;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(g),
                              selected: isSel,
                              onSelected: (val) => setState(() => _selectedGender = g),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      // Age range
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Age Range',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                          Text(
                            '${_ageRange.start.round()} - ${_ageRange.end.round()} yrs',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ],
                      ),
                      RangeSlider(
                        values: _ageRange,
                        min: 0,
                        max: 100,
                        divisions: 20,
                        activeColor: const Color(0xFF2563EB),
                        labels: RangeLabels(
                          '${_ageRange.start.round()}',
                          '${_ageRange.end.round()}',
                        ),
                        onChanged: (vals) {
                          setState(() {
                            _ageRange = vals;
                          });
                        },
                      ),
                    ],
                  ),
                ),

              // Results Count Banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Found ${results.length} case${results.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    if (_selectedCategory != 'All' || _selectedGender != 'All' || _selectedStatus != null)
                      GestureDetector(
                        onTap: _resetFilters,
                        child: const Text(
                          'Clear Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Results List
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 56, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text(
                                'No matching cases found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF334155),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Try adjusting your search keywords or loosening the filter criteria.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _resetFilters,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset All Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          return PersonCard(person: results[index]);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
