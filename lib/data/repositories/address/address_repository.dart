import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../features/personalization/models/address_model.dart';
import '../authentication/authentication_repository.dart';

class AddressRepository extends GetxController {
  static AddressRepository get instance => Get.find();
  final supabase = Supabase.instance.client;

  Future<List<AddressModel>> fetchUserAddresses() async {
    try {
      final userId = AuthenticationRepository.instance.authUser!.id;
      if (userId.isEmpty) {
        throw ('Unable to find user information. Try again in few minutes');
      }

      final response =
          await supabase.from('addresses').select().eq('user_id', userId);

      // response is List<dynamic>
      final data = response as List<dynamic>;
      return data
          .map((row) => AddressModel.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw 'Something went wrong while fetching address information, try again later';
    }
  }

  Future<void> updateSelectedField(String addressId, bool selected) async {
    try {
      final userId = AuthenticationRepository.instance.authUser!.id;

      await supabase
          .from('addresses')
          .update({'selected_address': selected})
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw 'Something went wrong while updating address information, try again later';
    }
  }

  Future<String> addAddress(AddressModel address) async {
    try {
      final userId = AuthenticationRepository.instance.authUser!.id;

      final response = await supabase
          .from('addresses')
          .insert({
            ...address.toJson(),
            'user_id': userId,
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e, s) {
      print('Supabase insert error: $e\n$s');
      rethrow;
    }
  }

  /// Delete an address by ID
  Future<void> deleteAddress(String addressId) async {
    try {
      final userId = AuthenticationRepository.instance.authUser!.id;
      if (userId.isEmpty) {
        throw ('Unable to find user information. Try again in few minutes');
      }

      await supabase
          .from('addresses')
          .delete()
          .eq('id', addressId)
          .eq('user_id', userId);
    } catch (e) {
      throw 'Something went wrong while deleting address information, try again later';
    }
  }
}
