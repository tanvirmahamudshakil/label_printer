import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_label_printer/printer/hanin_cpcl_printer.dart';
import 'package:flutter_label_printer/printer/hanin_tspl_printer.dart';
import 'package:flutter_label_printer/printer_search_result/printer_search_result.dart';
import 'package:flutter_label_printer/printer_searcher/usb_printer_searcher.dart';
import 'package:flutter_label_printer/templating/printer_template/hanin_cpcl_template_printer.dart';
import 'package:flutter_label_printer/templating/printer_template/hanin_tspl_template_printer.dart';
import 'package:flutter_label_printer/templating/printer_template/image_template_printer.dart';
import 'package:label_printer/addbarcode.dart';
import 'package:label_printer/main.dart';
import 'package:label_printer/qrcoide.dart';

enum PrinterModel { cpcl, tspl, image }

class PrinterPage extends StatefulWidget {
  const PrinterPage({super.key});

  @override
  State<PrinterPage> createState() => _PrinterPageState();
}

class _PrinterPageState extends State<PrinterPage> {
  final UsbPrinterSearcher _usbSearcher = UsbPrinterSearcher();

  List<PrinterSearchResult> _searchResults = [];
  bool _searching = false;
  bool _connected = false;
  final connectIndexController = TextEditingController();

  String _exceptionText = '';

  @override
  void dispose() {
    connectIndexController.dispose();
    super.dispose();
  }

  PrinterModel _printerModel = PrinterModel.image;

  StreamSubscription<List<PrinterSearchResult>>? _usbSearchSubscription;
  Future<void> _startUsbSearch() async {
    try {
      setState(() {
        _searching = true;
      });

      _usbSearchSubscription = _usbSearcher.search().listen((event) {
        setState(() {
          _searchResults = event;
        });
      });
    } catch (ex, st) {
      print('Exception: $ex\n$st');
      setState(() {
        _exceptionText = ex.toString();
      });
    }
  }

  Future<void> _stopUsbSearch() async {
    try {
      _usbSearchSubscription?.cancel();
      setState(() {
        _searching = false;
      });
    } catch (ex, st) {
      print('Exception: $ex\n$st');
      setState(() {
        _exceptionText = ex.toString();
      });
    }
  }

  Future<void> _connect() async {
    try {
      switch (_printerModel) {
        case PrinterModel.cpcl:
          PrinterSearchResult? result = _searchResults[int.parse(connectIndexController.text)];

          MyApp.printer = HaninCPCLTemplatePrinter(result);
          break;
        case PrinterModel.tspl:
          PrinterSearchResult? result = _searchResults[int.parse(connectIndexController.text)];

          MyApp.printer = HaninTSPLTemplatePrinter(result);
          break;
        case PrinterModel.image:
          MyApp.printer = ImageTemplatePrinter("/output.png");
          break;
      }

      await MyApp.printer?.connect();
      setState(() {
        _connected = true;
      });
    } catch (ex, st) {
      print('Exception: $ex\n$st');
      setState(() {
        _exceptionText = ex.toString();
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await MyApp.printer?.disconnect();
      setState(() {
        _connected = false;
      });
    } catch (ex, st) {
      print('Exception: $ex\n$st');
      setState(() {
        _exceptionText = ex.toString();
      });
    }
  }

  Future<void> _getStatus(BuildContext context) async {
    try {
      dynamic result;
      switch (_printerModel) {
        case PrinterModel.cpcl:
          result = await (MyApp.printer as HaninCPCLPrinter).getStatus();
          break;
        case PrinterModel.tspl:
          result = await (MyApp.printer as HaninTSPLPrinter).getStatus();
          break;
        case PrinterModel.image:
          break;
      }

      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(title: Text('Status = $result'));
          });
    } catch (ex, st) {
      print('Exception: $ex\n$st');
      setState(() {
        _exceptionText = ex.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('flutter_label_printer example app'),
          ),
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewportConstraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      Text('Exception = $_exceptionText'),
                      ElevatedButton(onPressed: _startUsbSearch, child: const Text('Start USB search')),
                      Text('Searching = $_searching'),
                      Text('Search Result = ${_searchResults.toString()}\n'),
                      ElevatedButton(onPressed: _stopUsbSearch, child: const Text('Stop USB search')),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Index of Search result to Connect Bluetooth to',
                        ),
                        keyboardType: TextInputType.number,
                        controller: connectIndexController,
                      ),
                      DropdownButton<PrinterModel>(
                          items: const [
                            DropdownMenuItem(
                              value: PrinterModel.cpcl,
                              child: Text('Hanin CPCL (e.g. HM-A300L)'),
                            ),
                            DropdownMenuItem(
                              value: PrinterModel.tspl,
                              child: Text('Hanin TSPL (e.g. N31)'),
                            ),
                            DropdownMenuItem(
                              value: PrinterModel.image,
                              child: Text('Image'),
                            ),
                          ],
                          value: _printerModel,
                          onChanged: (value) {
                            setState(() {
                              _printerModel = value ?? PrinterModel.cpcl;
                            });
                          }),
                      ElevatedButton(onPressed: _connect, child: const Text('Connect')),
                      Text('Connected = $_connected\n'),
                      ElevatedButton(onPressed: () => _getStatus(context), child: const Text('Get Status')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddBarcode()));
                          },
                          child: const Text('Add Barcode')),
                      ElevatedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddQRCode()));
                          },
                          child: const Text('Add QRCode')),
                      ElevatedButton(onPressed: _disconnect, child: const Text('Disconnect')),
                    ],
                  ),
                ),
              );
            },
          )),
    );
  }

  Widget printerModel() {
    return DropdownButton<PrinterModel>(
        items: const [
          DropdownMenuItem(
            value: PrinterModel.cpcl,
            child: Text('Hanin CPCL (e.g. HM-A300L)'),
          ),
          DropdownMenuItem(
            value: PrinterModel.tspl,
            child: Text('Hanin TSPL (e.g. N31)'),
          ),
          DropdownMenuItem(
            value: PrinterModel.image,
            child: Text('Image'),
          ),
        ],
        value: _printerModel,
        onChanged: (value) {
          setState(() {
            _printerModel = value ?? PrinterModel.cpcl;
          });
        });
  }
}
