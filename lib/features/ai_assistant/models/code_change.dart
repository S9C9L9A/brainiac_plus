/// Represents a code modification request
class CodeChange {
  final String id;
  final String filePath;
  final CodeChangeType type;
  final String description;
  final String? oldContent;
  final String? newContent;
  final DateTime createdAt;
  final CodeChangeStatus status;
  final String? errorMessage;

  CodeChange({
    required this.id,
    required this.filePath,
    required this.type,
    required this.description,
    this.oldContent,
    this.newContent,
    required this.createdAt,
    this.status = CodeChangeStatus.pending,
    this.errorMessage,
  });

  CodeChange copyWith({
    String? id,
    String? filePath,
    CodeChangeType? type,
    String? description,
    String? oldContent,
    String? newContent,
    DateTime? createdAt,
    CodeChangeStatus? status,
    String? errorMessage,
  }) {
    return CodeChange(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      type: type ?? this.type,
      description: description ?? this.description,
      oldContent: oldContent ?? this.oldContent,
      newContent: newContent ?? this.newContent,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filePath': filePath,
        'type': type.name,
        'description': description,
        'oldContent': oldContent,
        'newContent': newContent,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'errorMessage': errorMessage,
      };

  factory CodeChange.fromJson(Map<String, dynamic> json) => CodeChange(
        id: json['id'] as String,
        filePath: json['filePath'] as String,
        type: CodeChangeType.values.byName(json['type'] as String),
        description: json['description'] as String,
        oldContent: json['oldContent'] as String?,
        newContent: json['newContent'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: CodeChangeStatus.values.byName(json['status'] as String),
        errorMessage: json['errorMessage'] as String?,
      );
}

/// Type of code change
enum CodeChangeType {
  create, // Create new file
  modify, // Modify existing file
  delete, // Delete file (rarely used)
}

/// Status of code change
enum CodeChangeStatus {
  pending, // Waiting for approval
  approved, // User approved
  rejected, // User rejected
  applied, // Successfully applied
  failed, // Failed to apply
}

/// Extension for CodeChangeType
extension CodeChangeTypeX on CodeChangeType {
  String get label {
    switch (this) {
      case CodeChangeType.create:
        return 'Create';
      case CodeChangeType.modify:
        return 'Modify';
      case CodeChangeType.delete:
        return 'Delete';
    }
  }
}

/// Extension for CodeChangeStatus
extension CodeChangeStatusX on CodeChangeStatus {
  String get label {
    switch (this) {
      case CodeChangeStatus.pending:
        return 'Pending';
      case CodeChangeStatus.approved:
        return 'Approved';
      case CodeChangeStatus.rejected:
        return 'Rejected';
      case CodeChangeStatus.applied:
        return 'Applied';
      case CodeChangeStatus.failed:
        return 'Failed';
    }
  }
}
