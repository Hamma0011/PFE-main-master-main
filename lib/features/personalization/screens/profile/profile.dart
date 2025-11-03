import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../common/widgets/images/circular_image.dart';
import '../../../../common/widgets/texts/section_heading.dart';
import '../../../../utils/constants/image_strings.dart';
import '../../../../utils/constants/sizes.dart';
import '../../controllers/user_controller.dart';
import 'widgets/change_name.dart';
import 'widgets/profile_menu.dart';

class ProfileScreen extends GetView<UserController> {
  const ProfileScreen({super.key});

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              // Image en plein écran
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image(
                      image: imageUrl.startsWith('http')
                          ? NetworkImage(imageUrl)
                          : AssetImage(imageUrl) as ImageProvider,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 300,
                          height: 300,
                          color: Colors.grey[300],
                          child: const Icon(Icons.error, size: 50),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bouton fermer en haut à droite
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TAppBar(
        showBackArrow: true,
        title: const Text('Mon Profil'),
        customBackNavigation: () {
          Get.back();
        },
      ),
      body: Obx(() {
        // si le profil est en chargement
        if (controller.profileLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Charger utilisateur courant
        final user = controller.user.value;

        // Déterminer l'image de profil
        final profileImage = user.profileImageUrl!.isNotEmpty
            ? user.profileImageUrl!
            : user.sex == 'Homme'
            ? TImages.userMale
            : TImages.userFemale;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              children: [
                /// Photo de profil avec icône modifier
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Photo de profil cliquable
                          GestureDetector(
                            onTap: () {
                              _showFullScreenImage(context, profileImage);
                            },
                            child: CircularImage(
                              isNetworkImage: true,
                              image: profileImage,
                              width: 80,
                              height: 80,
                            ),
                          ),

                          // Icône modifier en bas à droite
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );
                                if (pickedFile != null) {
                                  await controller.updateProfileImage(pickedFile);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.spaceBtwItems / 2),
                      TextButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            await controller.updateProfileImage(pickedFile);
                          }
                        },
                        child: const Text('Modifier la photo de profil'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSizes.spaceBtwItems / 2),
                const Divider(),
                const SizedBox(height: AppSizes.spaceBtwItems),

                const TSectionHeading(
                  title: 'Informations du profil',
                  showActionButton: false,
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),

                TProfileMenu(
                    title: "Nom",
                    value: "${user.firstName} ${user.lastName}",
                    onPressed: () => Get.to(() => const ChangeName())),
                TProfileMenu(
                  title: "Nom d'utilisateur",
                  value: user.username,
                  onPressed: () {},
                ),

                const SizedBox(height: AppSizes.spaceBtwItems),
                const Divider(),
                //const SizedBox(height: AppSizes.spaceBtwItems),

                const TSectionHeading(
                  title: 'Infos personnelles',
                  showActionButton: false,
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),
                TProfileMenu(
                  title: "E-mail",
                  value: user.email,
                  onPressed: () {},
                ),
                TProfileMenu(
                  title: "Téléphone",
                  value: user.phone,
                  onPressed: () {},
                ),
                TProfileMenu(
                  title: "Date de naissance ",
                  value: user.dateOfBirth != null
                      ? DateFormat('dd/MM/yyyy').format(user.dateOfBirth!)
                      : "Non définie",
                  onPressed: () {},
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}