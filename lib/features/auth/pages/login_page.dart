import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:purepath/core/bloc/user_bloc/user_bloc.dart';
import 'package:purepath/core/constants/app_text_styles.dart';
import 'package:purepath/core/constants/assets_constants.dart';
import 'package:purepath/core/constants/color_constants.dart';
import 'package:purepath/core/navigation/app_routes.dart';
import 'package:purepath/core/utils/snackbar.dart';
import 'package:purepath/core/utils/utils.dart';
import 'package:purepath/core/utils/validators.dart';
import 'package:purepath/core/widgets/custom_textfield.dart';
import 'package:purepath/core/widgets/primary_button.dart';
import 'package:purepath/core/widgets/space.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool hidePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();

  @override
  void dispose() {
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkGreyColor,
      body: BlocConsumer<UserBloc, UserState>(
        listener: (context, state) {
          if (state is UserSignedIn) {
            context.push(AppRoute.onboarding.path);
            AppSnackBar.success(context, "Login successful");
          } else if (state is AuthFailure) {
            AppSnackBar.error(context, state.message);
          }
        },
        builder: (context, state) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(Assets.svgLogoSmall),
                  Space.vertical(20),
                  Text(
                    'Welcome Back',
                    style: AppTextStyles.bold.copyWith(
                      color: kLightYellowColor,
                      fontSize: 35,
                    ),
                  ),
                  Text(
                    'Login to access you account',
                    style: AppTextStyles.normal.copyWith(
                      color: kWhiteColor,
                      fontSize: 20,
                    ),
                  ),
                  Space.vertical(30),
                  CustomTextField(
                    hintText: "Email",
                    controller: _emailTextController,
                    prefix: SvgPicture.asset(
                      Assets.svgEmailIcon,
                      colorFilter: colorFilter(color: kLightYellowColor),
                    ),
                    validator: (value) {
                      return Validators.email(value);
                    },
                  ),
                  Space.vertical(16),
                  CustomTextField(
                    hintText: "Password",
                    controller: _passwordTextController,
                    obscureText: hidePassword,
                    validator: (value) {
                      return Validators.password(value);
                    },
                    prefix: SvgPicture.asset(
                      Assets.svgLockIcon,
                      colorFilter: colorFilter(color: kLightYellowColor),
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
                        colorFilter: colorFilter(color: kLightYellowColor),
                      ),
                    ),
                  ),
                  Space.vertical(30),
                  PrimaryButton(
                    text: "Login",
                    // inactive: true,
                    buttonColor: kLightYellowColor,
                    isLoading: state is AuthLoading,
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        context.read<UserBloc>().add(
                          LoginRequested(
                            email: _emailTextController.text.trim(),
                            password: _passwordTextController.text.trim(),
                          ),
                        );
                      }
                    },
                  ),
                  Space.vertical(30),
                  GestureDetector(
                    onTap: () {
                      context.push(AppRoute.signup.path);
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
                              color: kGreyColor,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: "Sign up",
                                style: AppTextStyles.semiBold.copyWith(
                                  color: kWhiteColor,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
