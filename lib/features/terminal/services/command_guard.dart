/// Result of a [CommandGuard] assessment.
class CommandCheck {
  final bool isDangerous;

  /// Human-readable explanation, null when the command is safe.
  final String? reason;

  const CommandCheck.safe() : isDangerous = false, reason = null;

  const CommandCheck.dangerous(this.reason) : isDangerous = true;
}

/// Classifies shell commands that can destroy data or take the machine down,
/// so the embedded terminal can require an explicit confirmation before
/// executing them. Mirrors the red-flag list the AI SafetyAgent enforces for
/// chat-driven operations.
class CommandGuard {
  /// Assesses [command], considering each `;`/`&&`/`|` segment separately so
  /// `ls; rm -rf /` is still caught.
  CommandCheck assess(String command) {
    final normalized = command.trim().toLowerCase();
    if (normalized.isEmpty) return const CommandCheck.safe();

    // Fork bomb — recognizable as a whole, before any segmentation.
    if (normalized.contains(':(){')) {
      return const CommandCheck.dangerous('fork bomb');
    }
    // Writes straight to a block device, wherever they appear.
    if (RegExp(r'(>\s*|of=)/dev/(sd|nvme|hd|mmcblk)').hasMatch(normalized)) {
      return const CommandCheck.dangerous('raw write to a block device');
    }

    for (final rawSegment in normalized.split(RegExp(r'[;&|]+'))) {
      final segment = rawSegment.trim().replaceFirst(RegExp(r'^sudo\s+'), '');
      if (segment.isEmpty) continue;
      final word = segment.split(RegExp(r'\s+')).first;

      // rm with recursive+force flags (combined -rf/-fr in any position).
      if (word == 'rm' &&
          RegExp(r'\s-[a-z]*(rf|fr)[a-z]*(\s|$)').hasMatch(segment)) {
        return const CommandCheck.dangerous('recursive forced delete (rm)');
      }
      if (word == 'dd' && segment.contains('of=/dev/')) {
        return const CommandCheck.dangerous('dd onto a device');
      }
      if (word.startsWith('mkfs')) {
        return const CommandCheck.dangerous('filesystem format (mkfs)');
      }
      if (const {'shutdown', 'reboot', 'poweroff', 'halt'}.contains(word)) {
        return const CommandCheck.dangerous('system power command');
      }
      if (segment.startsWith('git push') &&
          RegExp(r'\s(--force|-f)(\s|$)').hasMatch(segment)) {
        return const CommandCheck.dangerous('git force push');
      }
      if (RegExp(r'^chmod\s+-r\s+777\s+/\s*$').hasMatch(segment)) {
        return const CommandCheck.dangerous('recursive 777 on root');
      }
    }

    return const CommandCheck.safe();
  }
}
