import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../home/models/cms_models.dart';
import '../../home/providers/cms_providers.dart';
import '../data/cms_admin_repository.dart';
import '../providers/admin_providers.dart';

// ── 常數 ──────────────────────────────────────────────────────────────────────

const _kContentMaxWidth = 900.0;
const _kThumbnailSize = 72.0;

// ── CmsPage ────────────────────────────────────────────────────────────────────

/// CMS 後台主頁面（路由：`/admin/cms`）。
/// 分為 Banner 管理與品牌故事兩個 Tab。
class CmsPage extends ConsumerWidget {
  const CmsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('首頁視覺管理'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.image_outlined), text: 'Banner 管理'),
              Tab(icon: Icon(Icons.auto_stories_outlined), text: '品牌故事'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BannerManagementTab(),
            _BrandStoryTab(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Banner 管理 Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _BannerManagementTab extends ConsumerStatefulWidget {
  const _BannerManagementTab();

  @override
  ConsumerState<_BannerManagementTab> createState() =>
      _BannerManagementTabState();
}

class _BannerManagementTabState extends ConsumerState<_BannerManagementTab> {
  List<BannerItem>? _localBanners;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final cmsAsync = ref.watch(cmsHomepageProvider);

    return cmsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('讀取失敗：$err')),
      data: (cms) {
        // 首次載入時同步本地狀態
        final banners = _localBanners ?? cms?.banners ?? [];

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: banners.isEmpty
                      ? const _EmptyBannerPlaceholder()
                      : ReorderableListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: banners.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              final list = List<BannerItem>.from(banners);
                              if (newIndex > oldIndex) newIndex--;
                              final item = list.removeAt(oldIndex);
                              list.insert(newIndex, item);
                              _localBanners = list;
                            });
                          },
                          itemBuilder: (context, index) {
                            final banner = banners[index];
                            return _BannerListTile(
                              key: ValueKey(banner.id),
                              banner: banner,
                              onDelete: () => _deleteBanner(banners, index),
                            );
                          },
                        ),
                ),
                _BannerActionBar(
                  isSaving: _isSaving,
                  onAdd: () => _showAddBannerDialog(context, banners),
                  onSave: banners.isEmpty
                      ? null
                      : () => _saveBanners(context, banners),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _deleteBanner(List<BannerItem> banners, int index) {
    setState(() {
      final list = List<BannerItem>.from(banners);
      list.removeAt(index);
      _localBanners = list;
    });
  }

  Future<void> _showAddBannerDialog(
    BuildContext context,
    List<BannerItem> currentBanners,
  ) async {
    final result = await showDialog<BannerItem>(
      context: context,
      builder: (_) => const _AddBannerDialog(),
    );
    if (result != null) {
      setState(() {
        _localBanners = [...currentBanners, result];
      });
    }
  }

  Future<void> _saveBanners(
    BuildContext context,
    List<BannerItem> banners,
  ) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(adminGuardProvider.future);
      final repo = CmsAdminRepository();
      await repo.updateBanners(banners);
      // 儲存成功後清除本地狀態，讓 StreamProvider 接管
      setState(() => _localBanners = null);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner 已儲存')),
        );
      }
    } on UnauthorizedException catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.message);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, '儲存失敗：$e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

// ── _BannerListTile ───────────────────────────────────────────────────────────

class _BannerListTile extends StatelessWidget {
  const _BannerListTile({
    super.key,
    required this.banner,
    required this.onDelete,
  });

  final BannerItem banner;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: _kThumbnailSize,
            height: _kThumbnailSize,
            child: banner.imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: banner.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const _ImageErrorPlaceholder(),
                  )
                : const _ImageErrorPlaceholder(),
          ),
        ),
        title: Text(
          banner.title ?? '（無標題）',
          style: theme.textTheme.bodyLarge,
        ),
        subtitle: banner.linkUrl != null
            ? Text(
                banner.linkUrl!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_handle,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.delete_outline,
                  color: theme.colorScheme.error),
              onPressed: onDelete,
              tooltip: '刪除',
            ),
          ],
        ),
      ),
    );
  }
}

// ── _BannerActionBar ──────────────────────────────────────────────────────────

