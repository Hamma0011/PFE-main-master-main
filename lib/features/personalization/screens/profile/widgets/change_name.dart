import 'package:caferesto/utils/validators/validation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../common/widgets/appbar/appbar.dart';
import '../../../../../utils/constants/sizes.dart';
import '../../../controllers/update_name_controller.dart';

class ChangeName extends StatelessWidget {
  const ChangeName({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UpdateNameController());
    return Scaffold(
      /// AppBar Personnalisé
      appBar: TAppBar(
        showBackArrow: true,
        title: Text('Modifier le nom',
            style: Theme.of(context).textTheme.headlineSmall),
        customBackNavigation: () {
          Get.back(result: false);
        },
      ),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// En tetes
            ///
            Text(
                "Utiliser un nom réel, ce nom va appraître dans plusieurs pages",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppSizes.spaceBtwSections),
            Form(
              key: controller.updateUserNameFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.firstName,
                    validator: (value) =>
                        TValidator.validateEmptyText("Prénom", value),
                    decoration: const InputDecoration(
                      labelText: 'Prénom',
                      hintText: 'Entrez votre prénom',
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwInputFields),
                  TextFormField(
                    controller: controller.lastName,
                    validator: (value) =>
                        TValidator.validateEmptyText("Nom", value),
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      hintText: 'Entrez votre nom',
                    ),
                  ),
                  const SizedBox(
                    height: AppSizes.spaceBtwInputFields,
                  ),
                  TextFormField(
                    controller: controller.username,
                    validator: (value) =>
                        TValidator.validateEmptyText("Nom d'utilsateur", value),
                    decoration: const InputDecoration(
                        labelText: "Nom d'utilisateur",
                        hintText: "Entrez votre nom d'utilisateur"),
                  ),
                  const SizedBox(
                    height: AppSizes.spaceBtwInputFields,
                  ),
                  TextFormField(
                    controller: controller.phone,
                    validator: (value) =>
                        TValidator.validateEmptyText("Téléphone", value),
                    decoration: const InputDecoration(
                        labelText: "Téléphone",
                        hintText: "Entrez votre numéro de téléphone"),
                  ),
                  const SizedBox(
                    height: AppSizes.spaceBtwInputFields,
                  ),
                  TextFormField(
                    controller: controller.birthDate,
                    readOnly: true, // empêche la saisie manuelle
                    validator: (value) =>
                        TValidator.validateEmptyText("Date de naissance", value),
                    decoration: const InputDecoration(
                      labelText: "Date de naissance",
                      hintText: "Sélectionnez votre date de naissance",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    onTap: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        locale: const Locale("fr", "FR"),
                      );

                      if (pickedDate != null) {
                        controller.birthDate.text =
                        "${pickedDate.day.toString().padLeft(2,'0')}/"
                            "${pickedDate.month.toString().padLeft(2,'0')}/"
                            "${pickedDate.year}";
                      }
                    },
                  ),

                ],
              ),
            ),

            const SizedBox(height: AppSizes.spaceBtwSections),
// Save Button (update)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.updateUserName(),
                child: const Text('Mettre à jour'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
