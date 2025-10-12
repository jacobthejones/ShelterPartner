import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/photo.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/edit_animal_view_model.dart';
import 'package:shelter_partner/views/components/add_log_view.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
import 'package:shelter_partner/views/components/logs_view.dart';
import 'package:shelter_partner/views/components/notes_view.dart';
import 'package:photo_view/photo_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EnrichmentAnimalDetailPage extends ConsumerWidget {
  final Animal initialAnimal;
  final bool visitorPage;

  const EnrichmentAnimalDetailPage({
    super.key,
    required this.initialAnimal,
    required this.visitorPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint(
      '[EnrichmentAnimalDetailPage] build called for animal: ${initialAnimal.id}',
    );
    final serviceUrls = ref.watch(serviceUrlsProvider);
    // Cache the animal and get its provider using the ID
    cacheAnimal(initialAnimal);
    final animal = ref.watch(editAnimalViewModelProvider(initialAnimal.id));
    final appUser = ref.read(appUserProvider);
    final accountSettings = ref.watch(accountSettingsViewModelProvider);

    bool isAdmin() {
      // Replace with actual logic to check if the user is an admin
      return appUser?.type == "admin" &&
          accountSettings.value!.accountSettings?.mode == "Admin";
    }

    String formatAge(int monthsOld) {
      int years = monthsOld ~/ 12;
      int months = monthsOld % 12;
      String yearsText = years > 0 ? '$years year${years > 1 ? 's' : ''}' : '';
      String monthsText = months > 0
          ? '$months month${months > 1 ? 's' : ''}'
          : '';
      if (yearsText.isNotEmpty && monthsText.isNotEmpty) {
        return '$yearsText and $monthsText';
      } else {
        return yearsText.isNotEmpty ? yearsText : monthsText;
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(animal.name)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 1200;
          if (isWideScreen) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoSection(
                          context,
                          animal,
                          ref,
                          appUser,
                          isAdmin,
                          serviceUrls,
                        ),
                        const SizedBox(height: 24.0),
                        _buildDetailsSection(context, animal, formatAge),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24.0),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTagsSection(
                          context,
                          animal,
                          ref,
                          appUser,
                          isAdmin,
                        ),
                        const SizedBox(height: 24.0),
                        _buildAlertsSection(context, animal, isAdmin()),
                        const SizedBox(height: 24.0),
                        _buildNotesSection(
                          context,
                          animal,
                          ref,
                          appUser,
                          isAdmin,
                        ),
                        if (!visitorPage) ...[
                          const SizedBox(height: 24.0),
                          _buildLogsSection(
                            context,
                            animal,
                            ref,
                            appUser,
                            isAdmin,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPhotoSection(
                    context,
                    animal,
                    ref,
                    appUser,
                    isAdmin,
                    serviceUrls,
                  ),
                  const SizedBox(height: 16.0),
                  _buildTagsSection(context, animal, ref, appUser, isAdmin),
                  const SizedBox(height: 16.0),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      animal.description,
                      style: const TextStyle(fontSize: 15.0),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  _buildDetailsSection(context, animal, formatAge),
                  const SizedBox(height: 24.0),
                  _buildAlertsSection(context, animal, isAdmin()),
                  const SizedBox(height: 24.0),
                  _buildNotesSection(context, animal, ref, appUser, isAdmin),
                  if (!visitorPage) ...[
                    const SizedBox(height: 24.0),
                    _buildLogsSection(context, animal, ref, appUser, isAdmin),
                  ],
                ],
              ),
            );
          }
        },
      ),
    );
  }

  // --- Helper methods ---

  Widget _buildPhotoSection(
    BuildContext context,
    Animal animal,
    WidgetRef ref,
    dynamic appUser,
    bool Function() isAdmin,
    dynamic serviceUrls,
  ) {
    return SizedBox(
      height: 220.0,
      child: (animal.photos?.isNotEmpty ?? false)
          ? PhotoList(
              photos: animal.photos ?? [],
              isAdmin: isAdmin(),
              onDelete: (photoId) {
                ref
                    .read(editAnimalViewModelProvider(animal.id).notifier)
                    .deleteItemOptimistically(
                      appUser!.shelterId,
                      animal.species,
                      animal.id,
                      'photos',
                      photoId,
                    );
              },
              onPhotoTap: (index) {
                showFullScreenGallery(
                  context,
                  animal.photos!.map((p) => p.url).toList(),
                  index,
                );
              },
            )
          : const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No photos available',
                style: TextStyle(color: Colors.grey),
              ),
            ),
    );
  }

  Widget _buildTagsSection(
    BuildContext context,
    Animal animal,
    WidgetRef ref,
    dynamic appUser,
    bool Function() isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tags', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        animal.tags.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: animal.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.label,
                            size: 16,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            tag.title,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (tag.count > 1) ...[
                            const SizedBox(width: 4.0),
                            Text(
                              '(${tag.count})',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                          if (isAdmin()) ...[
                            const SizedBox(width: 8.0),
                            GestureDetector(
                              onTap: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: Text(
                                      'Are you sure you want to delete the tag "${tag.title}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (shouldDelete == true) {
                                  ref
                                      .read(
                                        editAnimalViewModelProvider(
                                          animal.id,
                                        ).notifier,
                                      )
                                      .deleteItemOptimistically(
                                        appUser!.shelterId,
                                        animal.species,
                                        animal.id,
                                        'tags',
                                        tag.id,
                                      );
                                }
                              },
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              )
            : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No tags available',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
      ],
    );
  }

  Widget _buildDetailsSection(
    BuildContext context,
    Animal animal,
    String Function(int) formatAge,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Details', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildDetailRow('Age', formatAge(animal.monthsOld)),
                const Divider(height: 20),
                _buildDetailRow('Sex', animal.sex == "m" ? "Male" : "Female"),
                const Divider(height: 20),
                _buildDetailRow('Breed', animal.breed),
                const Divider(height: 20),
                _buildDetailRow('Species', animal.species.toUpperCase()),
                const Divider(height: 20),
                _buildDetailRow('Location', animal.location),
                if (animal.description.isNotEmpty) ...[
                  const Divider(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 14.0,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        animal.description,
                        style: const TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 14.0,
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 16.0))),
      ],
    );
  }

  Widget _buildAlertsSection(
    BuildContext context,
    Animal animal,
    bool isAdmin,
  ) {
    final hasAlerts =
        animal.takeOutAlert.isNotEmpty && animal.takeOutAlert != 'Unknown' ||
        animal.putBackAlert.isNotEmpty && animal.putBackAlert != 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alerts', style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        hasAlerts
            ? Column(
                children: [
                  if (animal.takeOutAlert.isNotEmpty &&
                      animal.takeOutAlert != 'Unknown')
                    Card(
                      color: Colors.orange.shade50,
                      child: ListTile(
                        leading: Icon(
                          Icons.warning,
                          color: Colors.orange.shade600,
                        ),
                        title: const Text(
                          'Take Out Alert',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(animal.takeOutAlert),
                      ),
                    ),
                  if (animal.putBackAlert.isNotEmpty &&
                      animal.putBackAlert != 'Unknown')
                    Card(
                      color: Colors.red.shade50,
                      child: ListTile(
                        leading: Icon(Icons.error, color: Colors.red.shade600),
                        title: const Text(
                          'Put Back Alert',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(animal.putBackAlert),
                      ),
                    ),
                ],
              )
            : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No alerts', style: TextStyle(color: Colors.grey)),
              ),
      ],
    );
  }

  Widget _buildNotesSection(
    BuildContext context,
    Animal animal,
    WidgetRef ref,
    dynamic appUser,
    bool Function() isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddNoteView(animal: animal),
                );
              },
              icon: const Icon(Icons.add),
              tooltip: 'Add Note',
            ),
          ],
        ),
        const Divider(),
        NotesWidget(
          notes: animal.notes,
          isAdmin: isAdmin(),
          onDelete: (String noteId) {
            ref
                .read(editAnimalViewModelProvider(animal.id).notifier)
                .deleteItemOptimistically(
                  appUser!.shelterId,
                  animal.species,
                  animal.id,
                  'notes',
                  noteId,
                );
          },
        ),
      ],
    );
  }

  Widget _buildLogsSection(
    BuildContext context,
    Animal animal,
    WidgetRef ref,
    dynamic appUser,
    bool Function() isAdmin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Logs', style: Theme.of(context).textTheme.titleLarge),
            if (isAdmin())
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddLogView(animal: animal),
                  );
                },
                icon: const Icon(Icons.add),
                tooltip: 'Add Log',
              ),
          ],
        ),
        const Divider(),
        LogsWidget(
          logs: animal.logs,
          isAdmin: isAdmin(),
          onDelete: (String logId) {
            ref
                .read(editAnimalViewModelProvider(animal.id).notifier)
                .deleteItemOptimistically(
                  appUser!.shelterId,
                  animal.species,
                  animal.id,
                  'logs',
                  logId,
                );
          },
        ),
      ],
    );
  }

  void showFullScreenGallery(
    BuildContext context,
    List<String> imageUrls,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FullScreenGallery(imageUrls: imageUrls, initialIndex: initialIndex),
      ),
    );
  }
}

