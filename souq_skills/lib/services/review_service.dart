import '../models/review.dart';
import 'repository.dart';

class ReviewService {
  ReviewService({Repository? repository}) : _repository = repository ?? Repository.instance;
  final Repository _repository;
  Future<List<Review>> getReviews() async => List.unmodifiable(_repository.reviews);
  Future<Review> addReview(Review review) async {
    if (review.rating < 1 || review.rating > 5) {
      throw ArgumentError('Rating must be between 1 and 5');
    }
    _repository.reviews.add(review);
    _repository.emitChange();
    return review;
  }
}
