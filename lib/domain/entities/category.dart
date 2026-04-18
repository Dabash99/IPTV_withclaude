import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String categoryId;
  final String categoryName;
  final int parentId;

  const Category({
    required this.categoryId,
    required this.categoryName,
    required this.parentId,
  });

  @override
  List<Object?> get props => [categoryId, categoryName, parentId];
}
