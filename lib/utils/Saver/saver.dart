import "dart:convert";
import "package:web/web.dart";

class Data{
  final String _name;
  final String _surname;

  Data(this._name, this._surname);

}

void writeToFile(String name, String surname) async{
  int count = 0;
  String? countS = window.localStorage.getItem("count");
  if(countS != null){
    count = int.parse(countS);
    count++;
  }

  var save = {'name' : '$name', 'surname' : '$surname'};
  final String json = jsonEncode(save);
  print(json);
  window.localStorage.setItem("$count", json);
  window.localStorage.setItem("count", count.toString());
  print("Saved");
}

void readFromFile() {
  String? item = window.localStorage.getItem("count");
  if(item == null){
    return;
  }
  int count = int.parse(item);
  for(int i = 0; i <= count; i++){
    String? entry = window.localStorage.getItem("$i");
    print(entry);
  }
}