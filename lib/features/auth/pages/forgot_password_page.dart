import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/utils/utils.dart';
import 'package:purepath/core/utils/validators.dart';
import 'package:purepath/core/widgets/custom_back_button.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/fade_slide_in.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailTextController = TextEditingController();

  // Once the reset email has gone out we swap the form for a confirmation
  // view so the user knows to check their inbox.
  bool _emailSent = false;

  @override
  void dispose() {
    _emailTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kScaffoldColor,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: kScaffoldColor,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is PasswordResetSent) {
            setState(() => _emailSent = true);
            AppSnackBar.success(context, "Reset link sent to your email");
          } else if (state is PasswordResetFailure) {
            AppSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Space.vertical(8),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 0),
                    child: CustomBackButton(onTap: () => context.pop()),
                  ),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: _emailSent
                            ? _buildSentView(context)
                            : _buildFormView(context, state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormView(BuildContext context, UserState state) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: SvgPicture.asset(Assets.svgLogoSmall),
          ),
          Space.vertical(20),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: Text(
              'Forgot Password?',
              style: AppTextStyles.bold.copyWith(
                color: kWhiteColor,
                fontSize: 24,
              ),
            ),
          ),
          Space.vertical(8),
          FadeSlideIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              "Enter the email linked to your account and we'll send you a "
              "link to reset your password.",
              textAlign: TextAlign.center,
              style: AppTextStyles.normal.copyWith(
                color: kSecondaryGreyColor,
                fontSize: 14,
              ),
            ),
          ),
          Space.vertical(30),
          FadeSlideIn(
            delay: const Duration(milliseconds: 280),
            child: CustomTextField(
              hintText: "Email",
              controller: _emailTextController,
              keyboardType: TextInputType.emailAddress,
              prefix: SvgPicture.asset(
                Assets.svgEmailIcon,
                colorFilter: colorFilter(color: kSecondaryGreyColor),
              ),
              validator: (value) => Validators.email(value),
            ),
          ),
          Space.vertical(30),
          FadeSlideIn(
            delay: const Duration(milliseconds: 360),
            child: PrimaryButton(
              text: "Send Reset Link",
              isLoading: state is PasswordResetLoading,
              onPressed: () {
                FocusScope.of(context).unfocus();
                if (_formKey.currentState!.validate()) {
                  context.read<UserBloc>().add(
                    PasswordResetRequested(
                      email: _emailTextController.text.trim(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 0),
          child: SvgPicture.asset(Assets.svgLogoSmall),
        ),
        Space.vertical(20),
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: Text(
            'Check Your Email',
            style: AppTextStyles.bold.copyWith(
              color: kWhiteColor,
              fontSize: 24,
            ),
          ),
        ),
        Space.vertical(8),
        FadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: Text(
            "We've sent a password reset link to\n"
            "${_emailTextController.text.trim()}",
            textAlign: TextAlign.center,
            style: AppTextStyles.normal.copyWith(
              color: kSecondaryGreyColor,
              fontSize: 14,
            ),
          ),
        ),
        Space.vertical(30),
        FadeSlideIn(
          delay: const Duration(milliseconds: 220),
          child: PrimaryButton(
            text: "Back to Login",
            onPressed: () => context.pop(),
          ),
        ),
        Space.vertical(16),
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: GestureDetector(
            onTap: () => setState(() => _emailSent = false),
            child: ColoredBox(
              color: kTransparentColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 5,
                ),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: "Didn't get the email? ",
                    style: AppTextStyles.medium.copyWith(
                      color: kWhiteColor,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: "Try again",
                        style: AppTextStyles.semiBold.copyWith(
                          color: kSecondaryGreyColor,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
