// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:developer';

// import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
    getfromServer();
  }

  bool isLoading = false;
  Uint8List? bytes;
  List<Uint8List>? imageList;
  String url = "http://127.0.0.1:4044";
  List<String> imagePaths = [];
  List<Uint8List> imagePathsByte = [];

  Future<void> uploadToServer() async {
    try {
      final image = await FilePicker.platform.pickFiles(type: FileType.image);
      if (image != null) {
        String path = kIsWeb ? image.files.first.name : image.files.first.path!;
        log('path is $path');
        // File file = File(path);
        http.MultipartRequest request =
            http.MultipartRequest("POST", Uri.parse("$url/upload"));
        // http.MultipartFile multipartFile =
        //     await http.MultipartFile.fromPath('image', file.path);
        http.MultipartFile multipartFile = kIsWeb
            ? http.MultipartFile.fromString(path, path)
            : await http.MultipartFile.fromPath('image', path);
        request.files.add(multipartFile);
        // request.headers.addAll(_header());
        // request.fields.addAll(data);
        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        log("response ${response.contentLength}");
        // imagePaths.add(response.body);
        imagePathsByte.add(response.bodyBytes);
        // log("response ${imagePathsByte.length}");
        setState(() {});
        // print(jsonDecode(response.body));
        log(image.files.first.name);
        // File
      }
    } on Exception catch (e) {
      log(e.toString());
    }
  }

  Future<void> getfromServer() async {
    try {
      // final response = await http.get(Uri.parse(url));

      // if (response.statusCode == HttpStatus.ok) {
      // bytes = response.bodyBytes;
      // setState(() {});
      setState(() => isLoading = true);
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      List<dynamic> imageList =
          (data['dataBytes'] as List).map((e) => e).toList();
      List<String> imageListData = List<String>.from(data['data']);
      imagePaths.addAll(imageListData);
      imagePathsByte.addAll(
        imageList.map(
          (e) => Uint8List.fromList(
            (e as List).map((e) => e as int).toList(),
          ),
        ),
      );
    } on Exception catch (e) {
      log("Talk $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteFromServer(
      BuildContext context, String path, int index) async {
    imagePaths.remove(path);
    imagePathsByte.removeAt(index);
    setState(() {});
    final body = {'image': path};
    final response = await http.post(
      Uri.parse('$url/delete'),
      body: jsonEncode(body),
    );
    log(response.body);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Image Deleted')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: uploadToServer,
                      child: const Text('Upload Image from file'),
                    ),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Take  Image from camera'),
                    ),
                  ),
                ],
              ),
            ),
            bytes != null ? Image.memory(bytes!) : const SizedBox(),
            Expanded(
              child: Builder(builder: (context) {
                if (isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return GridView.builder(
                    itemCount: imagePathsByte.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 3,
                      mainAxisSpacing: 3,
                      childAspectRatio: 0.9,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final image = imagePathsByte[index];
                      // final imagePath = imagePaths[index];
                      return GridItem(
                        image: image,
                        onDelete: () =>
                            deleteFromServer(context, 'imagePath', index),
                      );
                    });
              }),
            )
          ],
        ),
      ),
    );
  }
}

class GridItem extends StatefulWidget {
  const GridItem({
    super.key,
    required this.image,
    required this.onDelete,
  });
  final Uint8List image;
  final Function() onDelete;

  @override
  State<GridItem> createState() => _GridItemState();
}

class _GridItemState extends State<GridItem> {
  bool isEditing = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        setState(() {
          isEditing = !isEditing;
        });
      },
      onTap: () {
        if (isEditing) {
          setState(() {
            isEditing = !isEditing;
          });
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.memory(
            (widget.image),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.red,
              );
            },
          ),
          Visibility(
            visible: isEditing,
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                height: 20,
                width: 20,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => widget.onDelete(),
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
