import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/constants.dart';
import '../domain/voice_state.dart';
import '../providers/voice_provider.dart';
import 'widgets/voice_waveform.dart';

/// Full-screen voice input overlay.
class VoiceOverlayScreen extends ConsumerStatefulWidget {
  const VoiceOverlayScreen({
    super.key,
    required this.documentId,
    this.onComplete,
  });

  /// The document ID for context.
  final int documentId;

  /// Callback when voice input is complete.
  final void Function(String text)? onComplete;

  @override
  ConsumerState<VoiceOverlayScreen> createState() => _VoiceOverlayScreenState();
}

class _VoiceOverlayScreenState extends ConsumerState<VoiceOverlayScreen> {
  @override
  void initState() {
    super.initState();
    // Start listening immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _startListening() {
    ref.read(voiceProvider.notifier).startListening(
      onComplete: (text) {
        widget.onComplete?.call(text);
        if (mounted) {
          context.pop(text);
        }
      },
    );
  }

  void _toggleListening() {
    final state = ref.read(voiceProvider);
    if (state.isListening) {
      ref.read(voiceProvider.notifier).stopListening();
    } else {
      _startListening();
    }
  }

  void _cancel() {
    ref.read(voiceProvider.notifier).cancelListening();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.voiceOverlayGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Spacer(),
              _buildCenterContent(voiceState),
              const Spacer(),
              _buildBottomControls(voiceState),
              SizedBox(height: AppDimensions.spacingXl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.all(AppDimensions.spacingMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.close, color: Colors.white),
            iconSize: 28,
          ),
          const Text(
            'Voice Input',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 48), // Balance the close button
        ],
      ),
    );
  }

  Widget _buildCenterContent(VoiceState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform visualization
        VoiceWaveform(
          isActive: state.isListening,
          soundLevel: state.soundLevel,
          height: AppDimensions.voiceWaveformHeight,
          barCount: 7,
        ),
        SizedBox(height: AppDimensions.spacingXl),
        
        // Status text
        Text(
          _getStatusText(state),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppDimensions.spacingLg),
        
        // Transcribed text
        Container(
          constraints: BoxConstraints(
            maxWidth: AppDimensions.voiceTranscriptMaxWidth,
            minHeight: 80,
          ),
          padding: EdgeInsets.all(AppDimensions.spacingMd),
          child: Text(
            state.displayText.isEmpty
                ? (state.isListening ? 'Listening...' : 'Tap to speak')
                : state.displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: state.displayText.isEmpty ? 16 : 20,
              fontWeight: FontWeight.w500,
              fontStyle: state.displayText.isEmpty 
                  ? FontStyle.italic 
                  : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls(VoiceState state) {
    return Column(
      children: [
        // Main mic button
        VoiceMicButton(
          isListening: state.isListening,
          onPressed: _toggleListening,
          size: 80,
        ),
        SizedBox(height: AppDimensions.spacingLg),
        
        // Helper text
        Text(
          state.isListening
              ? 'Tap to stop'
              : (state.displayText.isNotEmpty ? 'Tap to retry' : 'Tap to start'),
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 14,
          ),
        ),
        
        // Error message
        if (state.hasError) ...[
          SizedBox(height: AppDimensions.spacingMd),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingMd,
              vertical: AppDimensions.spacingSm,
            ),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: AppDimensions.spacingSm),
                Text(
                  state.error ?? 'An error occurred',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Send button when text is available
        if (state.displayText.isNotEmpty && !state.isListening) ...[
          SizedBox(height: AppDimensions.spacingLg),
          ElevatedButton.icon(
            onPressed: () {
              widget.onComplete?.call(state.displayText);
              context.pop(state.displayText);
            },
            icon: const Icon(Icons.send),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.textOnPrimary,
              padding: EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingXl,
                vertical: AppDimensions.spacingMd,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getStatusText(VoiceState state) {
    switch (state.mode) {
      case VoiceMode.listening:
        return 'Listening...';
      case VoiceMode.processing:
        return 'Processing...';
      case VoiceMode.error:
        return 'Error';
      default:
        if (state.displayText.isNotEmpty) {
          return 'Ready to send';
        }
        return 'Ready';
    }
  }
}
