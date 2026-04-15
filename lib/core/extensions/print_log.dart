import 'dart:developer';

extension Log on Object? {
  void printInfo({String tag = 'PURE PATH'}) {
    log('$this', name: tag);
  }

  void printError({String tag = 'ERROR LOG'}) {
    log('$this', name: tag);
  }
}
