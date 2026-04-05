part of 'otp_screen.dart';

extension _OTPScreenStateUi on _OTPScreenState {
  Widget _buildLogoSection() {
    // International standard: OTP/verification screens use 10-14% of screen height
    // Examples: WhatsApp (12%), Telegram (11%), Signal (13%)
    final screenH = MediaQuery.of(context).size.height;
    final logoSize = (screenH * 0.16).clamp(110.0, 160.0);

    return Column(
      children: [
        AppLogo(
          size: logoSize,
          fallback: Icon(
            Icons.location_on,
            color: SignupConstants.primaryGold,
            size: logoSize * 0.4,
          ),
        ),
        const SizedBox(height: 24), // 8pt grid: logo → title
        const Text(
          'Vérification',
          style: TextStyle(
            fontSize: 18,
            color: SignupConstants.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8), // 8pt grid: title → subtitle
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              color: SignupConstants.textGrey,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Entrez le code envoyé au\n'),
              TextSpan(
                text: PhoneFormatter.formatPhoneForDisplay(widget.phone),
                style: const TextStyle(
                  color: SignupConstants.primaryGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isVerifying
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  _handleBack();
                },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            minimumSize: const Size(180, 40),
            foregroundColor: SignupConstants.primaryGold,
          ),
          child: Text(
            'Numéro incorrect ?',
            style: TextStyle(
              fontSize: 13,
              color: _isVerifying ? SignupConstants.textGrey.withValues(alpha: 0.6) : SignupConstants.primaryGold,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor:
                  _isVerifying ? SignupConstants.textGrey.withValues(alpha: 0.6) : SignupConstants.primaryGold,
            ),
          ),
        ),
        if (_otpUnavailableMessage != null && _otpUnavailableMessage!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SignupConstants.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: SignupConstants.errorRed.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: SignupConstants.errorRed, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otpUnavailableMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: SignupConstants.errorRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOTPFields() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            const maxBox = 54.0;
            const minBox = 36.0; // allow smaller to avoid overflow on small devices
            var gap = 10.0;

            // Start with an ideal size, then shrink gap/box as needed to always fit.
            var boxW = (maxW - gap * 5) / 6;
            if (boxW > maxBox) boxW = maxBox;

            if (boxW < minBox) {
              boxW = minBox;
              gap = ((maxW - boxW * 6) / 5).clamp(4.0, 10.0);
              // If still doesn't fit (very narrow screens), shrink box to fit with min gap.
              const minGap = 4.0;
              if (boxW * 6 + minGap * 5 > maxW) {
                boxW = ((maxW - minGap * 5) / 6).clamp(28.0, minBox);
                gap = minGap;
              }
            }

            const height = 62.0;

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(6, (index) {
                return Padding(
                  padding: EdgeInsets.only(right: index == 5 ? 0 : gap),
                  child: SizedBox(
                    width: boxW,
                    height: height,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      enabled: !_isVerifying && !_otpBlocked,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      textInputAction:
                          index == 5 ? TextInputAction.done : TextInputAction.next,
                      cursorColor: SignupConstants.primaryGold,
                      style: const TextStyle(
                        color: SignupConstants.textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      autofillHints:
                          index == 0 ? const [AutofillHints.oneTimeCode] : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onChanged(index, value),
                      onTap: () {
                        // Select all text when tapping for easy replacement
                        final t = _controllers[index].text;
                        if (t.isNotEmpty) {
                          _controllers[index].selection = TextSelection(
                            baseOffset: 0,
                            extentOffset: t.length,
                          );
                        }
                      },
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: SignupConstants.bgDark2,
                        contentPadding: const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: SignupConstants.borderColor, width: 1),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: SignupConstants.borderColor, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: SignupConstants.primaryGold,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
        if (_isVerifying) ...[
          const SizedBox(height: 16),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(SignupConstants.primaryGold),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResendButton() {
    return Column(
      children: [
        TextButton(
          onPressed: (_canResend && !_isVerifying) ? _handleResend : null,
          style: TextButton.styleFrom(
            foregroundColor: _canResend ? SignupConstants.primaryGold : SignupConstants.textGrey,
          ),
          child: Text(
            _canResend
                ? 'Renvoyer le code'
                : 'Renvoyer le code (${_resendTimer}s)',
            style: TextStyle(
              color: _canResend ? SignupConstants.primaryGold : SignupConstants.textGrey,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpScreen(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: MerchantColors.bgHeader,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: MerchantColors.bgMain,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && !_isVerifying) {
            _handleBack();
          }
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _handleBack,
                      icon: const Icon(Icons.arrow_back),
                      color: SignupConstants.primaryGold,
                      iconSize: 24,
                    ),
                  ),
                  _buildLogoSection(),
                  const SizedBox(height: 32),
                  _buildOTPFields(),
                  const SizedBox(height: 40),
                  _buildResendButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
