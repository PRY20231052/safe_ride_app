import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../styles.dart';
import 'log_in_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Widget emailTextField = Templates.textField(emailController, 'Email',
        CupertinoIcons.mail, TextInputType.emailAddress, () => {}, false);
    Widget passwordTextField = Templates.textField(
        passwordController,
        'Password',
        CupertinoIcons.lock,
        TextInputType.visiblePassword,
        () => {},
        true);
    Widget usernameTextField = Templates.textField(
        usernameController,
        'Username',
        CupertinoIcons.person,
        TextInputType.name,
        () => {},
        false);
    List<Widget> textFields = [
      usernameTextField,
      emailTextField,
      passwordTextField,
    ];
    return Scaffold(
      backgroundColor: MyColors.white,
      body: SafeArea(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: Templates.paddingApp,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(),
                    Column(
                      children: [
                        const Text('Sign Up', style: MyTextStyles.title),
                        Templates.spaceBoxH,
                        ListView.builder(
                          itemBuilder: (context, index) {
                            return Container(
                              padding: Templates.paddingBottom,
                              child: textFields[index],
                            );
                          },
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: textFields.length,
                        ),
                        Templates.elevatedButton("Sign Up", () {})
                      ],
                    ),
                    Templates.captionRowForPage("Already have an account?", 'Sign In', context, const LogInScreen())
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
