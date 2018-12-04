# Creating City Blocks in 3ds Max - Part 25 - Creating Building Libraries with Building Maker

By 

[Melissa Lax](https://area.autodesk.com/profile/HxmMtmu0/tutorials/) 

https://area.autodesk.com/tutorials/3ds-max-creating-city-blocks-creating-building-libraries-with-building-maker-part-25/

# Creating City Blocks in 3ds Max - Part 25 - Creating Building Libraries with Building Maker 

#### In this tutorial, you turn your building creations into simple editable polys to reduce calculating time. You have the options of creating in-project duplicates or exporting and storing them as external files to use with other projects and other 3D applications if you so choose.



<iframe src="https://www.youtube.com/embed/x64RzkNWmeQ?enablejsapi=1&amp;origin=https://area.autodesk.com" frameborder="0" allowfullscreen="true" data-wat-video-found="true" id="waf_detected_youtube0" style="-webkit-tap-highlight-color: rgba(0, 0, 0, 0); overflow-wrap: break-word; word-break: break-word; hyphens: none; position: absolute; top: 0px; left: 0px; width: 1120px; height: 655px;"></iframe>





[Download Package Assets](http://areadownloads.autodesk.com/wdm/3dsmax/HTM-PRJ_cityblks-bldgs.zip)

Notes

- Recorded in: 3ds Max 2014
- Scripts used: <http://areadownloads.autodesk.com/wdm/3dsmax/HTM-PRJ_cityblks-BMscripts.zip>
- This tutorial is intended for use with 3ds Max version 2014 or higher.

Transcript

```
1
00:00:06,583 --> 00:00:09,286
Continue working on your file from the last movie.

2
00:00:09,646 --> 00:00:16,867
If you need to, you can also use the file named CityBlocks_Bldgs-bake.max you downloaded for this tutorial.

3
00:00:17,477 --> 00:00:25,443
As you work with Building Maker, each element you create at any given level carries with it a fair number of modifiers and other constraints.

4
00:00:25,978 --> 00:00:32,433
These are essential for Building Maker to work properly, but do require a fair amount of calculations to process.

5
00:00:32,746 --> 00:00:40,419
For that reason, you can help with calculation time by stripping the building down to a poly object when you are done with the design.

6
00:00:40,907 --> 00:00:44,605
Remember to do this only when the design is complete.

7
00:00:45,358 --> 00:00:51,264
To extract a building as a separate poly object, you start by selecting any part of it.

8
00:00:51,889 --> 00:00:57,037
You then use the Bake Building button in the Building Maker UI. A dialog appears.

9
00:00:57,364 --> 00:01:07,334
Here, you have two options: One option is the Bake button, which extracts all the building information into an in-project editable poly.

10
00:01:08,036 --> 00:01:11,326
You can then place that duplicate anywhere you want.

11
00:01:16,497 --> 00:01:23,885
Note that the duplicated building has no connection to the Building Maker interface and cannot be edited that way.

12
00:01:26,256 --> 00:01:34,804
The original building is still in place. If you do not need it anymore, select any part of it and use the Delete Building button to remove it.

13
00:01:35,339 --> 00:01:39,365
A warning reminds you that this operation cannot be undone.

14
00:01:43,265 --> 00:01:48,157
The other method of baking a building is the Bake and Export to FBX method.

15
00:01:48,547 --> 00:01:56,239
The advantage of this method is that it lets you store individual buildings OR groups of buildings externally as FBX files.

16
00:01:56,708 --> 00:02:03,044
This means you can use Import procedures to reimport them into 3ds Max or other 3D applications.

17
00:02:03,574 --> 00:02:09,982
Try it on the high rise. Select an element of that building, and then click the Bake and Export to FBX button.

18
00:02:10,372 --> 00:02:15,213
You are prompted for a location and a file name, choose those accordingly.

19
00:02:15,818 --> 00:02:20,388
Once the file is saved to disk, you can dismiss the Building Baker window.

20
00:02:21,044 --> 00:02:25,569
To test it out, try importing the high rise back into your scene.

21
00:02:28,687 --> 00:02:31,902
Use the Add method to add it to the current scene.

22
00:02:32,727 --> 00:02:38,173
The fbx file is imported but the new building is not showing the textures in the viewport.

23
00:02:38,733 --> 00:02:46,831
You may have noticed when you unpacked Building Maker that there was another .ms file available named PostFbxImport.ms

24
00:02:47,375 --> 00:02:53,492
With the imported building still selected, run the new script to take care of the textures being shown in the viewport.

25
00:02:53,804 --> 00:02:58,749
Actually, this script does a bit more than that and fixes some scaling discrepancies.

26
00:02:59,138 --> 00:03:05,830
This is mostly important if and when the imported fbx file and the current scene are not of the same scale.

27
00:03:06,466 --> 00:03:13,362
Using the techniques shown in this movie, you can now easily create a library of buildings that you can use to add to your city blocks.

28
00:03:13,944 --> 00:03:23,378
An example is shown in the scene named CityBlocks_Bldgs-pattern.max, which you will use shortly as you put the city blocks in context.

29
00:03:24,064 --> 00:03:29,229
This completes the building creation part of this tutorial, so you can close the Building Maker UI.

30
00:03:29,684 --> 00:03:33,601
Now you have three city blocks with a variety of buildings scattered about.

31
00:03:33,924 --> 00:03:38,929
In the next movie, you use various techniques to tile the city blocks in an irregular pattern.
```