import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:icon_decoration/icon_decoration.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/repositories/animal_card_repository.dart';
import 'package:shelter_partner/view_models/animal_card_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/views/components/add_log_view.dart';
import 'package:shelter_partner/views/components/add_note_view.dart';
import 'package:shelter_partner/views/components/put_back_confirmation_view.dart';
import 'package:shelter_partner/views/components/take_out_confirmation_view.dart';

/// Helper method to calculate time ago from a given DateTime.
String _timeAgo(DateTime dateTime, bool inKennel) {
  final Duration difference = DateTime.now().difference(dateTime);

  if (difference.inDays > 8) {
    return '${(difference.inDays / 7).floor()} weeks${inKennel ? ' ago' : ''}';
  } else if (difference.inDays >= 1) {
    final dayLabel = difference.inDays == 1 ? 'day' : 'days';
    return '${difference.inDays} $dayLabel${inKennel ? ' ago' : ''}';
  } else if (difference.inHours >= 1) {
    return '${difference.inHours} hours${inKennel ? ' ago' : ''}';
  } else if (difference.inMinutes >= 1) {
    return '${difference.inMinutes} minutes${inKennel ? ' ago' : ''}';
  } else {
    return inKennel ? 'Just now' : '0 minutes';
  }
}

class AnimalCardView extends ConsumerStatefulWidget {
  final Animal animal;
  final int maxLocationTiers;

  const AnimalCardView({
    super.key,
    required this.animal,
    required this.maxLocationTiers,
  });

  @override
  AnimalCardViewState createState() => AnimalCardViewState();
}

class AnimalCardViewState extends ConsumerState<AnimalCardView> {
  late final LoggerService _logger;
  bool _automaticPutBackHandled = false;

