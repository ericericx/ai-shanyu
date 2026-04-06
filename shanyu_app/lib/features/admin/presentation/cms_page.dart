import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../home/models/cms_models.dart';
import '../../home/providers/cms_providers.dart';
import '../../products/providers/product_providers.dart';
import '../data/cms_admin_repository.dart';
import '../providers/admin_providers.dart';

// ── 常數 ──────────────────────────────────────────────────────────────────────

const _kContentMaxWidth = 900.0;

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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: banners.length,
                          itemBuilder: (context, index) {
                            return _BannerListTile(
                              key: ValueKey(banners[index].id),
                              banner: banners[index],
                              isFirst: index == 0,
                              isLast: index == banners.length - 1,
                              onMoveUp: () => _swapBanners(banners, index, index - 1),
                              onMoveDown: () => _swapBanners(banners, index, index + 1),
                              onEdit: () => _showEditBannerDialog(context, banners, index),
                              onDelete: () => _deleteBanner(context, banners, index),
                            );
                          },
                        ),
                ),
                _BannerActionBar(
                  isSaving: _isSaving,
                  onAdd: () => _showAddBannerDialog(context, banners),
                  onSave: _localBanners != null
                      ? () => _saveBanners(context, banners)
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteBanner(
    BuildContext context,
    List<BannerItem> banners,
    int index,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確認刪除'),
        content: Text('確定要刪除「${banners[index].title ?? '此 Banner'}」嗎？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        final list = List<BannerItem>.from(banners);
        list.removeAt(index);
        _localBanners = list;
      });
    }
  }

  void _swapBanners(List<BannerItem> banners, int from, int to) {
    setState(() {
      final list = List<BannerItem>.from(banners);
      final item = list.removeAt(from);
      list.insert(to, item);
      _localBanners = list;
    });
  }

  Future<void> _showAddBannerDialog(
    BuildContext context,
    List<BannerItem> currentBanners,
  ) async {
    final result = await showDialog<BannerItem>(
      context: context,
      builder: (_) => const _BannerFormDialog(),
    );
    if (result != null) {
      setState(() {
        _localBanners = [...currentBanners, result];
      });
    }
  }

  Future<void> _showEditBannerDialog(
    BuildContext context,
    List<BannerItem> currentBanners,
    int index,
  ) async {
    final result = await showDialog<BannerItem>(
      context: context,
      builder: (_) => _BannerFormDialog(existing: currentBanners[index]),
    );
    if (result != null) {
      setState(() {
        final list = List<BannerItem>.from(currentBanners);
        list[index] = result;
        _localBanners = list;
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

class _BannerListTile extends ConsumerWidget {
  const _BannerListTile({
    super.key,
    required this.banner,
    required this.isFirst,
    required this.isLast,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onEdit,
    required this.onDelete,
  });

  final BannerItem banner;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 左側：寬幅圖片預覽 + 標題
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2.5,
                    child: banner.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: banner.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                const _ImageErrorPlaceholder(),
                          )
                        : const _ImageErrorPlaceholder(),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.title ?? '（無標題）',
                          style: theme.textTheme.bodyLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        _BannerLinkLabel(
                          linkUrl: banner.linkUrl,
                          ref: ref,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 右側：工具欄（上移 / 下移 / 刪除）
            Container(
              width: 48,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    onPressed: isFirst ? null : onMoveUp,
                    tooltip: '上移',
                    iconSize: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    onPressed: isLast ? null : onMoveDown,
                    tooltip: '下移',
                    iconSize: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: onEdit,
                    tooltip: '編輯',
                    iconSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: theme.colorScheme.error),
                    onPressed: onDelete,
                    tooltip: '刪除',
                    iconSize: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _BannerLinkLabel（解析 linkUrl 顯示可讀標籤）────────────────────────────

class _BannerLinkLabel extends StatelessWidget {
  const _BannerLinkLabel({required this.linkUrl, required this.ref});

  final String? linkUrl;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.primary,
    );

    if (linkUrl == null || linkUrl!.isEmpty) {
      return Text('無連結', style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ));
    }

    // /products/:catId/:prodId
    final productMatch =
        RegExp(r'^/products/([^/]+)/([^/]+)$').firstMatch(linkUrl!);
    if (productMatch != null) {
      final catId = productMatch.group(1)!;
      final prodId = productMatch.group(2)!;
      final productsAsync = ref.watch(productsByCategoryProvider(catId));
      final productName = productsAsync.valueOrNull
          ?.where((p) => p.id == prodId)
          .firstOrNull
          ?.name;
      return Text(
        '導連商品：${productName ?? '載入中...'}',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // /products/:catId
    final categoryMatch =
        RegExp(r'^/products/([^/]+)$').firstMatch(linkUrl!);
    if (categoryMatch != null) {
      final catId = categoryMatch.group(1)!;
      final categoriesAsync = ref.watch(categoriesProvider);
      final catName = categoriesAsync.valueOrNull
          ?.where((c) => c.id == catId)
          .firstOrNull
          ?.name;
      return Text(
        '導連分類：${catName ?? '載入中...'}',
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // 外部 URL
    return Text(
      '網址：$linkUrl',
      style: style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

// ── Banner 連結類型 ──────────────────────────────────────────────────────────

enum _BannerLinkType { none, url, category, product }

// ── _BannerFormDialog（新增 / 編輯共用）────────────────────────────────────────

class _BannerFormDialog extends ConsumerStatefulWidget {
  const _BannerFormDialog({this.existing});

  /// 傳入既有 Banner 即為編輯模式，null 為新增模式。
  final BannerItem? existing;

  @override
  ConsumerState<_BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends ConsumerState<_BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();

  Uint8List? _pickedBytes;
  String? _pickedFileName;
  bool _isUploading = false;
  double _uploadProgress = 0;

  _BannerLinkType _linkType = _BannerLinkType.none;
  String? _selectedCategoryId;
  String? _selectedProductId;
  String? _productCategoryId; // 商品所屬分類（用於組路由）

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.existing!.title ?? '';
      _initLinkType(widget.existing!.linkUrl);
    }
  }

  void _initLinkType(String? url) {
    if (url == null || url.isEmpty) {
      _linkType = _BannerLinkType.none;
      return;
    }
    // /products/:catId/:prodId
    final productMatch = RegExp(r'^/products/([^/]+)/([^/]+)$').firstMatch(url);
    if (productMatch != null) {
      _linkType = _BannerLinkType.product;
      _productCategoryId = productMatch.group(1);
      _selectedProductId = productMatch.group(2);
      return;
    }
    // /products/:catId
    final categoryMatch = RegExp(r'^/products/([^/]+)$').firstMatch(url);
    if (categoryMatch != null) {
      _linkType = _BannerLinkType.category;
      _selectedCategoryId = categoryMatch.group(1);
      return;
    }
    _linkType = _BannerLinkType.url;
    _linkController.text = url;
  }

  String? get _resolvedLinkUrl {
    switch (_linkType) {
      case _BannerLinkType.none:
        return null;
      case _BannerLinkType.url:
        final text = _linkController.text.trim();
        return text.isEmpty ? null : text;
      case _BannerLinkType.category:
        return _selectedCategoryId != null
            ? '/products/$_selectedCategoryId'
            : null;
      case _BannerLinkType.product:
        return _selectedProductId != null && _productCategoryId != null
            ? '/products/$_productCategoryId/$_selectedProductId'
            : null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return AlertDialog(
      title: Text(_isEditing ? '編輯 Banner' : '新增 Banner'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 圖片選擇區（5:2 比例預覽框）
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AspectRatio(
                    aspectRatio: 2.5,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _pickedBytes != null
                            ? Image.memory(
                                _pickedBytes!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              )
                            : _isEditing && widget.existing!.imageUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.existing!.imageUrl,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) =>
                                        const _ImageErrorPlaceholder(),
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
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '建議比例 5:2（例如 1440×576 px）',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_pickedBytes != null || (_isEditing && widget.existing!.imageUrl.isNotEmpty))
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isUploading ? null : _pickImage,
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('更換圖片'),
                    style: TextButton.styleFrom(
                      textStyle: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),

              // ── 連結類型選擇 ──
              Text('點擊連結', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<_BannerLinkType>(
                segments: const [
                  ButtonSegment(
                    value: _BannerLinkType.none,
                    label: Text('無'),
                    icon: Icon(Icons.block, size: 16),
                  ),
                  ButtonSegment(
                    value: _BannerLinkType.category,
                    label: Text('分類'),
                    icon: Icon(Icons.category_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: _BannerLinkType.product,
                    label: Text('商品'),
                    icon: Icon(Icons.shopping_bag_outlined, size: 16),
                  ),
                  ButtonSegment(
                    value: _BannerLinkType.url,
                    label: Text('自訂'),
                    icon: Icon(Icons.link, size: 16),
                  ),
                ],
                selected: {_linkType},
                onSelectionChanged: (v) => setState(() {
                  _linkType = v.first;
                }),
              ),
              const SizedBox(height: 12),

              // ── 依類型顯示對應欄位 ──
              if (_linkType == _BannerLinkType.url)
                TextFormField(
                  controller: _linkController,
                  decoration: const InputDecoration(
                    labelText: '連結 URL',
                    hintText: '例：https://example.com',
                    border: OutlineInputBorder(),
                  ),
                ),
              if (_linkType == _BannerLinkType.category)
                categoriesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('無法載入分類'),
                  data: (categories) => DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: '選擇分類',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                    validator: (v) => v == null ? '請選擇分類' : null,
                  ),
                ),
              if (_linkType == _BannerLinkType.product)
                _AllProductsDropdown(
                  selectedCategoryId: _productCategoryId,
                  selectedProductId: _selectedProductId,
                  onChanged: (catId, prodId) => setState(() {
                    _productCategoryId = catId;
                    _selectedProductId = prodId;
                  }),
                ),
            ],
          ),
        ),
      ),
      actions: _isUploading
          ? [
              SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(value: _uploadProgress),
                    const SizedBox(height: 4),
                    Text(
                      '上傳中 ${(_uploadProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ]
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: _submit,
                child: Text(_isEditing ? '儲存變更' : '確認新增'),
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

    // 新增模式必須選圖；編輯模式可沿用原圖
    if (_pickedBytes == null && !_isEditing) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('請先選擇一張圖片')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await ref.read(adminGuardProvider.future);

      String imageUrl;
      if (_pickedBytes != null) {
        final repo = CmsAdminRepository();
        final fileName = '${const Uuid().v4()}_${_pickedFileName!}';
        imageUrl = await repo.uploadImage(
          _pickedBytes!,
          fileName,
          onProgress: (p) {
            if (mounted) setState(() => _uploadProgress = p);
          },
        );
      } else {
        imageUrl = widget.existing!.imageUrl;
      }

      final banner = BannerItem(
        id: _isEditing ? widget.existing!.id : const Uuid().v4(),
        imageUrl: imageUrl,
        title: _titleController.text.trim(),
        linkUrl: _resolvedLinkUrl,
        sortOrder: _isEditing ? widget.existing!.sortOrder : 0,
        isActive: _isEditing ? widget.existing!.isActive : true,
      );

      if (mounted) Navigator.of(context).pop(banner);
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

// ── _AllProductsDropdown（所有商品扁平下拉，依分類分組）────────────────────────

class _AllProductsDropdown extends ConsumerWidget {
  const _AllProductsDropdown({
    required this.selectedCategoryId,
    required this.selectedProductId,
    required this.onChanged,
  });

  final String? selectedCategoryId;
  final String? selectedProductId;
  final void Function(String categoryId, String productId) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return categoriesAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const Text('無法載入商品'),
      data: (categories) {
        // 為每個分類載入商品
        final allItems = <DropdownMenuItem<String>>[];
        final productCategoryMap = <String, String>{}; // prodId → catId

        for (final cat in categories) {
          final productsAsync =
              ref.watch(productsByCategoryProvider(cat.id));
          final products = productsAsync.valueOrNull ?? [];

          if (products.isEmpty) continue;

          // 分類標題（不可選）
          allItems.add(DropdownMenuItem<String>(
            enabled: false,
            value: '_header_${cat.id}',
            child: Text(
              cat.name,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ));

          for (final p in products) {
            productCategoryMap[p.id] = cat.id;
            allItems.add(DropdownMenuItem<String>(
              value: p.id,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(p.name),
              ),
            ));
          }
        }

        if (allItems.isEmpty) {
          return const Text('尚無商品');
        }

        // 確認 selectedProductId 存在於選項中
        final validValue = productCategoryMap.containsKey(selectedProductId)
            ? selectedProductId
            : null;

        return DropdownButtonFormField<String>(
          initialValue: validValue,
          decoration: const InputDecoration(
            labelText: '選擇商品',
            border: OutlineInputBorder(),
          ),
          items: allItems,
          onChanged: (prodId) {
            if (prodId == null) return;
            final catId = productCategoryMap[prodId];
            if (catId != null) onChanged(catId, prodId);
          },
          validator: (v) =>
              v == null || v.startsWith('_header_') ? '請選擇商品' : null,
        );
      },
    );
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

  // 追蹤原始值以判斷是否有變更
  String _originalTitle = '';
  String _originalContent = '';
  String _originalImageUrl = '';
  bool _isDirty = false;

  void _checkDirty() {
    final dirty = _titleController.text != _originalTitle ||
        _contentController.text != _originalContent ||
        _imageUrlController.text != _originalImageUrl;
    if (dirty != _isDirty) {
      setState(() => _isDirty = dirty);
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkDirty);
    _contentController.removeListener(_checkDirty);
    _imageUrlController.removeListener(_checkDirty);
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
        // 首次載入時填入初始值並記錄原始值
        if (!_initialized && cms != null) {
          _titleController.text = cms.brandStoryTitle;
          _contentController.text = cms.brandStoryContent;
          _imageUrlController.text = cms.brandStoryImageUrl;
          _originalTitle = cms.brandStoryTitle;
          _originalContent = cms.brandStoryContent;
          _originalImageUrl = cms.brandStoryImageUrl;
          _titleController.addListener(_checkDirty);
          _contentController.addListener(_checkDirty);
          _imageUrlController.addListener(_checkDirty);
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
                              helperText: '建議比例 4:3（例如 800×600 px）',
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
                      onPressed: _isSaving || !_isDirty ? null : _save,
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
        // 儲存成功後更新原始值，重置 dirty 狀態
        _originalTitle = _titleController.text.trim();
        _originalContent = _contentController.text.trim();
        _originalImageUrl = _imageUrlController.text.trim();
        _isDirty = false;
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
