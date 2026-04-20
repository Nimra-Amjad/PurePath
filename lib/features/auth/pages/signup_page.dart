import 'package:flutter/material.dart';
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
      backgroundColor: kWhiteColor,
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(Assets.svgLogoSmall),
                    Space.vertical(20),
                    Text(
                      'Get Started Now',
                      style: AppTextStyles.bold.copyWith(
                        color: kPrimaryColor,
                        fontSize: 35,
                      ),
                    ),
                    Text(
                      'Create an account',
                      style: AppTextStyles.normal.copyWith(
                        color: kBlackColor,
                        fontSize: 20,
                      ),
                    ),
                    Space.vertical(26),
                    CustomTextField(
                      hintText: "Full Name",
                      controller: _fullNameTextController,
                      textCapitalization: TextCapitalization.words,
                      inputFormatters: [CapitalizeWordsFormatter()],
                      validator: (value) {
                        return Validators.userName(value);
                      },

                      prefix: SvgPicture.asset(
                        Assets.svgUserIcon,
                        colorFilter: colorFilter(color: kPrimaryColor),
                      ),
                    ),
                    Space.vertical(16),
                    CustomTextField(
                      hintText: "Email",
                      controller: _emailTextController,
                      prefix: SvgPicture.asset(
                        Assets.svgEmailIcon,
                        colorFilter: colorFilter(color: kPrimaryColor),
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
                        colorFilter: colorFilter(color: kPrimaryColor),
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
                          colorFilter: colorFilter(color: kPrimaryColor),
                        ),
                      ),
                    ),
                    Space.vertical(30),
                    PrimaryButton(
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
                    Space.vertical(30),
                    GestureDetector(
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
                                color: kBlackColor,
                                fontSize: 14,
                                letterSpacing: 0.2,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                  text: "Login",
                                  style: AppTextStyles.semiBold.copyWith(
                                    color: kPrimaryColor,
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
            ),
          );
        },
      ),
    );
  }
}
