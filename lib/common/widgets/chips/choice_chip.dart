import 'package:flutter/material.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../custom_shapes/containers/circular_container.dart';

class TChoiceChip extends StatelessWidget {
  const TChoiceChip({
    super.key,
    required this.text,
    required this.selected,
    this.onSelected,
  });

  final String text;
  final bool selected;
  final void Function(bool)? onSelected;

  @override
  Widget build(BuildContext context) {
    final isColor = THelperFunctions.getColor(text) != null;
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.transparent),
      child: Column(
        children: [
          ChoiceChip(
            label: isColor ? const SizedBox() : Text(text),
            selected: selected,
            onSelected: onSelected,
            labelStyle: TextStyle(color: selected ? AppColors.white : null),
            avatar: isColor
                ? TCircularContainer(
                    width: 50,
                    height: 50,
                    backgroundColor: THelperFunctions.getColor(text)!,
                  )
                : null,
            shape: isColor ? CircleBorder() : null,
            labelPadding: isColor ? EdgeInsets.all(0) : null,
            padding: isColor ? EdgeInsets.all(0) : null,
            backgroundColor: isColor ? THelperFunctions.getColor(text)! : null,
          ),
          SizedBox(height: 10),
        ],
      ),
    );
  }
}
