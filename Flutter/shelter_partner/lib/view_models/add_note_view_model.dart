// animal_card_view_model.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shelter_partner/models/animal.dart';
import 'package:shelter_partner/models/note.dart';
import 'package:shelter_partner/repositories/add_note_repository.dart';
import 'package:shelter_partner/view_models/shelter_details_view_model.dart';
import 'package:shelter_partner/view_models/auth_view_model.dart';
import 'package:shelter_partner/view_models/account_settings_view_model.dart';
import 'package:shelter_partner/view_models/shelter_settings_view_model.dart';
import 'package:shelter_partner/view_models/enrichment_view_model.dart';

import 'package:shelter_partner/services/logger_service.dart';
import 'package:shelter_partner/providers/firebase_providers.dart';
import 'package:shelter_partner/view_models/edit_animal_view_model.dart';

class AddNoteViewModel extends StateNotifier<Animal> {
  final AddNoteRepository _repository;
  final Ref ref;
  final LoggerService _logger;

  AddNoteViewModel(this._repository, this.ref, Animal animal)
    : _logger = ref.read(loggerServiceProvider),
      super(animal);

  Future<void> updateAnimalTags(Animal animal, List<String> tags) async {
    try {
      // Get user details
      final userDetails = ref.read(appUserProvider);

      // Check if name is required based on user type
      final accountSettings = ref.read(accountSettingsViewModelProvider);
      final shelterSettings = ref.read(shelterSettingsViewModelProvider);
      final bool requireName = userDetails?.type == "admin"
          ? (accountSettings.value?.accountSettings?.requireName ?? false)
          : (shelterSettings.value?.volunteerSettings.requireName ?? false);

      for (var tag in tags) {
        await _repository.updateAnimalTags(
          animal,
          ref.read(shelterDetailsViewModelProvider).value!.id,
          tag,
          authorName: requireName ? userDetails?.firstName : null,
          authorID: requireName ? userDetails?.id : null,
        );
      }

      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      _logger.error('Failed to add tags', e);
    }
  }

  Future<void> addNoteToAnimal(Animal animal, Note note) async {
    _logger.debug(
      'addNoteToAnimal called with note: ${note.toMap()} for animal: ${animal.id}',
    );
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.addNoteToAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        note,
      );

      // Update the main enrichment view model with the new note
      final enrichmentViewModel = ref.read(
        enrichmentViewModelProvider.notifier,
      );
      final updatedAnimal = animal.copyWith(notes: [...animal.notes, note]);
      enrichmentViewModel.updateAnimalOptimistically(updatedAnimal);

      // Also update the EditAnimalViewModel (detail page) if it exists
      try {
        // Cache the animal first, then use its ID to get the provider
        cacheAnimal(animal);
        ref
            .read(editAnimalViewModelProvider(animal.id).notifier)
            .addNoteLocally(note);
      } catch (_) {
        // If not in detail page context, ignore
      }

      _logger.debug(
        'addNoteToAnimal: called addNoteLocally on EditAnimalViewModel for animal: ${animal.id}',
      );

      // Update local state
      state = updatedAnimal;
      _logger.debug(
        'addNoteToAnimal: updated local AddNoteViewModel state for animal: ${animal.id}',
      );
    } catch (e) {
      // Handle error
      _logger.error('Failed to add note', e);
    }
  }

  Future<void> uploadImageToAnimal(
    Animal animal,
    XFile image,
    WidgetRef ref,
  ) async {
    // Get shelter ID from shelterDetailsViewModelProvider
    final shelterDetailsAsync = ref.read(shelterDetailsViewModelProvider);
    try {
      await _repository.uploadImageToAnimal(
        animal,
        shelterDetailsAsync.value!.id,
        image,
        ref,
      );

      // Optionally, update the state if needed
    } catch (e) {
      // Handle error
      _logger.error('Failed to upload image', e);
    }
  }
}

// Provider for AddNoteViewModel
final addNoteViewModelProvider =
    StateNotifierProvider.family<AddNoteViewModel, Animal, Animal>((
      ref,
      animal,
    ) {
      final repository = ref.watch(addNoteRepositoryProvider);
      return AddNoteViewModel(repository, ref, animal);
    });
