StoryMapOffline1
================

This iOS native app is for viewing Story Maps offline. It will start as online and then automatically download all the contents to local disk. 

The app will take a story map url from stprymaps.arcgis.com and either get the webmap id from the url or extract the webmap id from 
the index.html page. Once it gets the webmap id, it will load the features used for the story map and save them to the local disk
including pictures (videos aren't supported) and descriptions. The UI looks very close to the web app version. Once the app initialized, 
you can view the story map just like you would do with its web counterpart. The map tiles will be dynamically downloaded when the 
map is zooming and panning around. 

Once you have gone through the whole story map, you can set your iPad to airplane mode, the app will start work. 

## Features
* Take story map offline. This app doesn't use the ArcGIS iOS SDK's offline capability. It has its own caching, so it works with Basic License. 

## Instructions
* Open the app and touch the "esri' icon on the up-right corner. A dialog window will be dislayed, where you type or copy a story map url there and tap "Go" button to initialize the story map. There is default story url in the url bar to let you test the app. 
* Once you add more than one story maps to the app, all of them will be listed in the dialog window and you tap one of them to show it. 

## Requirements
XCode 

## Resources
[ArcGIS for iOS API Resource Center] (http://developers.arcgis.com/en/ios/)

## Issues

Find a bug or want to request a new feature?  Please let us know by submitting an issue.

## Contributing

Esri welcomes contributions from anyone and everyone. Please see our [guidelines for contributing](https://github.com/esri/contributing).

## Licensing
Copyright 2013 Esri

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

A copy of the license is available in the repository's [license.txt]( https://raw.github.com/Esri/quickstart-map-js/master/license.txt) file.

[](Esri Tags: ArcGIS iOS SDK)
[](Esri Language: Objective-C)​
