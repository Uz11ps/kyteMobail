// Stub для не-веб платформ
// Этот файл используется вместо dart:html на мобильных и desktop платформах

// Экспортируем классы с префиксом html
library html_stub;

class FileUploadInputElement {
  String? accept;
  List<File>? files;
  
  void click() {}
  
  Stream<dynamic> get onChange => const Stream.empty();
}

class File {
  String name;
  int size;
  String type;
  
  File(this.name, this.size, this.type);
}

class FileReader {
  void readAsDataUrl(File file) {}
  void readAsArrayBuffer(File file) {}
  dynamic result;
  
  Stream<dynamic> get onLoadEnd => const Stream.empty();
  Stream<dynamic> get onError => const Stream.empty();
}
