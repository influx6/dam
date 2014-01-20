import 'dart:io';
import 'package:path/path.dart' as path;
import 'dart:async';

// simple cmd tool to create and link dart library structure
final platform = Platform.environment;
//final packages = new Path(platform['HOME'].concat('/Pubpackages'));
final home = path.normalize(Directory.current.path);
final packages = path.join(home,"packages");
final makeOption = new RegExp(r'^\w+:');
final license = """
The MIT License (MIT)

Developer: @name
Email: @email
Copyright (c) ${new DateTime.now().year};

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
""";
final help = """Dam Version: 0.0.1

Details: Due to the cumbersome recurring case of dealing with packages folder and the fact that pub unlike
like node transverse the folder tree for a packages folder,i decided to create this small utility that 
provides these needs with the exception that instead of transversing we instead run the dam command at the library root 
folder and either add a folder,init a new packages folder or create a new project libary

Options:
""";
final inithelp = """
  :init (creates a new dart packages folder if it exists do nothing)
""";
final makehelp = """
  :create (creates a new dart package folder with the linked packages folder)
        eg. dam :create name:'hello' desc:'say hello' dirs:lib,spec,framework
    note: please ensure to follow the order as above.
""";
// final linkhelp = """
//   :link (simple links into the directory the global packages folder)
// """;
final addhelp = """
  :add (add a new dir that will be linked with the packages folder)
        eg. dam :add framework,extensions,apps
""";
final pubtemp = """
name: @name
version: 0.0.1
author: Developer <@email>
repository: @repository
homepage: @homepage
description: @description
dependencies:
""";

void makeDir(String paths,[void callback(d)]){
  new Directory(paths).create(recursive:true).then((dir){
    print("---> Adding $dir!");
        if(callback != null) callback(dir);
  });
}

void createPubSpec(String paths,data){
  try{
      var spec = new File(path.join(paths,'pubspec.yaml')).openWrite();
      var lic = new File(path.join(paths,'LICENSE')).openWrite();
      spec.write(data);
    lic.write(license);
      print('Adding pubspec.yaml to $paths');
      print('Adding LICENSE to $paths');
      spec.close();
    lic.close();
  }catch(e){
      print(e);
      throw new Exception('Error creating pubspec.yaml and LICENSE!');
  }
}

void make(List args){
      if(args.isEmpty || args.length > 3) return (print('$makehelp \n Incorrect Arguments Passed! '));
      var hasDesc = (args.length >= 2 && new RegExp(r'^desc:').hasMatch(args[1])) ? true : false;
      var hasDirs = (args.length >= 3 && new RegExp(r'^dirs:').hasMatch(args[2])) ? true : false;
      
      var projName = args[0].split(':')[1];
      var projDesc = hasDesc ? args[1].split(':')[1] : null;
      var projDirs = hasDirs ? args[2].split(':')[1].split(','): null;
      var template = pubtemp;

      template = template.replaceAll('@name',projName);
      if(hasDesc) template = template.replaceAll('@description',projDesc);
      
      var ghome = path.join(home,projName);
      makeDir(ghome,(dir){
        var route = dir.path;
        var pkgs = path.join(route,"packages");
        makeDir(pkgs);
        createPubSpec(route,template);
        if(hasDirs){
            projDirs.forEach((n){
              makeDir(path.join(route,n),(dirs){
              link(dirs.path,pkgs);
            });
          });
        }
      });
}

void addDir(List args){
    if(args.isEmpty) return print(addhelp);
  var lists = args.first.split(',');
  if(!new Directory(packages).existsSync()) return print("packages folder does not exist here!");
    lists.forEach((n){
    makeDir(path.join(home,n),(dir){
          link(dir.path);
      });
  });
}

void link(paths,[String fr]){
    var loc = null; var from = (fr != null) ? fr : packages;
  if(paths is String) loc = paths;
  else loc = home;
  
    try{
         var hr = path.join(loc,"packages");
         var ln = new Link(hr);
         ln.createSync(from.toString());
         print('---> Adding SymLink for packages as ${ln.path}!');
    }catch(e){
         print('Unable to create symlink for packages or a folder/symlink with the same name exists!');
    }
}

void init(){
    var pac = new Directory(packages);
    if(!pac.existsSync()) pac.createSync(recursive:false);
}

void printHelp(){
      print(help);
      print(inithelp);
      print(makehelp);
      print(addhelp);
}

void main(List<String> arguments){

    //init();
  
    var ops = new List.from(arguments);
    if(ops.length <= 0) return printHelp(); 

    var cmd = ops.first;

    ops.remove(cmd);

    switch(cmd){
        case ':init':
               init();
               break;
        // case ':link':
        //        link(home.toString());
        //        break;
        case ':create':
               make(ops);
               break;
        case ':add':
               addDir(ops);
               break;
        default:
               printHelp();
               break;
    }
}
