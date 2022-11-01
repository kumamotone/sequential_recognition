import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:simple_ripple_animation/simple_ripple_animation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomeTabPage extends HookConsumerWidget {
  const HomeTabPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const MyApp();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class StatusController extends StateNotifier<String> {
  StatusController(String state) : super(state);

  void add(String e) {
    state = e;
  }
}

class ErrorController extends StateNotifier<SpeechRecognitionError> {
  ErrorController(SpeechRecognitionError state) : super(state);

  void add(SpeechRecognitionError e) {
    state = e;
  }
}

class WordsController extends StateNotifier<List<String>> {
  WordsController(List<String> state) : super(state);

  void add(String e) {
    final newState = [...state];
    newState.add(e);
    state = newState;
  }

  void clear() {
    state = [];
  }
}

final wordsProvider = StateNotifierProvider<WordsController, List<String>>(
    (ref) => WordsController([]));
final errorsProvider =
    StateNotifierProvider<ErrorController, SpeechRecognitionError>((ref) =>
        ErrorController(SpeechRecognitionError("initializing...", false)));
final statusesProvider = StateNotifierProvider<StatusController, String>(
    (ref) => StatusController('notListening'));

final speechProvider = StateProvider((ref) => SpeechToText());

final recognitionServiceProvider =
    StateProvider((ref) => SpeechRecognitionService(ref));

class SpeechRecognitionService {
  SpeechRecognitionService(this.ref);

  final Ref ref;
  late SpeechToText speech = ref.watch(speechProvider);
  var _localeId = '';

  Future<bool> initSpeech() async {
    bool hasSpeech = await speech.initialize(
      onError: errorListener,
      onStatus: statusListener,
    );

    if (hasSpeech) {
      var systemLocale = await speech.systemLocale();
      _localeId = systemLocale?.localeId ?? "";
    }

    return hasSpeech;
  }

  void startListening() {
    speech.stop();
    speech.listen(
        onResult: resultListener,
        listenFor: const Duration(minutes: 1),
        localeId: _localeId,
        onSoundLevelChange: null,
        listenMode: ListenMode.search,
        cancelOnError: true,
        partialResults: true);
  }

  void errorListener(SpeechRecognitionError error) {
    final errors = ref.watch(errorsProvider.notifier);
    print(errors.state);
    errors.add(error);
  }

  void statusListener(String status) {
    final statuses = ref.watch(statusesProvider.notifier);
    print(status);
    statuses.add(status);
  }

  void resultListener(SpeechRecognitionResult result) {
    final words = ref.watch(wordsProvider.notifier);
    print(result.alternates.first);
    print(result.finalResult);
    // RegExp exp = RegExp(r"([0-9]|1[0-9]|2[0-3])時([0-9]|[0-5][0-9])分");
    RegExp exp = RegExp(
        r"(1[0-2]|[1-9])月(3[0-1]|2[0-9]|1[0-9]|[1-9])日([^0-9]*)(([0-9]|,)+)円");
    final matches = exp.allMatches(result.alternates.first.recognizedWords);

    // make list
    var l = [];
    for (var m in matches) {
      l.add("${m[1]}月${m[2]}日\t ${m[3]}\t${m[4]?.replaceAll(',', '')}円");
    }

    words.add(l.join("\n"));
  }

  void stopListening() {
    speech.stop();
  }

  void cancelListening() {
    speech.cancel();
  }
}

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recognitionService = ref.watch(recognitionServiceProvider);
    final speechEnabled = useFuture(useMemoized(recognitionService.initSpeech),
        initialData: false);
    List<String> words = ref.watch(wordsProvider);
    String status = ref.watch(statusesProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "医療費集計フォームつくる",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32.0, 8.0, 32.0, 8.0),
                    child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.all(16),
                        child: speechEnabled.hasData
                            ? AutoSizeText(
                                words.toString(),
                                style: TextStyle(fontSize: 14),
                              )
                            : Text("")
                        // : (speechEnabled.hasData && speechEnabled.data!)
                        //     ? 'Tap the microphone to start listening...'
                        //     : 'Speech not available',
                        // ),
                        ),
                  ),
                ),
              ),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: status != 'listening'
                          ? Ink(
                              decoration: const ShapeDecoration(
                                color: Colors.lightBlue,
                                shape: CircleBorder(),
                              ),
                              child: IconButton(
                                  iconSize: 64,
                                  onPressed: () {
                                    recognitionService.startListening();
                                  },
                                  icon: Icon(Icons.mic_off)),
                            )
                          : RippleAnimation(
                              repeat: true,
                              color: Colors.blue,
                              minRadius: 60,
                              ripplesCount: 6,
                              child: Ink(
                                decoration: const ShapeDecoration(
                                  color: Colors.lightBlue,
                                  shape: CircleBorder(),
                                ),
                                child: IconButton(
                                    iconSize: 64,
                                    onPressed: recognitionService.stopListening,
                                    icon: Icon(Icons.mic_rounded)),
                              ),
                            ),
                    ),
                    IconButton(
                        onPressed: () {
                          final w = ref.read(wordsProvider.notifier);
                          w.clear();
                        },
                        icon: const Icon(Icons.delete))
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    status != "listening" ? "タップして音声認識を開始" : "タップして音声認識を終了"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
