import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategoryTabs({
    Key? key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < AppTheme.mobileBreakpoint;
    final isTablet = screenWidth < AppTheme.tabletBreakpoint && screenWidth >= AppTheme.mobileBreakpoint;
    
    // Calcul des dimensions responsives
    final horizontalPadding = isMobile ? 12.0 : 16.0;
    final verticalPadding = isMobile ? 6.0 : 8.0;
    final margin = isMobile ? 6.0 : 8.0;
    final fontSize = isMobile ? 14.0 : (isTablet ? 15.0 : 16.0);
    final borderWidth = isMobile ? 1.5 : 2.0;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          categories.length,
          (index) => GestureDetector(
            onTap: () => onCategorySelected(index),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              margin: EdgeInsets.only(
                left: margin,
                right: margin,
                bottom: margin,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selectedIndex == index ? Colors.white : Colors.transparent,
                    width: borderWidth,
                  ),
                ),
              ),
              child: Text(
                categories[index],
                style: TextStyle(
                  color: selectedIndex == index ? Colors.white : Colors.grey[400],
                  fontSize: fontSize,
                  fontWeight: selectedIndex == index ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
} 