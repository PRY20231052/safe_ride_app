// ignore_for_file: prefer_const_constructors

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
                        SizedBox(height: 8,),
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
                        Container(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            style: MyButtonStyles.primary,
                            child: Text('Sign Up', style: MyTextStyles.primaryButton,),
                            onPressed: () {
                              
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Already have an account?",),
                        TextButton(
                          child: Text('Sign In',),
                          onPressed: () {
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => LogInScreen()));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          )),
    );
  }
}