  @override
  void initState() {
    super.initState();
    _logger = ref.read(loggerServiceProvider);

    // Print the account type on appear.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final appUser = ref.read(appUserProvider);
      _logger.info("Account type on appear: ${appUser?.type}");
    });

    // Handle automatic put back after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_automaticPutBackHandled) {
        final shelterDetails = ref.read(shelterDetailsViewModelProvider).value;
        if (shelterDetails != null) {
          final shelterSettings = shelterDetails.shelterSettings;
          final shelterId = shelterDetails.id;
          final animalType = widget.animal.species;
          final repository = ref.read(animalRepositoryProvider);
          final viewModel = AnimalCardViewModel(
            repository: repository,
            shelterId: shelterId,
            animalType: animalType,
            shelterSettings: shelterSettings,
          );
          viewModel.handleAutomaticPutBack(widget.animal);
        }
        _automaticPutBackHandled = true;
      }
    });
  }

  Future<void> _showTakeOutConfirmationDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return TakeOutConfirmationView(animals: [widget.animal]);
      },
    );
  }

  Future<void> showErrorDialog({
    required BuildContext context,
    required String message,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPutBackConfirmationDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return PutBackConfirmationView(animals: [widget.animal]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final animal = widget.animal;
    // Location strings (representing the animal's hierarchical location tiers within the shelter)
    // are accessed directly from the animal model when displaying tooltips and text labels.
    // This approach avoids unnecessary abstraction since the location data is already structured
    // and available, and direct access ensures up-to-date information is shown in the UI.
    final shelterDetailsAsync = ref.watch(shelterDetailsViewModelProvider);
    bool canInteract = false;
    shelterDetailsAsync.when(
      data: (shelter) {
        if (shelter != null && shelter.id.isNotEmpty) {
          canInteract = true;
        }
      },
      loading: () {
        canInteract = false;
      },
      error: (error, stack) {
        canInteract = false;
      },
    );

    return Card(
      color: animal.inKennel
          ? Colors.lightBlue.shade100
          : Colors.orange.shade100,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      shadowColor: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Icon, Name, and Menu
          Padding(
            padding: const EdgeInsets.fromLTRB(12.0, 12.0, 12.0, 4.0),
            child: Row(
              children: [
                _buildIcon(animal.symbol, animal.symbolColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    animal.name,
                    style: const TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                PopupMenuButton<String>(
                  offset: const Offset(0, 40),
                  onSelected: (value) {
                    switch (value) {
                      case 'Details':
                        context.push('/enrichment/details', extra: animal);
                        break;
                      case 'Add Note':
                        showDialog(
                          context: context,
                          builder: (context) => AddNoteView(animal: animal),
                        );
                        break;
                      case 'Add Log':
                        showDialog(
                          context: context,
                          builder: (context) => AddLogView(animal: animal),
                        );
                        break;
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    final appUser = ref.read(appUserProvider);
                    final accountSettings = ref
                        .read(accountSettingsViewModelProvider)
                        .value;
                    final menuItems = {'Details', 'Add Note'};
                    if (appUser?.type == "admin" &&
                        accountSettings!.accountSettings?.mode == "Admin" &&
                        animal.inKennel) {
                      menuItems.add('Add Log');
                    }

                    return menuItems.map((String choice) {
                      return PopupMenuItem<String>(
                        value: choice,
                        child: Text(choice),
                      );
                    }).toList();
                  },
                  icon: const Icon(Icons.more_vert, size: 20),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Large Image Section - rectangular, non-interactive, edge-to-edge
          _buildAnimalImage(animal, ref),
          const SizedBox(height: 10),
          // Location and Time Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Location
                Flexible(
                  child: Tooltip(
                    triggerMode: TooltipTriggerMode.tap,
                    message: animal.location.isNotEmpty
                        ? animal.fullLocation
                        : (animal.locationTiers.isNotEmpty
                              ? animal.locationTiers.join(' > ')
                              : 'No location'),
                    preferBelow: false,
                    showDuration: const Duration(seconds: 3),
                    child: Text(
                      animal.location.isNotEmpty
                          ? animal.location
                          : (animal.locationTiers.isNotEmpty
                                ? animal.locationTiers.last
                                : ''),
                      style: const TextStyle(
                        fontSize: 25.0,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                // Time Badge
                if (animal.logs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 4,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 12),
                        const SizedBox(width: 3),
                        Text(
                          _timeAgo(
                            widget.animal.inKennel
                                ? animal.logs.last.endTime.toDate()
                                : animal.logs.last.startTime.toDate(),
                            widget.animal.inKennel,
                          ),
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Tags Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    // Location tiers
                    if (animal.locationTiers.isNotEmpty)
                      for (var tier in animal.locationTiers.sublist(
                        animal.locationTiers.length > widget.maxLocationTiers
                            ? animal.locationTiers.length -
                                  widget.maxLocationTiers
                            : 0,
                      ))
                        _buildTagChip(label: tier),
                    // Categories
                    if (animal.adoptionCategory.isNotEmpty)
                      _buildTagChip(label: animal.adoptionCategory),
                    if (animal.behaviorCategory.isNotEmpty)
                      _buildTagChip(label: animal.behaviorCategory),
                    if (animal.locationCategory.isNotEmpty)
                      _buildTagChip(label: animal.locationCategory),
                    if (animal.medicalCategory.isNotEmpty)
                      _buildTagChip(label: animal.medicalCategory),
                    if (animal.volunteerCategory.isNotEmpty)
                      _buildTagChip(label: animal.volunteerCategory),
                    // Top 3 tags
                    for (var tag
                        in (animal.tags
                              ..sort((a, b) => b.count.compareTo(a.count)))
                            .take(3))
                      _buildTagChip(label: tag.title),
                  ],
                ),
              ],
            ),
          ),
          // Spacer to push button to bottom
          const Spacer(),
          // Let Out Button - sticks to the bottom of the card
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: canInteract
                  ? () {
                      // Show confirmation dialog
                      if (animal.inKennel) {
                        _showTakeOutConfirmationDialog();
                      } else {
                        _showPutBackConfirmationDialog();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    animal.inKennel ? 'Let Out' : 'Put Back',
                    style: const TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward, size: 14),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds a tag chip for the Tags section.
/// If the [label] is "Unknown" (ignoring case and whitespace), nothing is rendered.
Widget _buildTagChip({required String label}) {
  if (label.trim().toLowerCase() == 'unknown') {
    return const SizedBox.shrink();
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.10),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 9.0,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
    ),
  );
}

/// Builds the rectangular animal image - edge to edge with no rounded corners
Widget _buildAnimalImage(Animal animal, WidgetRef ref) {
  final serviceUrls = ref.watch(serviceUrlsProvider);
  return Container(
    width: double.infinity,
    height: 120,
    color: Colors.grey.shade200,
    child: animal.photos?.isNotEmpty ?? false
        ? CachedNetworkImage(
            imageUrl: serviceUrls.corsImageUrl(animal.photos?.first.url ?? ''),
            cacheKey: animal.photos?.first.url,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
            ),
          )
        : Center(
            child: Icon(Icons.pets, size: 40, color: Colors.grey.shade400),
          ),
  );
}

Widget _buildIcon(String symbol, String symbolColor) {
  IconData? iconData;

  switch (symbol) {
    case 'pets':
      iconData = Icons.pets;
      break;
    case 'location_on':
      iconData = Icons.location_on;
      break;
    case 'star':
      iconData = Icons.star;
      break;
    default:
      return const SizedBox.shrink(); // No icon for default case
  }

  return DecoratedIcon(
    icon: Icon(iconData, color: _parseColor(symbolColor), size: 20),
    // decoration: const IconDecoration(
    //   border: IconBorder(
    //     color: Colors.black,
    //     width: 0.75,
    //   )
    // ),
  );
}

/// Parses a color string into a [Color] value.
Color _parseColor(String colorString) {
  switch (colorString.toLowerCase()) {
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'green':
      return Colors.green;
    case 'yellow':
      return Colors.yellow;
    case 'orange':
      return Colors.orange;
    case 'purple':
      return Colors.purple;
    case 'pink':
      return Colors.pink;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
    default:
      return Colors.transparent;
  }
}
