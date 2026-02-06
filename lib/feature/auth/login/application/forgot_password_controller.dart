import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state/forgot_password_state.dart';
import 'providers.dart';

class ForgotPasswordController extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordController(this.ref) : super(const ForgotPasswordInitial());

  final Ref ref;

  Future<void> sendResetEmail({required String email}) async {
    state = const ForgotPasswordLoading();

    final useCase = ref.read(sendPasswordResetEmailProvider);
    final result = await useCase.call(email: email);

    result.fold(
      (failure) {
        state = ForgotPasswordError(failure);
      },
      (_) {
        state = const ForgotPasswordSuccess();
      },
    );
  }

  void reset() {
    state = const ForgotPasswordInitial();
  }
}

