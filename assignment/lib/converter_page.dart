import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() {
    return _ConverterPageState();
  }
}

class _ConverterPageState extends State<ConverterPage> {
  TextEditingController controller = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  double result = 0;
  double rate = 0;

  bool isLoading = false;

  String fromCurrency = "USD";
  String toCurrency = "BDT";

  final List<String> currencies = [
    "USD",
    "BDT",
    "AUD",
    "EUR",
    "GBP",
    "INR",
    "CAD",
    "JPY",
    "CNY",
    "SAR",
    "AED",
  ];

  Future<void> convertCurrency() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      double amount = double.parse(controller.text);

      final url = Uri.parse("https://open.er-api.com/v6/latest/$fromCurrency");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        rate = data["rates"][toCurrency];

        result = amount * rate;

        setState(() {});
      } else {
        showMessage("Failed to load currency rate");
      }
    } catch (e) {
      showMessage("Something went wrong. Check internet connection.");
    }

    setState(() {
      isLoading = false;
    });
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Converter Page", style: GoogleFonts.lora()),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.amber,
      ),
      body: Center(
        child: SizedBox(
          height: 500,
          width: 330,
          child: Card(
            color: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Currency Converter",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.amber,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: fromCurrency,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "From",
                            labelStyle: TextStyle(color: Colors.amber),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber),
                            ),
                          ),
                          items: currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              fromCurrency = value!;
                            });
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      const Icon(Icons.swap_horiz, color: Colors.white),

                      const SizedBox(width: 10),

                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: toCurrency,
                          dropdownColor: Colors.grey[900],
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: "To",
                            labelStyle: TextStyle(color: Colors.amber),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.amber),
                            ),
                          ),
                          items: currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              toCurrency = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Field is empty";
                        }

                        if (double.tryParse(value) == null) {
                          return "Enter a valid number";
                        }

                        return null;
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(
                          Icons.monetization_on_sharp,
                          color: Colors.amber,
                        ),
                        hintText: "Enter Amount",
                        hintStyle: TextStyle(color: Colors.white),
                        labelText: "Amount",
                        labelStyle: TextStyle(color: Colors.amber),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(50)),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: isLoading ? null : convertCurrency,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 12,
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            "Convert",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "$toCurrency: ${result.toStringAsFixed(2)}",
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
