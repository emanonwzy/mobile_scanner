import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner_example/barcode_fetcher.dart';
import 'package:html/parser.dart' show parse;

class BarcodeScannerReturningImage extends StatefulWidget {
  const BarcodeScannerReturningImage({Key? key}) : super(key: key);

  @override
  _BarcodeScannerReturningImageState createState() =>
      _BarcodeScannerReturningImageState();
}

class _BarcodeScannerReturningImageState
    extends State<BarcodeScannerReturningImage>
    with SingleTickerProviderStateMixin {
  BarcodeCapture? barcode;
  MobileScannerArguments? arguments;

  MobileScannerController controller = MobileScannerController(
    // torchEnabled: true,
    returnImage: true,
    // formats: [BarcodeFormat.qrCode]
    // facing: CameraFacing.front,
  );

  bool isStarted = true;
  String isbnContent = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Builder(
        builder: (context) {
          return Column(
            children: [
              Container(
                color: Colors.blueGrey,
                width: double.infinity,
                height: 0.33 * MediaQuery.of(context).size.height,
                // child: barcode?.image != null
                //     ? Transform.rotate(
                //         angle: 90 * pi / 180,
                //         child: Image(
                //           gaplessPlayback: true,
                //           image: MemoryImage(barcode!.image!),
                //           fit: BoxFit.contain,
                //         ),
                //       )
                //     : const ColoredBox(
                //         color: Colors.white,
                //         child: Center(
                //           child: Text(
                //             'Your scanned barcode will appear here!',
                //           ),
                //         ),
                //       ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Text(isbnContent),
                  ),
                ),
              ),
              Container(
                height: 0.66 * MediaQuery.of(context).size.height,
                color: Colors.grey,
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: controller,
                      fit: BoxFit.contain,
                      // allowDuplicates: true,
                      // controller: MobileScannerController(
                      //   torchEnabled: true,
                      //   facing: CameraFacing.front,
                      // ),
                      onDetect: (barcode, arguments) async {
                        this.arguments = arguments;
                        this.barcode = barcode;

                        if (this.barcode?.barcodes.first.rawValue != null) {
                          final _isbnContent = await fetchIsbn(
                            (this.barcode?.barcodes.first.rawValue)!,
                          );
                          var document = parse(_isbnContent);
                          final element = document
                              .getElementsByClassName("result")[0]
                              .children[1];

                          final title = element.children[0];
                          final abstractContent = element.children[1].innerHtml;

                          final buffer = StringBuffer();
                          buffer.write(title);
                          // buffer.write(element.outerHtml);
                          // for (final element in element.children) {
                          //   buffer.write(element.className);
                          //   buffer.write("\n");
                          //   buffer.write(element.attributes);
                          //   buffer.write("\n\n");
                          // }
                          setState(() {
                            isbnContent = buffer.toString();
                          });
                        }
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        height: 100,
                        color: Colors.black.withOpacity(0.4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ColoredBox(
                              color: arguments != null && !arguments!.hasTorch
                                  ? Colors.red
                                  : Colors.white,
                              child: IconButton(
                                // color: ,
                                icon: ValueListenableBuilder(
                                  valueListenable: controller.torchState,
                                  builder: (context, state, child) {
                                    if (state == null) {
                                      return const Icon(
                                        Icons.flash_off,
                                        color: Colors.grey,
                                      );
                                    }
                                    switch (state as TorchState) {
                                      case TorchState.off:
                                        return const Icon(
                                          Icons.flash_off,
                                          color: Colors.grey,
                                        );
                                      case TorchState.on:
                                        return const Icon(
                                          Icons.flash_on,
                                          color: Colors.yellow,
                                        );
                                    }
                                  },
                                ),
                                iconSize: 32.0,
                                onPressed: () => controller.toggleTorch(),
                              ),
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: isStarted
                                  ? const Icon(Icons.stop)
                                  : const Icon(Icons.play_arrow),
                              iconSize: 32.0,
                              onPressed: () => setState(() {
                                isStarted
                                    ? controller.stop()
                                    : controller.start();
                                isStarted = !isStarted;
                              }),
                            ),
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 200,
                                height: 50,
                                child: FittedBox(
                                  child: Text(
                                    barcode?.barcodes.first.rawValue ??
                                        'Scan something!',
                                    overflow: TextOverflow.fade,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headline4!
                                        .copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              color: Colors.white,
                              icon: ValueListenableBuilder(
                                valueListenable: controller.cameraFacingState,
                                builder: (context, state, child) {
                                  if (state == null) {
                                    return const Icon(Icons.camera_front);
                                  }
                                  switch (state as CameraFacing) {
                                    case CameraFacing.front:
                                      return const Icon(Icons.camera_front);
                                    case CameraFacing.back:
                                      return const Icon(Icons.camera_rear);
                                  }
                                },
                              ),
                              iconSize: 32.0,
                              onPressed: () => controller.switchCamera(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
