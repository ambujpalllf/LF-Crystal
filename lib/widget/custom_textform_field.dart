// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:lf_crystal/constants/app_colors.dart';
// import 'package:lf_crystal/constants/app_text_style.dart';

// class CustomTextformField extends StatelessWidget {
//   final TextEditingController? controller;
//   final String? labelText;
//   final String? hintText;
//   final String? errorText;
//   final TextStyle? lableTextStyle;
//   final TextStyle? hintTextStyle;
//   final bool obscureText;
//   final bool readOnly;
//   final bool? filled;
//   final Color? fillColor;
//   final TextInputType keyboardType;
//   final Widget? prefixIcon;
//   final Widget? suffixIcon;
//   final Widget? suffix;
//   final BoxConstraints? suffixIconConstraints;
//   final Function(String)? onChanged;
//   final Color? borderColor;
//   final Color? lableTextColor;
//   final Color? hintTextColor;
//   final Color? cursorColor;
//   final VoidCallback? onTap;
//   final int? maxHintLines;
//   final int? minLines;
//   final int? maxLines;
//   final int? maxLength;
//   final List<TextInputFormatter>? inputFormatters;
//   final String? Function(String?)? validator;
//   final Function(String)? onFieldSubmitted;
//   final VoidCallback? onEditingComplete;
//   final double? borderRadius;

//   const CustomTextformField({
//     super.key,
//     this.controller,
//     this.labelText,
//     this.hintText,
//     this.lableTextStyle,
//     this.hintTextStyle,
//     this.errorText,
//     this.obscureText = false,
//     this.readOnly = false,
//     this.filled,
//     this.fillColor,
//     this.keyboardType = TextInputType.text,
//     this.prefixIcon,
//     this.suffixIcon,
//     this.suffix,
//     this.suffixIconConstraints,
//     this.onChanged,
//     this.borderColor,
//     this.hintTextColor,
//     this.lableTextColor,
//     this.cursorColor,
//     this.onTap,
//     this.maxHintLines,
//     this.minLines,
//     this.maxLines = 1,
//     this.maxLength,
//     this.inputFormatters,
//     this.validator,
//     this.onFieldSubmitted,
//     this.onEditingComplete,
//     this.borderRadius,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return TextFormField(
//       controller: controller,
//       cursorColor: cursorColor,
//       readOnly: readOnly,
//       obscureText: obscureText,
//       keyboardType: keyboardType,
//       onChanged: onChanged,
//       onTap: onTap,
//       minLines: minLines,
//       maxLines: maxLines,
//       maxLength: maxLength,
//       inputFormatters: inputFormatters,
//       validator: validator,
//       onFieldSubmitted: onFieldSubmitted,
//       onEditingComplete: onEditingComplete,
//       decoration: InputDecoration(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
//         suffixIconConstraints: suffixIconConstraints,
//         filled: filled,
//         fillColor: fillColor,
//         labelText: labelText,
//         labelStyle: lableTextStyle ?? AppTextStyle.ts14MB.copyWith(color: lableTextColor ?? AppColors.black),
//         hintText: hintText,
//         errorText: errorText,
//         hintMaxLines: maxHintLines,
//         hintStyle: hintTextStyle ?? AppTextStyle.ts14RB.copyWith(color: hintTextColor ?? AppColors.black),
//         prefixIcon: prefixIcon,
//         suffix: suffix,
//         suffixIcon: suffixIcon,
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
//           borderSide: BorderSide(color: borderColor ?? AppColors.grey),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
//           borderSide: BorderSide(color: borderColor ?? AppColors.grey),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
//           borderSide: BorderSide(color: AppColors.red),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(borderRadius ?? 8.0),
//           borderSide: BorderSide(color: AppColors.red),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lf_crystal/constants/app_colors.dart';
import 'package:lf_crystal/constants/app_text_style.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class CustomTextformField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final TextStyle? lableTextStyle;
  final TextStyle? hintTextStyle;
  final bool obscureText;
  final bool readOnly;
  final bool? filled;
  final Color? fillColor;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final Widget? suffix;
  final BoxConstraints? suffixIconConstraints;
  final Function(String)? onChanged;
  final Color? borderColor;
  final Color? lableTextColor;
  final Color? hintTextColor;
  final Color? cursorColor;
  final VoidCallback? onTap;
  final int? maxHintLines;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final Function(String)? onFieldSubmitted;
  final VoidCallback? onEditingComplete;
  final double? borderRadius;

  // Speech
  final bool enableSpeech;

  const CustomTextformField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.lableTextStyle,
    this.hintTextStyle,
    this.errorText,
    this.obscureText = false,
    this.readOnly = false,
    this.filled,
    this.fillColor,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.suffix,
    this.suffixIconConstraints,
    this.onChanged,
    this.borderColor,
    this.hintTextColor,
    this.lableTextColor,
    this.cursorColor,
    this.onTap,
    this.maxHintLines,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.validator,
    this.onFieldSubmitted,
    this.onEditingComplete,
    this.borderRadius,

    // Speech
    this.enableSpeech = true,
  });

  @override
  State<CustomTextformField> createState() => _CustomTextformFieldState();
}

