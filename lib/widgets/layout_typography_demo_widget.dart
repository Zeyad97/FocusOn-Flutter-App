import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_settings_provider.dart';
import '../theme/app_theme.dart';

class LayoutTypographyDemoWidget extends ConsumerWidget {
  const LayoutTypographyDemoWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(settings.interfacePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: AppColors.primaryPurple,
                  size: 24,
                ),
                SizedBox(width: settings.interfacePadding / 2),
                Text(
                  'Layout & Typography Demo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: settings.interfacePadding / 2,
                    vertical: settings.interfacePadding / 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    settings.interfaceDensity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: settings.interfacePadding),
            
            // Interface Density Demonstration
            Container(
              padding: EdgeInsets.all(settings.interfacePadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.1),
                    AppColors.accentPurple.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interface Density: ${settings.interfaceDensity}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: settings.interfacePadding / 2),
                  Text(
                    'This demo shows how interface density affects spacing and padding throughout the app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: settings.interfacePadding),
                  
                  // Sample UI elements showing density
                  ...List.generate(3, (index) => Container(
                    margin: EdgeInsets.only(bottom: settings.interfacePadding / 2),
                    child: ListTile(
                      dense: settings.interfaceDensity == 'Compact',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: settings.interfacePadding,
                        vertical: settings.interfacePadding / 4,
                      ),
                      leading: CircleAvatar(
                        radius: settings.interfaceDensity == 'Compact' ? 16 : 
                               settings.interfaceDensity == 'Spacious' ? 24 : 20,
                        backgroundColor: AppColors.primaryPurple.withOpacity(0.3),
                        child: Text('${index + 1}'),
                      ),
                      title: Text('Sample Item ${index + 1}'),
                      subtitle: Text('This shows ${settings.interfaceDensity.toLowerCase()} density'),
                      trailing: Icon(Icons.arrow_forward_ios, 
                        size: settings.interfaceDensity == 'Compact' ? 14 : 
                             settings.interfaceDensity == 'Spacious' ? 18 : 16),
                    ),
                  )),
                ],
              ),
            ),
            
            SizedBox(height: settings.interfacePadding),
            
            // Font Size Demonstration
            Container(
              padding: EdgeInsets.all(settings.interfacePadding),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Font Size: ${((settings.textScaleFactor - 0.75) / 0.75 * 8 + 12).round()}px',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: settings.interfacePadding / 2),
                  Text(
                    'Current text scale factor: ${settings.textScaleFactor.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: settings.interfacePadding),
                  
                  // Different text sizes for comparison
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heading Text',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: settings.interfacePadding / 4),
                      Text(
                        'Body Text - This demonstrates how the font size setting affects readability across the entire app.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: settings.interfacePadding / 4),
                      Text(
                        'Secondary Text - Smaller text that remains legible',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(height: settings.interfacePadding / 4),
                      Text(
                        'Caption Text - Very small but still readable',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: settings.interfacePadding),
            
            // Settings Values Display
            Container(
              padding: EdgeInsets.all(settings.interfacePadding),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Settings Values',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: settings.interfacePadding / 2),
                  _buildSettingRow('Interface Density', settings.interfaceDensity),
                  _buildSettingRow('Text Scale Factor', settings.textScaleFactor.toStringAsFixed(2)),
                  _buildSettingRow('Interface Padding', '${settings.interfacePadding.round()}px'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryPurple,
            ),
          ),
        ],
      ),
    );
  }
}
