import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import 'package:THECommu/common/constants.dart';

class Ice extends StatefulWidget {
  const Ice({super.key});

  @override
  State<Ice> createState() => _IceState();
}

class _IceState extends State<Ice> {
  late StateMachineController controller;
  late SMIBool smiOn;

  @override
  Widget build(BuildContext context) {
    return RiveAnimation.asset(
      "$baseRivePath/character_jumping_icecream.riv",
      // stateMachines: const ['State Machine 1'],
      animations: const ["idle"],
      onInit: (Artboard art) {
        // controller = StateMachineController.fromArtboard(art, 'State Machine 1')!;
        // controller.isActive = true;
        // art.addController(controller);
        // smiOn = controller.findInput<bool>('Scoop 1') as SMIBool;
        // smiHover = controller.findInput<bool>('Hover') as SMIBool;
        // smiOn.value = true;
      },
    );
  }
}
