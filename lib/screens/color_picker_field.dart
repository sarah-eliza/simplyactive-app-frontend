import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerField extends StatefulWidget {
  final ValueChanged<Color> onColorSelected;
  final Color initialColor;

  const ColorPickerField({
    super.key,
    required this.onColorSelected,
    this.initialColor = Colors.grey,
  });

  @override
  State<ColorPickerField> createState() => _ColorPickerFieldState();
}

class _ColorPickerFieldState extends State<ColorPickerField> {
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
  }

  void _changeColor(Color color) {
    setState(() {
      _currentColor = color;
    });
    widget.onColorSelected(color);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show the currently selected color.
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _currentColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "RGB: (${_currentColor.r.toInt()}, ${_currentColor.g.toInt()}, ${_currentColor.b.toInt()})",
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Select a Color"),
                content: SingleChildScrollView(
                  child: ColorPicker(
                    pickerColor: _currentColor,
                    onColorChanged: _changeColor,
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hsv,
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Done"),
                  ),
                ],
              ),
            );
          },
          child: const Text("Choose"),
        ),
      ],
    );
  }
}
