import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WebView 초기화
  if (Platform.isAndroid) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: WebViewScreen());
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebView 예제')),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri('http://222.100.172.236:3000')),
        initialSettings: InAppWebViewSettings(
          javaScriptCanOpenWindowsAutomatically: true,
          javaScriptEnabled: true,
          useOnDownloadStart: true,
          useOnLoadResource: true,
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: true,
          allowFileAccessFromFileURLs: true,
          allowUniversalAccessFromFileURLs: true,
          verticalScrollBarEnabled: true,
          userAgent:
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.122 Safari/537.36',
        ),
        onReceivedError: (controller, request, error) {
          print('WebView 오류: ${error.description}');
          // 오류 메시지를 화면에 표시할 수도 있습니다
        },
        onWebViewCreated: (controller) {
          // 웹뷰 컨트롤러를 저장하여 나중에 사용할 수 있습니다
          print('WebView created $controller');
        },
        onLoadStart: (controller, url) {
          // 페이지 로딩 시작 시 호출
        },
        onLoadStop: (controller, url) {
          // 페이지 로딩 완료 시 호출
        },
      ),
    );
  }
}
