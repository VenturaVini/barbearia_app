import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../domain/entities/service.dart';

/// Card de Serviço
class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;
  final bool showPrice;

  const ServiceCard({
    super.key,
    required this.service,
    this.onTap,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagem do serviço
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: service.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: service.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.surface,
                          child: const Icon(
                            Icons.content_cut,
                            color: AppColors.gold,
                            size: 32,
                          ),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.content_cut,
                          color: AppColors.gold,
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 16),

              // Informações do serviço
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          service.formattedDuration,
                          style: AppTextStyles.caption,
                        ),
                        if (showPrice) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: AppColors.gold,
                          ),
                          Text(
                            service.formattedPrice,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Ícone de seta
              if (onTap != null)
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textMuted,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