class _CustomTextformFieldState extends State<CustomTextformField> {
  late stt.SpeechToText _speech;

  bool _isListening = false;
  bool _speechAvailable = false;

  // Text that was already present before speech started.
  String _previousText = '';

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();

    if (widget.enableSpeech) {
      _initializeSpeech();
    }
  }

  Future<void> _initializeSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;

        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');

        if (!mounted) return;

        setState(() {
          _isListening = false;
        });
      },
    );

    if (mounted) {
      setState(() {});
    }
  }

  TextEditingValue _applyInputFormatters(TextEditingValue oldValue, TextEditingValue newValue) {
    TextEditingValue value = newValue;

    if (widget.inputFormatters != null) {
      for (final formatter in widget.inputFormatters!) {
        value = formatter.formatEditUpdate(oldValue, value);
      }
    }

    return value;
  }

  Future<void> _toggleSpeech() async {
    // STOP LISTENING
    if (_isListening) {
      await _speech.stop();

      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }

      return;
    }

    // Initialize if not initialized
    if (!_speechAvailable) {
      await _initializeSpeech();
    }

    if (!_speechAvailable) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition is not available')));

      return;
    }

    // Store existing text.
    _previousText = widget.controller?.text.trim() ?? '';

    setState(() {
      _isListening = true;
    });

    await _speech.listen(
      listenOptions: stt.SpeechListenOptions(
        listenFor: const Duration(minutes: 1),
        pauseFor: const Duration(seconds: 5),
      ),

      // onResult: (result) {
      //   if (!mounted) return;

      //   final spokenText = result.recognizedWords.trim();

      //   if (spokenText.isEmpty) {
      //     return;
      //   }

      //   String finalText;

      //   if (_previousText.isEmpty) {
      //     finalText = spokenText;
      //   } else {
      //     finalText = '$_previousText $spokenText';
      //   }

      //   widget.controller?.value = TextEditingValue(
      //     text: finalText,
      //     selection: TextSelection.collapsed(offset: finalText.length),
      //   );

      //   // Call your existing onChanged.
      //   widget.onChanged?.call(finalText);
      // },
      onResult: (result) {
        if (!mounted) return;

        final spokenText = result.recognizedWords.trim();

        if (spokenText.isEmpty) {
          return;
        }

        String text;

        if (_previousText.trim().isEmpty) {
          text = spokenText;
        } else {
          text = '${_previousText.trim()} $spokenText';
        }

        final oldValue = widget.controller?.value ?? const TextEditingValue();

        final newValue = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));

        // Apply your inputFormatters to speech text.
        final formattedValue = _applyInputFormatters(oldValue, newValue);

        widget.controller?.value = formattedValue;

        widget.onChanged?.call(formattedValue.text);
      },
    );
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      cursorColor: widget.cursorColor,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      onChanged: widget.onChanged,
      onTap: widget.onTap,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      onEditingComplete: widget.onEditingComplete,

      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),

        suffixIconConstraints: widget.suffixIconConstraints,

        filled: widget.filled,
        fillColor: widget.fillColor,

        labelText: widget.labelText,

        labelStyle:
            widget.lableTextStyle ?? AppTextStyle.ts14MB.copyWith(color: widget.lableTextColor ?? AppColors.black),

        hintText: widget.hintText,

        errorText: widget.errorText,

        hintMaxLines: widget.maxHintLines,

        hintStyle: widget.hintTextStyle ?? AppTextStyle.ts14RB.copyWith(color: widget.hintTextColor ?? AppColors.black),

        prefixIcon: widget.prefixIcon,

        suffix: widget.suffix,

        // ==============================
        // SPEECH MICROPHONE
        // ==============================
        suffixIcon:
            widget.enableSpeech
                ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isListening)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Text(
                          'Listening...',
                          style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),

                    IconButton(
                      tooltip: _isListening ? 'Stop listening' : 'Speak',
                      onPressed: _toggleSpeech,
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                )
                : widget.suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
          borderSide: BorderSide(color: widget.borderColor ?? AppColors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
          borderSide: BorderSide(color: widget.borderColor ?? AppColors.grey),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
          borderSide: BorderSide(color: AppColors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8.0),
          borderSide: BorderSide(color: AppColors.red),
        ),
      ),
    );
  }
}
