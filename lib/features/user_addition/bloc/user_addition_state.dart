part of 'user_addition_bloc.dart';
class UserAdditionState extends Equatable {
  final bool isLoading;
  final Map<String, PlatformFile> uploadedDocuments;

  UserAdditionState({
    this.isLoading = false,
    this.uploadedDocuments = const {},
  });

  UserAdditionState copyWith({
    bool? isLoading,
    Map<String, PlatformFile>? uploadedDocuments,
  }) {
    return UserAdditionState(
      isLoading: isLoading ?? this.isLoading,
      uploadedDocuments: uploadedDocuments ?? this.uploadedDocuments,
    );
  }

  @override
  List<Object?> get props => [isLoading, uploadedDocuments];
}