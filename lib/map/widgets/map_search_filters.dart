import 'package:flutter/material.dart';

import '../../design/brand_theme.dart';
import '../map_view_model.dart';

class MapSearchFilters extends StatelessWidget {
  const MapSearchFilters({
    super.key,
    required this.viewModel,
    required this.onShowAll,
  });

  final MapViewModel viewModel;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.white,
          elevation: 6,
          shadowColor: AppColors.ink.withValues(alpha: .18),
          borderRadius: BorderRadius.circular(19),
          child: TextField(
            key: const Key('map-search-field'),
            onChanged: viewModel.setSearch,
            decoration: InputDecoration(
              hintText: 'Buscar baños, escenarios, accesos…',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Ver todo',
                onPressed: onShowAll,
                icon: const Icon(Icons.center_focus_strong_rounded),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 43,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MapCategory.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final category = MapCategory.values[index];
              final selected = viewModel.state.category == category;
              return FilterChip(
                selected: selected,
                onSelected: (_) => viewModel.setCategory(category),
                label: Text(category.label),
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                side: BorderSide(
                  color: selected ? AppColors.primary : AppColors.line,
                ),
                labelStyle: TextStyle(
                  color: selected ? AppColors.primary : AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
                backgroundColor: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }
}
