import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare/utils/utils.dart';
import 'package:skincare/models/product.dart';
import 'package:skincare/models/time.dart';
import 'package:skincare/services/product_database.dart';
import 'package:dotted_border/dotted_border.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  final List<SkincareTime> routines;

  const EditProductPage({
    super.key,
    required this.product,
    required this.routines,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  late List<SkincareTime> _routines;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _routines = List.from(widget.routines);
    _imagePath = widget.product.imagePath;
  }

  Future<void> _saveProduct(Product product) async {
    product.id = widget.product.id;
    await ProductDatabase.instance.updateProduct(product);
    // Morning
    if (_routines.contains(SkincareTime.morning)) {
      if (!widget.routines.contains(SkincareTime.morning)) {
        await ProductDatabase.instance.addProductToRoutine(
          product,
          SkincareTime.morning,
        );
      }
    } else {
      if (widget.routines.contains(SkincareTime.morning)) {
        await ProductDatabase.instance.removeProductFromRoutine(
          product,
          SkincareTime.morning,
        );
      }
    }
    // Night
    if (_routines.contains(SkincareTime.night)) {
      if (!widget.routines.contains(SkincareTime.night)) {
        await ProductDatabase.instance.addProductToRoutine(
          product,
          SkincareTime.night,
        );
      }
    } else {
      if (widget.routines.contains(SkincareTime.night)) {
        await ProductDatabase.instance.removeProductFromRoutine(
          product,
          SkincareTime.night,
        );
      }
    }
    if (mounted) {
      GoRouter.of(context).go('/home');
    }
  }

  Future<void> pickImage() async {
    final path = await Utils.pickAndSaveImage();
    if (path == null) return;
    setState(() {
      _imagePath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ProductForm(
      onFinished: _saveProduct,
      imagePath: _imagePath,
      product: widget.product,
      type: ProductFormType.edit,
      checkboxValues: CheckboxValue(
        morning: _routines.contains(SkincareTime.morning),
        night: _routines.contains(SkincareTime.night),
      ),
      onCheckboxChanged: (time, value) {
        setState(() {
          if (value) {
            _routines.add(time);
          } else {
            _routines.remove(time);
          }
        });
      },
    );
  }
}

enum ProductFormType { create, edit }

class CheckboxValue {
  final bool morning;
  final bool night;

  const CheckboxValue({this.morning = false, this.night = false});
}

class ProductForm extends StatefulWidget {
  final Function(Product) onFinished;
  final ProductFormType type;
  final Function(SkincareTime, bool)? onCheckboxChanged;
  final CheckboxValue checkboxValues;
  final String? imagePath;
  final Product? product;

  const ProductForm({
    required this.onFinished,
    required this.type,
    this.imagePath,
    this.onCheckboxChanged,
    this.product,
    this.checkboxValues = const CheckboxValue(),
    super.key,
  });

  @override
  State<ProductForm> createState() => _ProductForm();
}

class _ProductForm extends State<ProductForm> {
  bool useInMorning = false;
  bool useAtNight = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    useInMorning = widget.checkboxValues.morning;
    useAtNight = widget.checkboxValues.night;
    _imagePath = widget.imagePath ?? '';
    _nameController.text = widget.product?.name ?? '';
    _intervalController.text = widget.product?.intervalDays.toString() ?? '';
    _instructionsController.text = widget.product?.instructions ?? '';
  }

  Future<void> pickImage() async {
    final path = await Utils.pickAndSaveImage();
    if (path == null) return;
    setState(() {
      _imagePath = path;
    });
  }

  void _onCheckboxChanged(SkincareTime time, bool value) {
    if (widget.onCheckboxChanged != null) {
      widget.onCheckboxChanged!(time, value);
    }
    setState(() {
      if (time == SkincareTime.morning) {
        useInMorning = value;
      } else if (time == SkincareTime.night) {
        useAtNight = value;
      }
    });
  }

  Product get product => Product(
    name: _nameController.text,
    intervalDays: int.tryParse(_intervalController.text) ?? 1,
    instructions: _instructionsController.text,
    imagePath: _imagePath,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16.0,
          children: [
            Text(
              'Product Image',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            ImagePickerButton(
              imagePath: _imagePath ?? '',
              onPressed: pickImage,
            ),

            const SizedBox(height: 16.0),
            Text(
              'Product Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            LabeledInput(
              label: 'Product Name',
              placeholder: 'e.g. Moisturizer',
              controller: _nameController,
            ),
            LabeledInput(
              label: 'Usage Interval (days)',
              placeholder: 'e.g. 1',
              controller: _intervalController,
              keyboardType: TextInputType.number,
            ),
            LabeledInput(
              label: 'Instructions',
              placeholder:
                  'e.g. Apply 2-3 drops to clear skin after toning, before moisturizing...',
              controller: _instructionsController,
              multiline: true,
            ),

            const SizedBox(height: 16.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Apply to routine(s)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Morning"),
                  activeColor: Theme.of(context).colorScheme.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: useInMorning,
                  onChanged: (val) {
                    _onCheckboxChanged(SkincareTime.morning, val ?? false);
                  },
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Night"),
                  activeColor: Theme.of(context).colorScheme.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: useAtNight,
                  onChanged: (val) {
                    _onCheckboxChanged(SkincareTime.night, val ?? false);
                  },
                ),
              ],
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await widget.onFinished(product);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 4,
                children: [
                  Icon(
                    widget.type == ProductFormType.create
                        ? Icons.add_circle_outline_rounded
                        : Icons.save_outlined,
                  ),
                  Text(widget.type == ProductFormType.create ? 'Add' : 'Save'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LabeledInput extends StatelessWidget {
  final String label;
  final String placeholder;
  final TextEditingController controller;
  final bool multiline;
  final TextInputType? keyboardType;

  const LabeledInput({
    super.key,
    required this.label,
    required this.placeholder,
    required this.controller,
    this.multiline = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: multiline ? null : 1,
          minLines: multiline ? 4 : 1,
          keyboardType: keyboardType ?? TextInputType.text,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey.shade500),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade500),
            ),
          ),
        ),
      ],
    );
  }
}

class ImagePickerButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String imagePath;

  const ImagePickerButton({
    super.key,
    required this.onPressed,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          dashPattern: [5, 5],
          strokeWidth: 2,
          color: Colors.grey.shade400,
          radius: const Radius.circular(12),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != '')
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        Colors.black.withAlpha(Utils.toOpacity(0.5)),
                        BlendMode
                            .darken, // Try also multiply, overlay, softLight, etc.
                      ),
                      child: Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        height: 200,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            TextButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.all(16.0),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Icon(Icons.image, size: 32),
                  Text(
                    'Tap to ${imagePath == '' ? 'take a' : 'change the'} picture',
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
