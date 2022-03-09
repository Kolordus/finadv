import 'package:finadv/model/FinanceEntry.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StepperInputScreenForFinance extends StatefulWidget {
  final String personName;
  final DateTime now;

  StepperInputScreenForFinance(this.personName, this.now);

  @override
  State<StatefulWidget> createState() => _StepperInputScreenForFinanceState();
}

class _StepperInputScreenForFinanceState extends State<StepperInputScreenForFinance> {
  var _currentStep = 0;
  TextEditingController operationNameController = TextEditingController();
  TextEditingController zlAmountController = TextEditingController();
  TextEditingController grAmountController = TextEditingController();

  tapped(int step) {
    setState(() => _currentStep = step);
  }

  continued() {
    var isFinalStep = _currentStep == stepList().length - 1;
    if (isFinalStep) {
      int zl = int.parse(zlAmountController.text) * 100;
      int gr = int.parse(grAmountController.text);
      int fullAmount = zl + gr;

      var financeEntry = FinanceEntry(widget.personName,
          widget.now.toString(),
          operationNameController.text,
          fullAmount);

      Navigator.pop(context);
    }
    _currentStep < 2 ? setState(() => {_currentStep += 1}) : null;
  }

  cancel() {
    _currentStep > 0 ? setState(() => _currentStep -= 1) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stepper(
        physics: ScrollPhysics(),
        currentStep: _currentStep,
        onStepTapped: (step) => tapped(step),
        onStepContinue: continued,
        onStepCancel: cancel,
        steps: stepList(),
        controlsBuilder: (context, controlsDetails) {
          var isFinalStep = _currentStep == stepList().length - 1;
          return Container(
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: continued,
                    child:
                        isFinalStep ? const Text("Finish") : const Text("Next"),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                if (_currentStep > 0)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: cancel,
                      child: const Text('Back'),
                    ),
                  )
              ],
            ),
          );
        },
      ),
    );
  }

  List<Step> stepList() => [
        Step(
          title: Text("Nazwa Operacji"),
          content: Column(
            children: [
              TextField(decoration: InputDecoration(hintText: "Nazwa operacji"), controller: operationNameController),
            ],
          ),
          isActive: _currentStep >= 0,
          state: _currentStep >= 0 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: Text("Kwota"),
          content: Column(
            children: [
              TextField(decoration: InputDecoration(hintText: "złotych"), controller: zlAmountController, inputFormatters: [FilteringTextInputFormatter.digitsOnly],),
              TextField(decoration: InputDecoration(hintText: "groszy"), controller: grAmountController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
            ],
          ),
          isActive: _currentStep >= 1,
          state: _currentStep >= 1 ? StepState.complete : StepState.disabled,
        ),
        Step(
          title: Text("Podsumowanie"),
          content: Column(
            children: [
              Text(widget.now.toLocal().toString().substring(0, 16)),
              Text(operationNameController.text),
              Text((int.parse(zlAmountController.text)).toString() + ',' + (int.parse(grAmountController.text)).toString() + " PLN"
              ),

            ],
          ),
          isActive: _currentStep >= 2,
          state: StepState.complete,
        )
      ];
}