class FullScreenGallery extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenGallery({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  FullScreenGalleryState createState() => FullScreenGalleryState();
}

class FullScreenGalleryState extends State<FullScreenGallery> {
  late PageController _pageController;
  late int _currentIndex;
  final _focusNode = FocusNode();

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (kIsWeb) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _previousImage();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _nextImage();
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.pop(context);
      }
    }
  }

  void _previousImage() {
    if (_currentIndex > 0) {
      _currentIndex--;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  void _nextImage() {
    if (_currentIndex < widget.imageUrls.length - 1) {
      _currentIndex++;
      _pageController.animateToPage(
        _currentIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          '${_currentIndex + 1} / ${widget.imageUrls.length}',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: isWeb ? _onKey : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return PhotoView(
                  imageProvider: CachedNetworkImageProvider(
                    widget.imageUrls[index],
                  ),
                  backgroundDecoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                );
              },
            ),
            if (isWeb && widget.imageUrls.length > 1)
              Positioned(
                left: 16.0,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_left,
                    color: Colors.white,
                    size: 48.0,
                  ),
                  onPressed: _previousImage,
                ),
              ),
            if (isWeb && widget.imageUrls.length > 1)
              Positioned(
                right: 16.0,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_right,
                    color: Colors.white,
                    size: 48.0,
                  ),
                  onPressed: _nextImage,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PhotoList extends StatefulWidget {
  final List<Photo> photos;
  final bool isAdmin;
  final Function(String photoId) onDelete;
  final Function(int index) onPhotoTap;

  const PhotoList({
    super.key,
    required this.photos,
    required this.isAdmin,
    required this.onDelete,
    required this.onPhotoTap,
  });

  @override
  PhotoListState createState() => PhotoListState();
}

class PhotoListState extends State<PhotoList> {
  late ScrollController _scrollController;
  double _scrollPosition = 0.0;
  final double _itemWidth = 216.0; // 200 width + 8 padding on each side

  @override
  void initState() {
    _scrollController = ScrollController();
    super.initState();
  }

  void _scrollLeft() {
    _scrollPosition = _scrollController.position.pixels - _itemWidth;
    _scrollController.animateTo(
      _scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollPosition = _scrollController.position.pixels + _itemWidth;
    _scrollController.animateTo(
      _scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    const isWeb = kIsWeb;
    return Stack(
      alignment: Alignment.center,
      children: [
        ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            final photo = widget.photos[index];
            return PhotoItem(
              photo: photo,
              index: index,
              isAdmin: widget.isAdmin,
              onTap: () => widget.onPhotoTap(index),
              onDelete: () => widget.onDelete(photo.id),
            );
          },
        ),
        if (isWeb && widget.photos.length > 1)
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_left, size: 32.0),
              onPressed: _scrollLeft,
            ),
          ),
        if (isWeb && widget.photos.length > 1)
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_right, size: 32.0),
              onPressed: _scrollRight,
            ),
          ),
      ],
    );
  }
}

class PhotoItem extends ConsumerWidget {
  final Photo photo;
  final int index;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const PhotoItem({
    super.key,
    required this.photo,
    required this.index,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceUrls = ref.watch(serviceUrlsProvider);
    final proxyUrl = serviceUrls.corsImageUrl(photo.url);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Stack(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: CachedNetworkImage(
                    imageUrl: proxyUrl,
                    cacheKey: photo.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
          if (isAdmin)
            Positioned(
              top: 4.0,
              right: 4.0,
              child: IconButton(
                icon: Icon(
                  Icons.delete,
                  size: 20.0,
                  color: Colors.red.withValues(alpha: 1),
                ),
                onPressed: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}