class _BannerActionBar extends StatelessWidget {
  const _BannerActionBar({
    required this.isSaving,
    required this.onAdd,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onAdd;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          OutlinedButton.icon(
            onPressed: isSaving ? null : onAdd,
            icon: const Icon(Icons.add),
            label: const Text('新增 Banner'),
          ),
          FilledButton.icon(
            onPressed: isSaving ? null : onSave,
            icon: isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

// ── _EmptyBannerPlaceholder ───────────────────────────────────────────────────

class _EmptyBannerPlaceholder extends StatelessWidget {
  const _EmptyBannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: theme.colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),
          Text(
            '尚無 Banner，點擊「新增 Banner」新增第一張。',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _ImageErrorPlaceholder ────────────────────────────────────────────────────

class _ImageErrorPlaceholder extends StatelessWidget {
  const _ImageErrorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.broken_image_outlined,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

// ── _AddBannerDialog ──────────────────────────────────────────────────────────

class _AddBannerDialog extends ConsumerStatefulWidget {
  const _AddBannerDialog();

  @override
  ConsumerState<_AddBannerDialog> createState() => _AddBannerDialogState();
}

class _AddBannerDialogState extends ConsumerState<_AddBannerDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();

  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('新增 Banner'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 圖片選擇區
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: _pickedBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _pickedBytes!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '點擊上傳圖片',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '標題',
                  hintText: '例：夏季水蜜桃特賣',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '請填寫標題' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: '連結 URL（選填）',
                  hintText: '例：/products/peach',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _isUploading ? null : _submit,
          child: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('確認新增'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _pickedBytes = file.bytes;
          _pickedFileName = file.name;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇一張圖片')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await ref.read(adminGuardProvider.future);

      final repo = CmsAdminRepository();
      final fileName = '${const Uuid().v4()}_${_pickedFileName!}';
      final downloadUrl = await repo.uploadImage(_pickedBytes!, fileName);

      final newBanner = BannerItem(
        id: const Uuid().v4(),
        imageUrl: downloadUrl,
        title: _titleController.text.trim(),
        linkUrl: _linkController.text.trim().isEmpty
            ? null
            : _linkController.text.trim(),
        sortOrder: 0,
        isActive: true,
      );

      if (mounted) Navigator.of(context).pop(newBanner);
    } on UnauthorizedException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上傳失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 品牌故事 Tab
// ═══════════════════════════════════════════════════════════════════════════════

class _BrandStoryTab extends ConsumerStatefulWidget {
  const _BrandStoryTab();

  @override
  ConsumerState<_BrandStoryTab> createState() => _BrandStoryTabState();
}

class _BrandStoryTabState extends ConsumerState<_BrandStoryTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _initialized = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cmsAsync = ref.watch(cmsHomepageProvider);

    return cmsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('讀取失敗：$err')),
      data: (cms) {
        // 首次載入時填入初始值
        if (!_initialized && cms != null) {
          _titleController.text = cms.brandStoryTitle;
          _contentController.text = cms.brandStoryContent;
          _imageUrlController.text = cms.brandStoryImageUrl;
          _initialized = true;
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kContentMaxWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '品牌故事標題',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '請填寫標題' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        labelText: '品牌故事內文',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      minLines: 5,
                      maxLines: null,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? '請填寫內文' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _imageUrlController,
                            decoration: const InputDecoration(
                              labelText: '圖片 URL',
                              hintText: 'https://...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _UploadImageButton(
                          isUploading: _isUploadingImage,
                          onUpload: _uploadBrandStoryImage,
                        ),
                      ],
                    ),
                    // 圖片預覽
                    if (_imageUrlController.text.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _ImagePreview(
                        imageUrl: _imageUrlController.text,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('儲存品牌故事'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadBrandStoryImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _isUploadingImage = true);
    try {
      await ref.read(adminGuardProvider.future);
      final repo = CmsAdminRepository();
      final fileName = '${const Uuid().v4()}_${file.name}';
      final url = await repo.uploadImage(file.bytes!, fileName);
      setState(() {
        _imageUrlController.text = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上傳失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(adminGuardProvider.future);
      final repo = CmsAdminRepository();
      await repo.updateBrandStory(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('品牌故事已儲存')),
        );
      }
    } on UnauthorizedException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('儲存失敗：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

// ── _UploadImageButton ────────────────────────────────────────────────────────

class _UploadImageButton extends StatelessWidget {
  const _UploadImageButton({
    required this.isUploading,
    required this.onUpload,
  });

  final bool isUploading;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: isUploading ? null : onUpload,
        icon: isUploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.upload_outlined),
        label: const Text('上傳'),
      ),
    );
  }
}

// ── _ImagePreview ─────────────────────────────────────────────────────────────

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 240),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorWidget: (_, __, ___) => Container(
            height: 120,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Text(
                '無法預覽圖片',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
