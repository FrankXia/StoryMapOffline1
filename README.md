StoryMapOffline1
================

This iOS native app is for viewing Story Maps offline. It will start as online and then automatically download all the contents to local disk. 

The app will take a story map url from stprymaps.arcgis.com and either get the webmap id from the url or extract the webmap id from 
the index.html page. Once it gets the webmap id, it will load the features used for the story map and save them to the local disk
including pictures (videos aren't supported) and descriptions. The UI looks very close to the web app version. Once the app initialized, 
you can view the story map just like you would do with its web counterpart. The map tiles will be dynamically downloaded when the 
map is zooming and panning around. 

Once you have gone through the whole story map, you can set your iPad to airplane mode, the app will start work. 
