part of 'otp_screen.dart';

extension _OTPScreenStateUi on _OTPScreenState {
  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Verification icon — compact, no logo waste
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: SignupConstants.primaryGold.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: SignupConstants.primaryGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.shield_outlined,
            color: SignupConstants.primaryGold,
            size: 26,
          ),
        ),
        const SizedBox(height: 16),

        // Title — gradient, Outfit, left-aligned (matches signup)
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [SignupConstants.textLight, SignupConstants.primaryGold],
            stops: [0.55, 1.0],
          ).createShader(bounds),
          child: Text(
            'Vérification',
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Subtitle
        RichText(
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: SignupConstants.textGrey,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Code envoyé au '),
              TextSpan(
                text: PhoneFormatter.formatPhoneForDisplay(widget.phone),
                style: GoogleFonts.outfit(
                  color: SignupConstants.primaryGold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // "Wrong number?" link
        GestureDetector(
          onTap: _isVerifying ? null : _handleBack,
          child: Text(
            'Numéro incorrect ? Modifier',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: _isVerifying
                  ? SignupConstants.primaryGold.withValues(alpha: 0.4)
                  : SignupConstants.primaryGold,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.underline,
              decorationColor: _isVerifying
                  ? SignupConstants.primaryGold.withValues(alpha: 0.4)
                  : SignupConstants.primaryGold,
            ),
          ),
        ),

        if (_otpUnavailableMessage != null &&
            _otpUnavailableMessage!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SignupConstants.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: SignupConstants.errorRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: SignupConstants.errorRed,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _otpUnavailableMessage!,
                    style: GoogleFonts.outfit(
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
            const minBox = 36.0;
            var gap = 10.0;

            var boxW = (maxW - gap * 5) / 6;
            if (boxW > maxBox) boxW = maxBox;

            if (boxW < minBox) {
              boxW = minBox;
              gap = ((maxW - boxW * 6) / 5).clamp(4.0, 10.0);
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
                      textInputAction: index == 5
                          ? TextInputAction.done
                          : TextInputAction.next,
                      cursorColor: SignupConstants.primaryGold,
                      style: GoogleFonts.outfit(
                        color: SignupConstants.textLight,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      autofillHints: index == 0
                          ? const [AutofillHints.oneTimeCode]
                          : null,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      onChanged: (value) => _onChanged(index, value),
                      onTap: () {
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
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 18),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: SignupConstants.borderColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: SignupConstants.borderColor,
                            width: 1,
                          ),
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
          const SizedBox(height: 20),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                SignupConstants.primaryGold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildResendButton() {
    final canTap = _canResend && !_isVerifying;
    return GestureDetector(
      onTap: canTap ? _handleResend : null,
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: SignupConstants.textGrey,
          ),
          children: [
            const TextSpan(text: 'Vous n\'avez pas reçu le code ? '),
            TextSpan(
              text: _canResend
                  ? 'Renvoyer'
                  : 'Renvoyer (${_resendTimer}s)',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: canTap
                    ? SignupConstants.primaryGold
                    : SignupConstants.textGrey.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                decoration:
                    canTap ? TextDecoration.underline : TextDecoration.none,
                decorationColor: SignupConstants.primaryGold,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
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
          if (!didPop && !_isVerifying) _handleBack();
        },
        child: Scaffold(
          backgroundColor: MerchantColors.bgMain,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  SizedBox(
                    height: 44,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: _isVerifying ? null : _handleBack,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: _isVerifying
                                ? SignupConstants.primaryGold
                                    .withValues(alpha: 0.4)
                                : SignupConstants.primaryGold,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLogoSection(),
                  const SizedBox(height: 36),
                  _buildOTPFields(),
                  const SizedBox(height: 32),
                  Center(child: _buildResendButton()),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
