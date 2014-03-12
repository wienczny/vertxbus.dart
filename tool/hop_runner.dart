import 'dart:async';
import 'dart:io';
import 'package:hop/hop.dart';
import 'package:hop/hop_tasks.dart';

void main(List<String> args) {

  //addTask('test', createUnitTestTask());

  addTask('test', createUnitTestTask());

  //
  // Analyzer
  //
  addTask('analyze_libs', createAnalyzerTask(_getLibs));

  runHop(args);
}


Future<List<String>> _getLibs() {
  return new Directory('lib').list()
      .where((FileSystemEntity fse) => fse is File)
      .map((File file) => file.path)
      .toList();
}

Task createUnitTestTask() {
  final allPassedRegExp = new RegExp('All \\d+ tests passed');
  return new Task((TaskContext ctx){
    ctx.info("Running Unit Tests....");
    var result = Process.run('content_shell',['--dump-render-tree','test/headless_test.html']).then((ProcessResult process){
      ctx.info(process.stdout);
      var res = allPassedRegExp.hasMatch(process.stdout);
      
      if (!res) {
        ctx.fail("Not all matched");
      }
    });
    return result;
  });
}