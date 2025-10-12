import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/view_models/add_note_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';

class AddTagView extends ConsumerStatefulWidget {
  final Animal animal;

  const AddTagView({super.key, required this.animal});

  @override
  AddTagViewState createState() => AddTagViewState();
}

class AddTagViewState extends ConsumerState<AddTagView> {
  final TextEditingController _tagController = TextEditingController();
  final Set<String> _selectedTags = {};

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userDetails = ref.read(appUserProvider);
    final shelterSettings = ref.watch(shelterSettingsViewModelProvider);
    final logger = ref.watch(loggerServiceProvider);

    return AlertDialog(
      title: Text('Add Tags - ${widget.animal.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Enter a custom tag...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 16),
                // Predefined tags from shelter settings
                Consumer(
                  builder: (context, watch, child) {
                    final tags = widget.animal.species == 'dog'
                        ? shelterSettings.value?.shelterSettings.dogTags
                        : shelterSettings.value?.shelterSettings.catTags;

                    if (tags == null || tags.isEmpty) {
                      return Container(); // Empty container if no tags
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Predefined Tags:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.0,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: tags.map((tag) {
                            return FilterChip(
                              label: Text(tag),
                              selected: _selectedTags.contains(tag),
                              onSelected: (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Add custom tag if entered
            if (_tagController.text.isNotEmpty) {
              _selectedTags.add(_tagController.text.trim());
            }

            if (_selectedTags.isNotEmpty && userDetails != null) {
              logger.debug('Adding tags: ${_selectedTags.toString()}');

              // Add each selected tag
              for (final tag in _selectedTags) {
                await ref
                    .read(addNoteViewModelProvider(widget.animal).notifier)
                    .updateAnimalTags(widget.animal, [tag]);
              }

              if (!context.mounted) return;
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _selectedTags.length == 1
                        ? 'Tag added successfully'
                        : '${_selectedTags.length} tags added successfully',
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select or enter at least one tag'),
                ),
              );
            }
          },
          child: const Text('Add Tags'),
        ),
      ],
    );
  }
}
