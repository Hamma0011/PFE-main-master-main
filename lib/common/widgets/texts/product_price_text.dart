import 'package:flutter/material.dart';

class ProductPriceText extends StatelessWidget {
  const ProductPriceText({
    super.key,
    this.currencySign = "DT",
    required this.price,
    this.isLarge = false,
    this.lineThrough = false,
    this.maxLines = 1,
    this.variable = false,
  });

  final String currencySign, price;
  final int maxLines;
  final bool isLarge;
  final bool lineThrough;
  final bool variable;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        variable ? Text('à partir de') : SizedBox(),
        Text(
          '$price $currencySign',
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: isLarge
              ? Theme.of(context).textTheme.headlineMedium!.apply(
                    decoration: lineThrough ? TextDecoration.lineThrough : null,
                  )
              : Theme.of(context).textTheme.titleLarge!.apply(
                  decoration: lineThrough ? TextDecoration.lineThrough : null),
        ),
      ],
    );
  }
}
