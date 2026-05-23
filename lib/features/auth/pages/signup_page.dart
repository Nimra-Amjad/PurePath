import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/utils/formatters.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/utils/utils.dart';
import 'package:purepath/core/utils/validators.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/fade_slide_in.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  bool hidePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _fullNameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
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
          if (state is UserSignedUp) {
            context.push(AppRoute.preferences.path);
            AppSnackBar.success(context, "Account created successfully");
          } else if (state is AuthFailure) {
            AppSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Each section gets a staggered fade-slide-in so the
                      // screen assembles itself instead of popping in flat.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 0),
                        child: SvgPicture.asset(Assets.svgLogoSmall),
                      ),
                      Space.vertical(20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: Text(
                          'Get Started Now',
                          style: AppTextStyles.bold.copyWith(
                            color: kWhiteColor,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: Text(
                          'Create an account',
                          style: AppTextStyles.normal.copyWith(
                            color: kWhiteColor,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      Space.vertical(26),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 220),
                        child: CustomTextField(
                          hintText: "Full Name",
                          controller: _fullNameTextController,
                          textCapitalization: TextCapitalization.words,
                          inputFormatters: [CapitalizeWordsFormatter()],
                          validator: (value) {
                            return Validators.userName(value);
                          },
                          prefix: SvgPicture.asset(
                            Assets.svgUserIcon,
                            colorFilter: colorFilter(
                              color: kSecondaryGreyColor,
                            ),
                          ),
                        ),
                      ),
                      Space.vertical(16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: CustomTextField(
                          hintText: "Email",
                          controller: _emailTextController,
                          prefix: SvgPicture.asset(
                            Assets.svgEmailIcon,
                            colorFilter: colorFilter(
                              color: kSecondaryGreyColor,
                            ),
                          ),
                          validator: (value) {
                            return Validators.email(value);
                          },
                        ),
                      ),
                      Space.vertical(16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 380),
                        child: CustomTextField(
                          hintText: "Password",
                          controller: _passwordTextController,
                          obscureText: hidePassword,
                          validator: (value) {
                            return Validators.password(value);
                          },
                          prefix: SvgPicture.asset(
                            Assets.svgLockIcon,
                            colorFilter: colorFilter(
                              color: kSecondaryGreyColor,
                            ),
                          ),
                          suffix: GestureDetector(
                            onTap: () {
                              setState(() {
                                hidePassword = !hidePassword;
                              });
                            },
                            child: SvgPicture.asset(
                              hidePassword
                                  ? Assets.svgEyeCloseIcon
                                  : Assets.svgEyeOpenIcon,
                              colorFilter: colorFilter(
                                color: kSecondaryGreyColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Space.vertical(30),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 460),
                        child: PrimaryButton(
                          text: "Sign up",
                          isLoading: state is AuthLoading,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              context.read<UserBloc>().add(
                                SignupRequested(
                                  fullName: _fullNameTextController.text.trim(),
                                  email: _emailTextController.text.trim(),
                                  password: _passwordTextController.text.trim(),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      Space.vertical(30),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 540),
                        child: GestureDetector(
                          onTap: () {
                            context.push(AppRoute.login.path);
                          },
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
                                  text: "Don't have an account? ",
                                  style: AppTextStyles.medium.copyWith(
                                    color: kWhiteColor,
                                    fontSize: 14,
                                    letterSpacing: 0.2,
                                  ),
                                  children: <TextSpan>[
                                    TextSpan(
                                      text: "Login",
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
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
