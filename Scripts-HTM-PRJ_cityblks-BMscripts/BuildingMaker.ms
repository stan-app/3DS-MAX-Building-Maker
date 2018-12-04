--================================
-- BuildingMaker.ms v.1.0.1
-- Date: March 31, 2014
--
-- Brought to you by: the Autodesk Scripting and SDK Learning Channel - Autodesk M&E
-- © Copyright 2014 Autodesk, Inc. All rights reserved.
-- Conceived & Designed by Amer Yassine - Autodesk M&E
-- Written & Developed by Martin Ashton - Autodesk M&E
-- [ youtube.com/3dsmaxhowtos | youtube.com/scriptingandsdkhowtos ]
-- [ 3dsmaxhowto@autodesk.com | scriptingandsdkhowto@autodesk.com ]
--
---------------------------
-- Changelog
-------------------------
--  v.1.0.1 - March 31, 2014
--    - While the BuildingMaker is open, material propagation to instances is disabled.
--
--  v.1.0 - March 1, 2014
--    - Initial release.
--
-------------------------
-- Known Limitations 
-------------------------
--  - The “Edit Spline” button works based on the name of the referenced spline. 
--    As such, it is recommended to avoid duplicate spline names in the scene.
--
--	- Building Maker uses Arch&Design Mental Ray Materials instead of the 
--     Standard Material. The Arch&Design Mental Ray material facilitates 
--     reflection map assignment for more believable renders.
--
--	- Manual object deletion within a building may cause some inconsistencies 
--     with the Building Maker’s interface. It is recommended to remove building 
--     elements or entire levels with the “Delete Selected” & "(!!!) Delete Building" buttons.
--
--================================

( -- open top-level parenthesis to avoid code echoing in the listener.

-- ==========================================
-- FORWARD FUNCTION DECLARATIONS
-- These are necessary because of MaxScript's single-pass compilation step.
-- ==========================================
function createNewBuilding = ()
function createNewFloor = ()
function createNewShape pCopyFromShape:undefined = ()

function isBuilding pObj = ()
function isFloor pObj =	()
function isShape pObj = ()
function isBuildingElement pObj = ()
function isBuildingRoot pObj = ()

function setBuildingElementXYControllers pObj = ()
function addExtrusionScriptedController pShapeObj = ()

function createNewUVWMapModifier pObj = ()
function setBitmapToSelection pFilename = ()
function createMaterial pObj = ()
function connectUVTilingControllers pShapeObj pBitmapObj = ()
function setReflectionMapToSelection pFilename = ()
function clearBitmapOnSelection = ()
function clearReflectionMapOnSelection = ()
function copyShapeParametersFromTarget pTargetObj = ()

function getModifierIndex pObj pModifierType = ()
function deleteModifierIfExists pObj pModifierType = ()
function swapSpline pCurrentObj pTargetSpline pObjectNameOverride:undefined = ()

function getRootBuilding pBuildingHierarchy pObj:undefined = ()
function splitShapeAndFloorChildren pObj = ()
function visitChildren pObj pAccumulator pNodeNames:True = ()
function updateBuildingHierarchy pBuildingRoot pBuildingHierarchy = ()
function selectObjectInHierarchy pObj pBuildingHierarchy = ()

function clearZPositionController pObj = ()
function updateScriptedController pObj = ()
function enableXRay pObject = ()
function disableXRay pObject = ()
function setAllBuildingXrayMode pBoolean = ()

function applyFunctionToBuildingObjects pFunc pObj pAffectShapes:True pAffectFloors:True = ()

function parentUp pObj = ()
function parentDown pObj = ()
function getNextParent pBuildingHierarchy pBuildingRoot = ()
function promptNoBuildingSelected = ()
function selectBase pBuildingHierarchy = ()
function addBuilding pBuildingHierarchy = ()
function addFloor pBuildingHierarchy showPrompt:true = ()
function addShape pBuildingHierarchy showPrompt:true = ()
function moveUp pBuildingHierarchy showPrompt:true = ()
function moveDown pBuildingHierarchy showPrompt:true = ()
function removeFromBuilding pObj = ()
function deleteElement pBuildingHierarchy showPrompt:true = ()
function deleteWholeBuilding pBuildingRoot = ()

function centerPivotAtBottomCenter pObj = ()
function isObjectInArray pArr pObj = ()
function bakeBuildingDialog = ()
function bakeBuildingArray pBuildingArray = ()
function bakeBuilding = ()
function copyFloor pBuildingHierarchy = ()

function getSimilarShapesInBuilding pCurrentShape = ()

global preDeleteCallback 
function preDeleteCallback = ()
global postDeleteCallback
function postDeleteCallback = ()
function registerDeleteCallbacks = ()
function unregisterDeleteCallbacks = ()


-- ==========================================
-- DEFAULT VALUE ASSIGNMENT
-- ==========================================
-- These default values are adapted to Max's system units
function initializeDefaultValues = (
	
	local baseValue = case units.SystemType of (
		#Inches: 240.0
		#Feet: 20.0
		#Miles: 0.0039
		#Millimeters: 6000.0
		#Centimeters: 600.0
		#Meters: 6.0
		#Kilometers: 0.006
		default: 240.0
	)
	
	persistent global default_V_Tiling = 1.0 / baseValue
	persistent global default_U_Tiling = 0.5 * default_V_Tiling
	
	persistent global default_Reflectivity = 0.6
	persistent global default_Roughness = 1.0
	
	persistent global default_Bevel_Level_2_Outline = -0.1 * baseValue
	persistent global default_Bevel_Level_3_Height = -0.25 * baseValue
	
	persistent global default_Diffuse_Color = [0.7, 0.7, 0.7, 1.0]

	persistent global default_Dummy_Size = baseValue
		
	global bake_Move_Vector = [ baseValue * 2, baseValue * 2, 0]
	
	global spinnerScale = baseValue * 0.01
	
	global previousViewportMode = viewport.GetRenderLevel()
	if previousViewportMode == #wireFrame then (
		previousViewportMode = #smoothhighlights
	)
	
)
initializeDefaultValues()

global currentBitmapDirectory
if currentBitmapDirectory == undefined then currentBitmapDirectory = (GetDir #maxroot)

global oldMaterialPropagationState = InstanceMgr.autoMtlPropagation
InstanceMgr.autoMtlPropagation = false

-- ==========================================
-- ROLLOUTS
-- ==========================================
global buildingRollout
rollout buildingRollout "Building Maker" width:904 height:768
(
	
	local blackBitmap = bitmap 128 128 color:black
	local replaceSplineReferences = False
	local xrayOn = False
	
	--=======================
	-- BUILDING SECTION
	--=======================
	edittext statusTxt "" pos:[8,8] width:496 height:18 enabled:true readOnly:true bold:true
	
	GroupBox buildingGrp "Building Options" pos:[8,40] width:160 height:600
	button createBuildingBtn "Create Building" pos:[16,64] width:144 height:16
	
	edittext bldName "" pos:[16,88] width:144 height:16 readOnly:true bold:true
	button selectBaseBtn "Select Building Base" pos:[16,112] width:144 height:16
	
	button addFloorBtn "Add New Level" pos:[16,136] width:144 height:16
	button copyFloorBtn "Copy Level" pos:[16,160] width:144 height:16 enabled:false
	button addShapeBtn "Add New Element" pos:[16,184] width:144 height:16
	button bakeBuildingBtn "Bake Building" pos:[16,208] width:144 height:16
	
	listbox buildingHierarchy "" pos:[16,230] width:120 height:27
	
	button moveUpBtn "^" pos:[144,232] width:16 height:176
	button moveDownBtn "v" pos:[144,416] width:16 height:165
	
	button deleteBtn "Delete Selected" pos:[16,592] width:144 height:16
	button deleteBuildingBtn "(!!!) Delete Building" pos:[16,616] width:144 height:16
	
	GroupBox globalOptionsGrp "Global Options" pos:[8,648] width:160 height:72
	button xrayBtn "Toggle XRay Vision" pos:[16,672] width:144 height:16
	button toggleWireframeBtn "Toggle Wireframe" pos:[16,696] width:144 height:16
	
	GroupBox shapeGrp "Element Options" pos:[176,40] width:328 height:680
	
	GroupBox baseSplineGrp "Base Spline" pos:[184,64] width:312 height:72
	edittext splineTxt "" pos:[192,88] width:208 height:16 type:#String readOnly:true bold:true
	button setSplineBtn "Replace" pos:[408,112] width:80 height:16
	button editBaseSplineBtn "Edit" pos:[408,88] width:80 height:16
	
	button copyShapeParamsBtn "Copy Building Element Properties" pos:[184,140] width:312 height:24
	
	GroupBox extrusionGrp "Extrusion Options" pos:[184,168] width:312 height:168
	label heightLbl "Height:" pos:[224,192] width:40 height:16
	spinner heightSpn "" pos:[264,192] width:64 height:16 range:[1e-032,1e+032,100] type:#worldunits scale:spinnerScale 
	label numVertTileLbl "Height Multiplier:" pos:[336,192] width:80 height:16
	spinner heightMultSpn "" pos:[424,192] width:64 height:16 range:[-1e+032,1e+032,1] type:#float scale:0.01
	spinner startOutlineSpn "Start Width:" pos:[248,216] width:80 height:16 range:[-1e+032,1e+032,0] type:#worldunits scale:spinnerScale 
	spinner level1OutlineSpn "End Width:" pos:[408,216] width:80 height:16 range:[-1e+032,1e+032,0] type:#worldunits scale:spinnerScale 
	checkbox affectsFloorHeightChk "Affect Upper Levels" pos:[190,240] width:115 height:16
	checkbox visibilityChk "Visible" pos:[306,240] width:48 height:17
	checkbox startCapChk "Start Cap" pos:[358,240] width:72 height:16
	checkbox endCapChk "End Cap" pos:[430,240] width:64 height:16
	
	GroupBox roofGrp "Roof" pos:[192,264] width:296 height:64
	checkbox level2Chk "Level 1:" pos:[200,280] width:63 height:16
	spinner level2HeightSpn "Height: " pos:[296,280] width:72 height:16 range:[-1e+032,1e+032,0] type:#worldunits scale:spinnerScale 
	spinner level2OutlineSpn "Outline: " pos:[408,280] width:69 height:16 range:[-1e+032,1e+032,0] type:#worldunits scale:spinnerScale 
	checkbox level3Chk "Level 2:" pos:[200,304] width:63 height:16
	spinner level3HeightSpn "Height: " pos:[296,303] width:71 height:16 range:[-1e+032,1e+032,0] type:#worldunits scale:spinnerScale 
	spinner level3OutlineSpn "Outline: " pos:[408,303] width:69 height:16 range:[-1e+032,1e+032,0] type:#worldunits scale:spinnerScale 
	
	GroupBox textureGrp "Material and Map Options" pos:[184,344] width:311 height:368
	colorPicker diffusePicker "Diffuse Color: " pos:[208,368] width:120 height:16 color:[0.7,0.7,0.7,1] title:"Choose a Diffuse Color" alpha:true
	spinner reflectivitySpn "Reflectivity: " pos:[408,368] width:76 height:16 range:[0,1,0] scale:0.01
	
	button textureBtn "Browse Color Map" pos:[192,392] width:144 height:16
	edittext textureTxt "" pos:[192,416] width:144 height:16 readOnly:true bold:true
	bitmap textureBmp "Bitmap" pos:[200,440] width:128 height:128 enabled:true fileName:""
	button clearTextureBtn "Clear Color Map" pos:[192,576] width:144 height:16

	button reflectionBtn "Browse Reflection Map" pos:[345,392] width:144 height:16
	edittext reflectionTxt "" pos:[344,416] width:144 height:16 readOnly:true bold:true
	bitmap reflectionBmp "Bitmap" pos:[352,440] width:128 height:128 enabled:true fileName:""
	button clearReflectionBtn "Clear Reflection Map" pos:[344,576] width:144 height:16
	
	GroupBox realWorldDimsGrp "Real-World Image Dimensions" pos:[192,600] width:296 height:48
	label widthLbl "Width:" pos:[216,624] width:40 height:16
	spinner widthSpn "" pos:[256,624] width:72 height:16 range:[1e-032,1e+032,100] type:#worldunits scale:spinnerScale 
	label heightLbl2 "Height:" pos:[352,624] width:41 height:16
	spinner heightSpn2 "" pos:[392,624] width:72 height:16 range:[1e-032,1e+032,100] type:#worldunits scale:spinnerScale 

	GroupBox texOffsetGrp "Image Position" pos:[192,656] width:296 height:48
	label xOffsetLbl "X: " pos:[200,680] width:16 height:16
	label yOffsetLbl "Y: " pos:[296,680] width:16 height:16
	label zOffsetLbl "Z: " pos:[392,680] width:16 height:16
	spinner xOffsetSpn "" pos:[216,680] width:72 height:16 range:[-1e+032,1e+032,0] type:#worldunits
	spinner yOffsetSpn "" pos:[312,680] width:72 height:16 range:[-1e+032,1e+032,0] type:#worldunits
	spinner zOffsetSpn "" pos:[408,680] width:72 height:16 range:[-1e+032,1e+032,0] type:#worldunits
	checkbox replaceChk "Replace all References" pos:[272,112] width:136 height:16 enabled:false
	
	function setStatusMessage pMessage = (
		
		statusString = ""
		statusString += pMessage
		statusTxt.text = statusString
		
	)
	
	function updateStatusFromSelection = (
		
		obj = selection[1]
		
		if obj == undefined or not isBuilding obj then (
			
			msg = "Press 'Create Building', or select a building element to continue working on it."
			
		) else (
			
			msg = "Press 'Add New Level' or 'Add New Element' to grow your building."
			
		)
		
		setStatusMessage msg
	)
	
	function generatePreviewBitmap pOriginalBitmap = (
		
		resultWidth = resultHeight = 128
		
		resultBitmap = bitmap resultWidth resultHeight color:black
		
		if pOriginalBitmap.height == 0 or pOriginalBitmap.width == 0 then (
			
			-- do nothing.
			
		) else if pOriginalBitmap.height == pOriginalBitmap.width then (
			
			copy pOriginalBitmap resultBitmap
		
		) else if pOriginalBitmap.height > pOriginalBitmap.width then (
			
			resampledHeight = resultHeight
			resampledWidth = (resultHeight * pOriginalBitmap.width / pOriginalBitmap.height )
			
			resampledBitmap = bitmap resampledWidth resampledHeight color:green
			
			-- Resample the original bitmap.
			copy pOriginalBitmap resampledBitmap
			
			-- Copy the resamped bitmap into a specific portion of the result bitmap.			
			pasteBitmap resampledBitmap resultBitmap [0,0] [resultWidth/2.0 - resampledWidth/2.0, 0]
			
		) else (
			
			resampledWidth = resultWidth
			resampledHeight = ( resultWidth * pOriginalBitmap.height / pOriginalBitmap.width )
			
			resampledBitmap = bitmap resampledWidth resampledHeight color:green
			
			-- Resample the original bitmap.
			copy pOriginalBitmap resampledBitmap
			
			-- Copy the resamped bitmap into a specific portion of the result bitmap.			
			pasteBitmap resampledBitmap resultBitmap [0,0] [0, (resultHeight/2.0 - resampledHeight/2.0)]
		)
		
		resultBitmap
	)
	
	function updateBitmap pShapeOptionsEnabled:True = (
		
		if pShapeOptionsEnabled == false \
			  or selection[1] == undefined \
		      or (not isShape selection[1]) \
		      or selection[1].ShapeAttributes.textureFilename == "" then (
				  
			textureTxt.Text = ""
			textureBmp.bitmap = blackBitmap
				  
		) else (
				  
			try (
				
				textureTxt.Text = selection[1].material.diff_color_map.filename
				--tmpBitmap = bitmap 128 128 color:black
				-- copy selection[1].material.diff_color_map.bitmap tmpBitmap 
				tmpBitmap = generatePreviewBitmap selection[1].material.diff_color_map.bitmap
				textureBmp.bitmap = tmpBitmap
				
			) catch (
				
				textureTxt.Text = ""
				textureBmp.bitmap = blackBitmap
				
			)
		)
	)
	
	function updateReflectionMap pShapeOptionsEnabled:True = (
		
		if pShapeOptionsEnabled == false \
			  or selection[1] == undefined \
		      or (not isShape selection[1]) \
		      or selection[1].ShapeAttributes.reflectionFilename == "" then (
				  
			reflectionTxt.Text = ""
			reflectionBmp.bitmap = blackBitmap
				  
		) else (
		
			try (
				
				reflectionTxt.Text = selection[1].material.refl_color_map.filename
-- 				tmpBitmap = bitmap 128 128 color:black
-- 				copy selection[1].material.refl_color_map.bitmap tmpBitmap
				tmpBitmap = generatePreviewBitmap selection[1].material.refl_color_map.bitmap
				reflectionBmp.bitmap = tmpBitmap
				
			) catch (
				
				reflectionTxt.Text = ""
				reflectionBmp.bitmap = blackBitmap
				
			)
		)
	)
	
	function updateSplineText pShapeOptionsEnabled:True = (
		
		if pShapeOptionsEnabled == false \
			  or selection[1] == undefined \
			  or (not isShape selection[1]) \
		      or selection[1].modifiers[#Substitute] == undefined then (
				
			splineTxt.Text = ""
				
		) else (
				  
			splineTxt.Text = selection[1].modifiers[#Substitute].objectName
				  
		)
	)
	
	function toggleShapeOptions pShapeOptionsEnabled = (
	
		local shapeUiElements = #( copyShapeParamsBtn, numVertTileLbl, heightMultSpn, reflectionBtn, clearTextureBtn, \
			                  clearReflectionBtn, baseSplineGrp, textureGrp, texOffsetGrp, \
			                  setSplineBtn, textureBtn, textureBmp, \
			                  widthLbl, heightLbl, widthSpn, heightSpn, xOffsetLbl, yOffsetLbl, zOffsetLbl, \
			                  xOffsetSpn, yOffsetSpn, zOffsetSpn, shapeGrp, \
							  roofGrp, startOutlineSpn, level1OutlineSpn, \
							  level2Chk, level2HeightSpn, level2OutlineSpn, level3Chk, \
							  level3HeightSpn, level3OutlineSpn, diffusePicker,  reflectivitySpn, \
							  startCapChk, endCapChk, affectsFloorHeightChk, visibilityChk, extrusionGrp, \
							  editBaseSplineBtn, realWorldDimsGrp, heightSpn2, heightLbl2, replaceChk )
							  
		shapeUiElements.enabled = pShapeOptionsEnabled
		
		updateBitmap pShapeOptionsEnabled:pShapeOptionsEnabled
		updateReflectionMap pShapeOptionsEnabled:pShapeOptionsEnabled
		updateSplineText pShapeOptionsEnabled:pShapeOptionsEnabled
	)
	
	function refreshShapeSection = (
		
		thisObject = selection[1]
		
		try (
			
			if thisObject != undefined and isShape thisObject then (
				
				toggleShapeOptions true
				
				diffusePicker.color = thisObject.material.diff_color
				reflectivitySpn.controller = thisObject.material.refl_weight.controller
				
				-- Hook up all the necessary controllers to the appropriate sliders.
				xOffsetSpn.controller = thisObject.ShapeAttributes.xOffset.controller
				yOffsetSpn.controller = thisObject.ShapeAttributes.yOffset.controller
				zOffsetSpn.controller = thisObject.ShapeAttributes.zOffset.controller
				
				widthSpn.value = 1.0 / thisObject.ShapeAttributes.widthScale
				heightSpn2.controller = heightSpn.controller =  bezier_float()
				heightSpn.value = 1.0 / thisObject.ShapeAttributes.heightScale
				
				heightMultSpn.controller = thisObject.ShapeAttributes.numVerticalTiles.controller
				
				startOutlineSpn.controller = thisObject.modifiers[#Bevel].Starting_Outline.controller
				level1OutlineSpn.controller = thisObject.modifiers[#Bevel].Level_1_Outline.controller
				level2Chk.checked = thisObject.modifiers[#Bevel].Use_Level_2 == 1
				level2HeightSpn.controller = thisObject.modifiers[#Bevel].Level_2_Height.controller
				level2OutlineSpn.controller = thisObject.modifiers[#Bevel].Level_2_Outline.controller
				level3Chk.checked = thisObject.modifiers[#Bevel].Use_Level_3 == 1
				level3HeightSpn.controller = thisObject.modifiers[#Bevel].Level_3_Height.controller
				level3OutlineSpn.controller = thisObject.modifiers[#Bevel].Level_3_Outline.controller
				
				startCapChk.checked = thisObject.modifiers[#Bevel].Cap_Bottom == 1
				endCapChk.checked = thisObject.modifiers[#Bevel].Cap_Top == 1
				
				affectsFloorHeightChk.checked = thisObject.ShapeAttributes.affectsFloorHeight == 1
				
				visibilityChk.checked = thisObject.ShapeAttributes.isVisible
				
			) else (
				
				toggleShapeOptions false
				
			)
			
		) catch (
			
			--format "*** % ***\n" (getCurrentException())
			
			toggleShapeOptions false
			
		)
	)
	
	function refresh = (
		
		thisObject = selection[1]
		
		try (
			
			if thisObject != undefined and isBuilding thisObject then (
				
				buildingRoot = getRootBuilding undefined pObj:thisObject
				bldName.text = buildingRoot.name
				
				if buildingRoot != undefined then (
					
					updateBuildingHierarchy buildingRoot buildingHierarchy
					selectObjectInHierarchy thisObject buildingHierarchy
					
					copyFloorBtn.enabled = isFloor thisObject
					
				)
				
			) else (
				
				buildingHierarchy.items = #()
				bldName.text = ""
				copyFloorBtn.enabled = false
				
			)
			
		) catch (
			
			buildingHierarchy.items = #()
			bldName.text = ""
			copyFloorBtn.enabled = false
			
		)
		
		refreshShapeSection()
		updateStatusFromSelection()
		
	)

	function preSplinePick = (
		
		buildingRoot = getRootBuilding buildingHierarchy
		
		if buildingRoot != undefined then (
			
			SetSelectFilter 3 --Pick only shapes.
			setAllBuildingXrayMode true
			
		) else (
			
			promptNoBuildingSelected()
			
		)
		
		buildingRoot
		
	)
	
	function postSplinePick = (
		
		SetSelectFilter 1 --Go back to normal mode.
		setAllBuildingXrayMode xrayOn
		--updateStatusFromSelection()
		refresh()
	)
	
	
	on buildingRollout open do
	(
		callbacks.addScript #selectionSetChanged "buildingRollout.refresh()" id:#buildingMaker_callbacks
		max create mode
		buildingRollout.refresh()
	)
	on buildingRollout close do
	(
		callbacks.RemoveScripts #selectionSetChanged id:#buildingMaker_callbacks
		InstanceMgr.autoMtlPropagation = oldMaterialPropagationState
	)
	on createBuildingBtn pressed do
	(
		setStatusMessage "Select a spline to create a building. Right-click anywhere to cancel."
		
		SetSelectFilter 3 --Pick only shapes.
		setAllBuildingXrayMode true
		
		pTargetObj = pickObject message:"Pick a spline to create a new building." count:1
		if pTargetObj != undefined and pTargetObj != #escape then (
			
			addBuilding buildingHierarchy pAtLocation:pTargetObj
			clearundobuffer() --if the user attempts to undo this deletion action, max crashes 			
			
		)
		
		postSplinePick()
	)
	on selectBaseBtn pressed do
	(
		selectBase buildingHierarchy
	)
	on addFloorBtn pressed do
	(
		setStatusMessage "Select a spline to create a new floor level."
		buildingRoot = preSplinePick()
		
		if buildingRoot != undefined then (
			
			pTargetObj = pickObject message:"Pick a spline to create a new floor level." count:1
			if pTargetObj != undefined and pTargetObj != #escape then (
				
				addFloor buildingHierarchy pAtLocation:pTargetObj
				addShape buildingHierarchy showPrompt:false pTargetSpline:pTargetObj
				clearundobuffer()
				
			)
			
		)
		
		postSplinePick()
	)
	on copyFloorBtn pressed do
	(
		copyFloor buildingHierarchy
		clearundobuffer()
		setAllBuildingXrayMode xrayOn
		refresh()
	)
	on addShapeBtn pressed do
	(
		setStatusMessage "Select a spline to create a new element on the current level."
		buildingRoot = preSplinePick()
		
		if buildingRoot != undefined  then (
			
			pTargetObj = pickObject message:"Pick a spline to create a new element." count:1
			if pTargetObj != undefined and pTargetObj != #escape then (
				
				addShape buildingHierarchy pTargetSpline:pTargetObj
				clearundobuffer()
				
			)
		)
		
		postSplinePick()
	)
	on bakeBuildingBtn pressed do
	(
		bakeBuildingDialog()
	)
	on buildingHierarchy selected sel do
	(
		select (getnodebyname (trimLeft buildingHierarchy.selected) )
	)
	on buildingHierarchy doubleClicked sel do
	(
		-- Using the "How To ... Quickly Rename Selected Objects" topic in the MaxScript Reference:
		rollout rename_rollout "Rename" width:152 height:56
		(
			edittext BASE_NAME default:"" pos:[6,8] width:136 height:17
			button rename_them "Rename Selected Object" pos:[8,32] width:135 height:21
			
			on rename_them pressed do
			(
				local currentObjects = selection
				
				if currentObjects != undefined and base_name.text != "" then (
					
					if currentObjects.count == 1 then (
						
						currentObjects[1].name = base_name.text
						
					) else (
						
						for i=1 to currentObjects.count do (
							
							currentObjects[i].name = uniquename base_name.text
							
						)
					)
				)
				
				refresh()
				destroyDialog rename_rollout
				
			)--end on
		)
		
		createDialog rename_rollout 150 60
		rename_rollout.BASE_NAME.text = selection[1].name		
	)
	on moveUpBtn pressed do
	(
		moveUp buildingHierarchy
		clearundobuffer() --if the user attempts to undo this action, max may crash, so we'll prevent undoing by clearing the undo buffer.
	)
	on moveDownBtn pressed do
	(
		moveDown buildingHierarchy
		clearundobuffer() --if the user attempts to undo this action, max may crash, so we'll prevent undoing by clearing the undo buffer. 
	)
	on deleteBtn pressed do
	(
		deleteElement buildingHierarchy
		clearundobuffer() --if the user attempts to undo this action, max may crash, so we'll prevent undoing by clearing the undo buffer.
	)
	on deleteBuildingBtn pressed do
	(
		deleteWholeBuilding() 
		clearundobuffer() --if the user attempts to undo this action, max may crash, so we'll prevent undoing by clearing the undo buffer.
		refresh()
	)
	on xrayBtn pressed do
	(
		xrayOn = not xrayOn
		setAllBuildingXrayMode xrayOn
	)
	on toggleWireframeBtn pressed do
	(
		
		if not viewport.isWire() then (
			
			previousViewportMode = viewport.GetRenderLevel()
			
			viewport.SetRenderLevel #wireFrame
			--actionMan.executeAction 0 "550"  -- Views: Viewport Visual Style Shaded
			
		) else (
			
			-- To avoid being caught in a wireframe loop, default to smooth highlights.
			if previousViewportMode == #wireFrame then (
				previousViewportMode = #smoothhighlights
			)
			viewport.SetRenderLevel previousViewportMode
			--actionMan.executeAction 0 "551"  -- Views: Viewport Visual Style Wireframe
			
		)
	)
	on setSplineBtn pressed do
	(
		setStatusMessage "Select a spline to replace the current element's footprint."
		buildingRoot = preSplinePick()
		
		if buildingRoot != undefined then (
			
			currentObj = selection[1]
			
			if currentObj != undefined then (
				
				pTargetObj = pickObject message:"Pick a spline to set the footprint." count:1
				if pTargetObj != undefined and pTargetObj != #escape then (
					
					similarShapes = getSimilarShapesInBuilding currentObj
					
					swapSpline currentObj pTargetObj
					in coordsys pTargetObj currentObj.pos=[pTargetObj.pos.x, pTargetObj.pos.y, 0]
					in coordsys currentObj.parent currentObj.pos=[currentObj.pos.x,currentObj.pos.y,0]
					
					if replaceSplineReferences then (
						
						for i = 1 to similarShapes.count do (
							
							lShape = similarShapes[i]
							
							swapSpline lShape pTargetObj
							in coordsys pTargetObj lShape.pos=[pTargetObj.pos.x, pTargetObj.pos.y, 0]
							in coordsys lShape.parent lShape.pos=[lShape.pos.x,lShape.pos.y,0]
							
						)
						
					)
					
					
				)
			)
		)
		
		postSplinePick()
	)
	on editBaseSplineBtn pressed do
	(
		global currentObj = selection[1]
		
		if currentObj != undefined and getModifierIndex currentObj #Substitute != 0 then (
			
			-- Need to declare this function as global so the editSplineRollout can find it.
			global preSplineEditMode
			function preSplineEditMode = (
				
				max modify mode
				--setAllBuildingXrayMode true
				select ( getnodebyname (currentObj.modifiers[#Substitute].objectName) )
				modPanel.setCurrentObject selection[1].baseObject
				--subobjectLevel = 1 -- point mode
				subobjectLevel = 2 -- edge mode
				
			)
			
			-- Need to declare this function as global so the editSplineRollout can find it.
			global postSplineEditMode
			function postSplineEditMode = (
				
				max create mode
				--setAllBuildingXrayMode xrayOn
				select currentObj
				
			)
			
			rollout editSplineRollout "Edit Spline Mode" width:360 height:48
			(
				button doneBtn "Done" pos:[248,8] width:104 height:32
				checkbutton pointModeBtn "Point Mode" pos:[8,8] width:104 height:32 checked:false
				checkbutton edgeModeBtn "Edge Mode" pos:[128,8] width:104 height:32 checked:true
				
				on editSplineRollout close do
				(
					postSplineEditMode()
				)
				on doneBtn pressed do
				(
					destroyDialog editSplineRollout
				)
				on pointModeBtn changed newState do
				(				
					if newState == true then (
						subobjectLevel = 1
						edgeModeBtn.state = not newState
					)
				)
				on edgeModeBtn changed newState do
				(				
					if newState == true then (
						subobjectLevel = 2
						pointModeBtn.state = not newState
					)
				)
			)
			
			preSplineEditMode()
			createDialog editSplineRollout 360 48
		)
	)
	on copyShapeParamsBtn pressed do
	(
		setStatusMessage "Select an object to copy its material, texture, and height."
		
		pTargetObj = pickObject count:1
		if pTargetObj != undefined and pTargetObj != #escape then (
			
			copyShapeParametersFromTarget pTargetObj
			
		)
		
		refresh()
	)
	on heightSpn changed val do
	(
		selection[1].ShapeAttributes.heightScale = 1.0 / heightSpn.value
	)
	on affectsFloorHeightChk changed newState do
	(
		affects_value = 0
		if newState == true then affects_value = 1
		selection[1].ShapeAttributes.affectsFloorHeight = affects_value
	)
	on visibilityChk changed newState do
	(
		selection[1].ShapeAttributes.isVisible = newState
		
		if selection[1].ShapeAttributes.isVisible then (
			
			unhide selection[1]
			
		) else (
			
			hide selection[1]
			
		)
	)
	on startCapChk changed newState do
	(
		cap_value = 0
		if newState == true then cap_value = 1
			
		selection[1].modifiers[#Bevel].Cap_Bottom = cap_value
	)
	on endCapChk changed newState do
	(
		cap_value = 0
		if newState == true then cap_value = 1
			
		selection[1].modifiers[#Bevel].Cap_Top = cap_value
	)
	on level2Chk changed newState do
	(
		use_level_value = 0
		if newState == true then use_level_value = 1
			
		selection[1].modifiers[#Bevel].Use_Level_2 = use_level_value
	)
	on level3Chk changed newState do
	(
		use_level_value = 0
		if newState == true then use_level_value = 1
			
		selection[1].modifiers[#Bevel].Use_Level_3 = use_level_value
	)
	on diffusePicker changed newColor do
	(
		selection[1].material.diff_color = newColor
	)
	on textureBtn pressed do
	(
		local bitmapFilename = getBitmapOpenFileName caption:"Select Bitmap" filename:currentBitmapDirectory
		
		if bitmapFilename != undefined and doesFileExist bitmapFilename then (
			
			currentBitmapDirectory = bitmapFilename
			setBitmapToSelection bitmapFilename
			refresh()
			
		)
	)
	on clearTextureBtn pressed do
	(
		clearBitmapOnSelection()
		refresh()
	)
	on reflectionBtn pressed do
	(
		local bitmapFilename = getBitmapOpenFileName caption:"Select Reflection Map" filename:currentBitmapDirectory
		
		if bitmapFilename != undefined and doesFileExist bitmapFilename then (
			
			currentBitmapDirectory = bitmapFilename
			setReflectionMapToSelection bitmapFilename
			refresh()
			
		)
	)
	on clearReflectionBtn pressed do
	(
		clearReflectionMapOnSelection()
		refresh()
	)
	on widthSpn changed val do
	(
		selection[1].ShapeAttributes.widthScale = 1.0 / widthSpn.value
	)
	on heightSpn2 changed val do
	(
		selection[1].ShapeAttributes.heightScale = 1.0 / heightSpn2.value
	)
	on replaceChk changed newState do (
		replaceSplineReferences = newState
		-- TODO
	)
	
)

-- ==========================================
-- CUSTOM ATTRIBUTES
-- ==========================================
global buildingAttr = attributes "BuildingAttributes" attribID:#(0x35503a2d, 0x4d497db7)
(
	parameters buildingParameters
	(
		-- this is basically just a tag to denote the object is part of a building.
	)
)

global elementAttr = attributes "BuildingElementAttributes" attribID:#(0x37333d52, 0x6d8e4f31)
(
	parameters buildingElementParameters rollout:buildingElementRollout
	(
		xPosition type:#float ui:xPosSpinner
		yPosition type:#float ui:yPosSpinner
	)
	rollout buildingElementRollout "Building Element Parameters" width:162 height:48
	(
		spinner xPosSpinner "X Position:" pos:[29,7] width:120 height:16 range:[-1000,1000,10] type:#worldunits
		spinner yPosSpinner "Y Position:" pos:[29,28] width:120 height:16 range:[-1000,1000,10] type:#worldunits
	)
)

global floorAttr = attributes "FloorAttributes" attribID:#(0x6ce0f, 0x65955942)
(
	parameters floorParameters
	(
		-- A placeholder attribute to identify the object as a floor.
	)
)

global shapeAttr = attributes "ShapeAttributes" attribID:#(0x39f324e8, 0x5c5de8ab)
(
	parameters shapeParameters --rollout:shapeRollout
	(
		affectsFloorHeight type:#integer default:1
		isVisible type:#boolean default:true
		extrusionAmount type:#worldunits
		textureFilename type:#string default:""
		reflectionFilename type:#string default:""
		numVerticalTiles type:#float default:1
		widthScale type:#worldUnits default:0.0028
		heightScale type:#worldUnits default:0.0042
		xOffset type:#worldunits default:0.0
		yOffset type:#worldunits default:0.0
		zOffset type:#worldunits default:0.0
	)
)

-- ==========================================
-- FUNCTION IMPLEMENTATIONS
-- ==========================================
function createNewBuilding = (
	
	--Create the building datastructure
	building = point Box:on cross:on axistripod:off size:default_Dummy_Size
	building.name = uniquename "Building"
	building.wirecolor = color 255 255 255
	
	--select building
	
	custAttributes.add building buildingAttr baseObject:true
	
	--Add the first floor.
	newFloor = createNewFloor()
	newFloor.parent = building
	in coordsys newFloor.parent newFloor.pos = [0,0,0]
	
	building
)

function createNewFloor = (
	-- Create a floor.
	
	newFloor = point Box:off cross:on axistripod:on size:default_Dummy_Size
	newFloor.name = uniquename "Level"
	
	custAttributes.add newFloor buildingAttr baseObject:true
	custAttributes.add newFloor elementAttr baseObject:true
	custAttributes.add newFloor floorAttr baseObject:true
		
	setBuildingElementXYControllers newFloor
	
	newFloor
)

function createNewShape pCopyFromShape:undefined = (
	
	-- Create a basic rectangle as a shape.
	newShape = rectangle length:100 width:100 
	newShape.name = uniquename "Element"
	select newShape -- This is apparently crucial for when we set the UVWMap modifier and want to access the gizmo subobject level.
	
	-- Add the building-related attributes
	custAttributes.add newShape buildingAttr baseObject:true
	custAttributes.add newShape elementAttr baseObject:true
	custAttributes.add newShape shapeAttr baseObject:true
	
	-- Set the building Element X-Y translation controllers on the shape.
	setBuildingElementXYControllers newShape
	
	-- Assign controllers for the x,y,z UVWMap offsets
	newShape.ShapeAttributes.xOffset.controller = bezier_float()
	newShape.ShapeAttributes.yOffset.controller = bezier_float()
	newShape.ShapeAttributes.zOffset.controller = bezier_float()

	newShape.ShapeAttributes.xOffset = 0
	newShape.ShapeAttributes.yOffset = 0
	newShape.ShapeAttributes.zOffset = 0
	
	-- Assign controllers for the texture-related width and height scales
	newShape.ShapeAttributes.widthScale.controller = bezier_float()
	newShape.ShapeAttributes.heightScale.controller = bezier_float()

	newShape.ShapeAttributes.widthScale = default_U_Tiling
	newShape.ShapeAttributes.heightScale = default_V_Tiling	
	
	-- Assign a scripted controller to the extrusion amount, based on the number of vertical tiles.
	newShape.ShapeAttributes.numVerticalTiles.controller = bezier_float()
	
	newShape.ShapeAttributes.numVerticalTiles = 1
	addExtrusionScriptedController newShape
	
	-- Add a bevel modifier.
	bevelModifier = Bevel()
	addModifier newShape bevelModifier
	bevelModifier.Level_1_Height.controller = newShape.ShapeAttributes.extrusionAmount.controller
	bevelModifier.Starting_Outline.controller = bezier_float()
	bevelModifier.Level_1_Outline.controller = bezier_float()
	bevelModifier.Level_2_Height.controller = bezier_float()
	bevelModifier.Level_2_Outline.controller = bezier_float()
	bevelModifier.Level_3_Height.controller = bezier_float()
	bevelModifier.Level_3_Outline.controller = bezier_float()
		
	bevelModifier.Starting_Outline = 0
	bevelModifier.Level_1_Outline = 0
	bevelModifier.Use_Level_2 = 0
	bevelModifier.Level_2_Height = 0
	bevelModifier.Level_2_Outline = default_Bevel_Level_2_Outline
	bevelModifier.Use_Level_3 = 0
	bevelModifier.Level_3_Height = default_Bevel_Level_3_Height
	bevelModifier.Level_3_Outline = 0
	
	
	-- Add a UVWMap modifier to get the shape ready for texture assignment and manipulation.
	createNewUVWMapModifier newShape
	
	modPanel.setCurrentObject newShape.baseObject
	
	createMaterial newShape
	
	-- Shape Copying section.
	if isShape pCopyFromShape then (
		
		-- Copy the bitmaps over.
		copyShapeParametersFromTarget pCopyFromShape pCopyOntoObj:newShape
		
		-- Copy the spline.
		if (getModifierIndex pCopyFromShape #Substitute) != 0 then (
			
			swapSpline newShape (pCopyFromShape.modifiers[#Substitute].objectReference) pObjectNameOverride:(pCopyFromShape.modifiers[#Substitute].objectName)
			
		)
		
		newShape.pos = pCopyFromShape.pos
		
	)
	
	newShape
)


function isBuilding pObj = (pObj != undefined) and (custAttributes.get pObj buildingAttr baseobject:on != undefined)
function isFloor pObj =	(pObj != undefined) and (custAttributes.get pObj floorAttr baseobject:on != undefined)
function isShape pObj = (pObj != undefined) and (custAttributes.get pObj shapeAttr baseobject:on != undefined)
function isBuildingElement pObj = (pObj != undefined) and (custAttributes.get pObj elementAttr baseobject:on != undefined)
function isBuildingRoot pObj = (isBuilding pObj) and (not isShape pObj) and (not isFloor pObj)

function addExtrusionScriptedController pShapeObj = (
	
	fs = float_script()
	
	fs.addobject "myInverseHeightScaleCtrl" pShapeObj.ShapeAttributes.heightScale.controller
	fs.addobject "myNumVerticalTilesCtrl" pShapeObj.ShapeAttributes.numVerticalTiles.controller
	
	scriptString = "myNumVerticalTilesCtrl.value * (1.0 / myInverseHeightScaleCtrl.value)"
	
	fs.script = scriptString
	
	pShapeObj.ShapeAttributes.extrusionAmount.controller = fs
	
)

function createMaterial pObj = (
	
	if pObj.material == undefined then (
		
		pObj.material = Arch___Design__mi ()
		
		pObj.material.ShowInViewport = true
		
		pObj.material.diff_color = default_Diffuse_Color 
		pObj.material.diff_rough = default_Roughness
		
		pObj.material.refl_weight.controller = bezier_float() -- so we can hook it up to a spinner...
		pObj.material.refl_weight = 0.0 --default_Reflectivity
	)
)

function connectUVTilingControllers pShapeObj pBitmapObj = (
	
	if pBitmapObj != undefined then (
		
		pBitmapObj.coords.U_Tiling.controller = pShapeObj.ShapeAttributes.widthScale.controller
		pBitmapObj.coords.V_Tiling.controller = pShapeObj.ShapeAttributes.heightScale.controller
		
	)
)

function setBitmapToSelection pFilename = (
	
	obj = selection[1]
	
	createNewUVWMapModifier obj
	
	createMaterial obj 
	
	-- Create a new bitmap texture using the filename.
	newBitmap = Bitmaptexture fileName:pFilename
	newBitmap.coords.realWorldScale=on
	
	-- Connect the bitmap to the material's diffuse color map
	obj.material.diff_color_map = newBitmap
	
	if isShape obj then (
		
		obj.ShapeAttributes.textureFilename = pFilename
		connectUVTilingControllers obj newBitmap
		
	)
	
	modPanel.setCurrentObject obj.baseObject
	showEndResult = True
	
	obj.modifiers[#UVW_Map]
)

function setReflectionMapToSelection pFilename = (
	
	obj = selection[1]
	
	createNewUVWMapModifier obj
	
	createMaterial obj
	
	-- Create a new bitmap texture using the filename.
	newBitmap = Bitmaptexture filename:pFilename
	newBitmap.coords.realWorldScale = on
	
	-- Connec the bitmap to the material's reflection color map.
	obj.material.refl_weight = default_Reflectivity
	obj.material.refl_color_map = newBitmap
	
	if isShape obj then (
		
		obj.ShapeAttributes.reflectionFilename = pFilename
		connectUVTilingControllers obj newBitmap
		
	)
	
	modPanel.setCurrentObject obj.baseObject
	showEndResult = True
	
	obj.modifiers[#UVW_Map]
)

function clearBitmapOnSelection = (
	
	obj = selection[1]
	
	if obj.material != undefined and obj.material.diff_color_map != undefined then (
		
		obj.material.diff_color_map = undefined
		
	)
	
	if isShape obj then (
		
		obj.ShapeAttributes.textureFilename = ""
		
	)
)

function clearReflectionMapOnSelection = (
	
	obj = selection[1]
	
	if obj.material != undefined and obj.material.refl_color_map != undefined then (
		
		obj.material.refl_weight = 0.0
		obj.material.refl_color_map = undefined
		
	)
	
	if isShape obj then (
		
		obj.ShapeAttributes.reflectionFilename = ""
		
	)
)

function copyShapeParametersFromTarget pTargetObj pCopyOntoObj:undefined = (
	
	obj = selection[1]
	if isShape pCopyOntoObj then (
		obj = pCopyOntoObj
	)
	
	if isShape obj and isShape pTargetObj and pTargetObj.material != undefined then (
		
		obj.ShapeAttributes.xOffset = pTargetObj.ShapeAttributes.xOffset
		obj.ShapeAttributes.yOffset = pTargetObj.ShapeAttributes.yOffset
		obj.ShapeAttributes.zOffset = pTargetObj.ShapeAttributes.zOffset
		
		obj.ShapeAttributes.affectsFloorHeight = pTargetObj.ShapeAttributes.affectsFloorHeight
		obj.ShapeAttributes.isVisible = pTargetObj.ShapeAttributes.isVisible
		if obj.ShapeAttributes.isVisible then (
			unhide obj
		) else (
			hide obj
		)
		
		obj.ShapeAttributes.widthScale = pTargetObj.ShapeAttributes.widthScale
		obj.ShapeAttributes.heightScale = pTargetObj.ShapeAttributes.heightScale
		
		obj.ShapeAttributes.numVerticalTiles = pTargetObj.ShapeAttributes.numVerticalTiles
		
		obj.modifiers[#Bevel].Starting_Outline = pTargetObj.modifiers[#Bevel].StartingOutline
		obj.modifiers[#Bevel].Level_1_Outline = pTargetObj.modifiers[#Bevel].Level_1_Outline
		obj.modifiers[#Bevel].Use_Level_2 = pTargetObj.modifiers[#Bevel].Use_Level_2
		obj.modifiers[#Bevel].Level_2_Height = pTargetObj.modifiers[#Bevel].Level_2_Height
		obj.modifiers[#Bevel].Level_2_Outline = pTargetObj.modifiers[#Bevel].Level_2_Outline
		obj.modifiers[#Bevel].Use_Level_3 = pTargetObj.modifiers[#Bevel].Use_Level_3
		obj.modifiers[#Bevel].Level_3_Height = pTargetObj.modifiers[#Bevel].Level_3_Height
		obj.modifiers[#Bevel].Level_3_Outline = pTargetObj.modifiers[#Bevel].Level_3_Outline
		obj.modifiers[#Bevel].Cap_Bottom = pTargetObj.modifiers[#Bevel].Cap_Bottom
		obj.modifiers[#Bevel].Cap_Top = pTargetObj.modifiers[#Bevel].Cap_Top
		
		-- Connect the Diffuse map
		if pTargetObj.ShapeAttributes.textureFilename != "" then (
			
			setBitmapToSelection pTargetObj.ShapeAttributes.textureFilename
			
		)
		
		-- Connect the Reflection map
		if pTargetObj.ShapeAttributes.reflectionFilename != "" then (
			
			setReflectionMapToSelection pTargetObj.ShapeAttributes.reflectionFilename
			
		)
		
		try (			
			-- Try to copy the diffuse color
			obj.material.diff_color = pTargetObj.material.diff_color
		) catch (
			-- Do nothing... you did your best!
		)
		
		try (
			-- Try to copy the reflectivity.
			obj.material.refl_weight = pTargetObj.material.refl_weight
		) catch (
			-- Do nothing, you did your best again!
		)
	)
)

function createNewUVWMapModifier pObj = (
	
	if isShape pObj and pObj.modifiers[#UVW_Map] == undefined then (
		
		try (
			
			newUVWMap = UVWMap()
			addModifier pObj newUVWMap
			
			newUVWMap.maptype = 4
			newUVWMap.realWorldMapSize=on
			newUVWMap.utile = 1
			newUVWMap.vtile = 1
			newUVWMap.length = 1
			newUVWMap.width = 1
			newUVWMap.height = 1
			
			--if isShape pObj then (
			max modify mode
			subobjectLevel = 1
			newUVWMap.gizmo.pos.controller.x_position.controller = pObj.ShapeAttributes.xOffset.controller
			newUVWMap.gizmo.pos.controller.y_position.controller = pObj.ShapeAttributes.yOffset.controller
			newUVWMap.gizmo.pos.controller.z_position.controller = pObj.ShapeAttributes.zOffset.controller
			subobjectLevel = 0
			max create mode
			--)
			
			newUVWMap
		
		) catch (
			
			-- This catches a rare occurence when the uvwmap does not have a gizmo.
			format "*** % ***\n" (getCurrentException())
			undefined
		
		)
		
	) else (
		
		undefined
		
	)
)

function setBuildingElementXYControllers pObj = (
	
	xController = pObj.pos.controller.x_position.controller
	pObj.BuildingElementAttributes.xPosition.controller = xController
	
	yController = pObj.pos.controller.y_position.controller
	pObj.BuildingElementAttributes.yPosition.controller = yController
	
)

function getRootBuilding pBuildingHierarchy pObj:undefined = (
	
	if pObj != undefined then (
		
		parentObj = pObj.parent
		
		if parentObj == undefined or (not isBuilding parentObj) then (
			
			pObj
			
		) else (
			
			getRootBuilding pBuildingHierarchy pObj:parentObj
			
		)
		
	) else if pBuildingHierarchy != undefined and pBuildingHierarchy.selected != undefined then (
		
		nextObject = getnodebyname (trimLeft pBuildingHierarchy.selected)
		getRootBuilding pBuildingHierarchy pObj:nextObject
		
	) else if selection[1] != undefined and (isBuilding selection[1]) then (
		
		getRootBuilding pBuildingHierarchy pObj:selection[1]
		
	) else (
		
		undefined
		
	)
)

function splitShapeAndFloorChildren pObj = (
	
	shapeChildren = #()
	floorChildren = #()
	
	for i = 1 to pObj.children.count do (
		
		child = pObj.children[i]
		if isShape child then append shapeChildren child
		if isFloor child then append floorChildren child
			
	)
	
	#(shapeChildren, floorChildren)
)

function visitChildren pObj pAccumulator pNodeNames:True = (
	
	result = splitShapeAndFloorChildren pObj
	shapeChildren = result[1]
	floorChildren = result[2]
	
	-- Handle the floors.
	for i = 1 to floorChildren.count do (
		
		visitChildren floorChildren[i] pAccumulator pNodeNames:pNodeNames
		
		if pNodeNames then (
			
			append pAccumulator floorChildren[i].name
			
		) else (
			
			append pAccumulator floorChildren[i]
			
		)
	)
	
	-- Handle the shapes.
	for i = 1 to shapeChildren.count do (
		
		if pNodeNames then (
			
			childName = "    " + shapeChildren[i].name
			append pAccumulator childName
			
		) else (
			
			append pAccumulator shapeChildren[i]
			
		)
	)
)

function updateBuildingHierarchy pBuildingRoot pBuildingHierarchy = (
	
	accumulator = #()
	visitChildren pBuildingRoot accumulator
	pBuildingHierarchy.items = accumulator
	
)

function selectObjectInHierarchy pObj pBuildingHierarchy = (
	
	if (isBuildingElement pObj) then (
		
		local notFound = true
		for i=1 to pBuildingHierarchy.items.count while notFound do (
			
			if findString pBuildingHierarchy.items[i] pObj.name != undefined then (
				
				pBuildingHierarchy.selection = i
				notFound = false
				
			)
		)
	) 
)

function clearZPositionController pObj = (
	
	if isFloor pObj then (
		
		pObj.position.controller.z_position.controller = bezier_float()
		
		if pObj.parent != undefined then (
			
			in coordsys pObj.parent pObj.pos = [pObj.pos.x,pObj.pos.y,0]
				
		)
	)
)

function updateScriptedController pObj = (
	
	if isFloor pObj and pObj.parent != undefined then (
		
		shapeSiblings = #()
		
		for i = 1 to pObj.parent.children.count do (
			
			sibling = pObj.parent.children[i]
			
			if sibling != pObj and isShape sibling then (
				
				append shapeSiblings sibling
				
			)
		)
		
		if shapeSiblings.count > 0 then (
			
			fs = float_script()
			
			scriptString = "amax #("
			
			for i=1 to shapeSiblings.count do (
				
				--variableName = "shape_" + (i as string)
				--fs.addobject variableName shapeSiblings[i]
				--scriptString += variableName + ".extrusionAmount * " + variableName + ".affectsFloorHeight"
				
				extrusionAmountVariable  =  "shape_" + (i as string) +"_extrusionAmount"
				affectsFloorHeightVariable = "shape_" + (i as string) + "_affectsFloorHeight"
				
				fs.addtarget extrusionAmountVariable shapeSiblings[i].ShapeAttributes[#extrusionAmount]
				fs.addtarget affectsFloorHeightVariable shapeSiblings[i].ShapeAttributes[#affectsFloorHeight]
				
				scriptString += extrusionAmountVariable + " * " + affectsFloorHeightVariable
				
				if i < shapeSiblings.count then (
					
					scriptString += ","
					
				)
			)
			
			scriptString += ")"
			fs.script = scriptString
			pObj.position.controller.z_position.controller = fs
		)
	)
)

function enableXRay pObject = ( 
	
	pObject.xray = true
	
)

function disableXRay pObject = ( 
	
	pObject.xray = false 

)

function applyFunctionToBuildingObjects pFunc pObj pAffectShapes:True pAffectFloors:True = (
	
	if (isShape pObj) == pAffectShapes and (isFloor pObj) == pAffectFloors then (
		
		pFunc pObj
		
	)
	
	if (isShape pObj) == false then (
		
		for i = 1 to pObj.children.count do (
			
			child = pObj.children[i]
			applyFunctionToBuildingObjects pFunc child pAffectShapes:pAffectShapes pAffectFloors:pAffectFloors
			
		)
	)
)

function parentUp pObj = (
	
	if isShape pObj and pObj.parent != undefined then (
		
		-- set my new parent to the floor that is my sibling (common current parent)
		
		floorChildren = (splitShapeAndFloorChildren pObj.parent)[2]
		
		if floorChildren.count > 0 then (
			
			pObj.parent = floorChildren[1]
			in coordsys pObj.parent pObj.pos = [pObj.pos.x,pObj.pos.y,0]
				
		)
		
	) else if isFloor pObj and pObj.parent != undefined then (
		
		-- set my child to occupy my position under my parent,
		floorChildren = (splitShapeAndFloorChildren pObj)[2]
		
		if floorChildren.count > 0 then (
			
			floorChildren2 = (splitShapeAndFloorChildren floorChildren[1])[2]
			floorChildren[1].parent = pObj.parent
			pObj.parent = floorChildren[1]
			
			if floorChildren2.count > 0 then (
				
				append pObj.children floorChildren2[1]
				in coordsys floorChildren2[1].parent floorChildren2[1].pos = [floorChildren2[1].pos.x,floorChildren2[1].pos.y,0]
					
			)
			
			in coordsys floorChildren[1].parent floorChildren[1].pos = [floorChildren[1].pos.x,floorChildren[1].pos.y,0]
			in coordsys pObj.parent pObj.pos = [pObj.pos.x,pObj.pos.y,0]
		)
	)
)

function parentDown pObj = (
	
	if isShape pObj and pObj.parent != undefined and pObj.parent.parent != undefined and isFloor pObj.parent.parent then (
		
		-- set my new parent to the floor above my parent
		pObj.parent = pObj.parent.parent
		in coordsys pObj.parent pObj.pos = [pObj.pos.x,pObj.pos.y,0]
		
	) else if isFloor pObj and pObj.parent != undefined and pObj.parent.parent != undefined and (isFloor pObj.parent.parent or isBuilding pObj.parent.parent) then (
		
		parentUp pObj.parent
		
	)
)

function getNextParent pBuildingHierarchy pBuildingRoot = (
	
	nextParent = pBuildingRoot
	
	-- collect the floors in the building hierarchy
	if pBuildingHierarchy.selection != 0 then (
		
		obj = getnodebyname( trimLeft pBuildingHierarchy.selected )
		
		if isFloor obj then (
			
			nextParent = obj
			
		) else if isShape obj then (
			
			nextParent = obj.parent
			
		)
	)
	
	nextParent
)

function removeFromBuilding pObj = (
	
	buildingRoot = getRootBuilding undefined pObj:pObj
	
	if buildingRoot != undefined then (
		
		applyFunctionToBuildingObjects clearZPositionController buildingRoot pAffectShapes:False pAffectFloors:True
		
		if isFloor pObj then (
			
			result = splitShapeAndFloorChildren pObj
			shapeChildren = result[1]
			floorChildren = result[2]
			
			delete shapeChildren
			
			if floorChildren.count > 0 then (
				
				floorChild = floorChildren[1]
				floorChild.parent = pObj.parent
				
			)
		)
		
		unregisterDeleteCallbacks()
		
		delete pObj
		
		registerDeleteCallbacks()
		
		applyFunctionToBuildingObjects updateScriptedController buildingRoot pAffectShapes:False pAffectFloors:True
	)
)

function promptNoBuildingSelected = (
	
	messageBox "No Building Selected." title:"Building Maker" beep:false
	
)

function selectBase pBuildingHierarchy showPrompt:true = (
	
	buildingRoot = getRootBuilding pBuildingHierarchy
	
	if buildingRoot != undefined then (
		
		select ( buildingRoot )
		actionMan.executeAction 0 "50001" -- set the tool to move mode, to move the base out of the way
		
	) else if showPrompt==true then (
		
		promptNoBuildingSelected()
		
	)
)

function addBuilding pBuildingHierarchy pAtLocation:undefined = (
	
	buildingRoot = createNewBuilding()
	newShape = createNewShape()
	
	newShape.parent = buildingRoot.children[1]
	in coordsys newShape.parent newShape.pos = [0,0,0]
	
	if pAtLocation != undefined then (
		
		in coordsys pAtLocation buildingRoot.pos = [0,0,0]
		swapSpline newShape pAtLocation
		
	)
	
	updateBuildingHierarchy buildingRoot pBuildingHierarchy
	
	select newShape
)

function insertFloorAbove pTargetFloor pNewFloor pBuildingRoot = (
	
	applyFunctionToBuildingObjects clearZPositionController pBuildingRoot
	
	floorChildren = (splitShapeAndFloorChildren pTargetFloor)[2]
	
	pNewFloor.parent = pTargetFloor

	in coordsys parent 	pNewFloor.pos = [0,0,0]
	
	if floorChildren.count > 0 then (
		
		floorChildren[1].parent = pNewFloor
		in coordsys parent floorChildren[1].pos = [0, 0, 0]
		
	)
	
	applyFunctionToBuildingObjects updateScriptedController pBuildingRoot pAffectShapes:False pAffectFloors:True
	
)

function addFloor pBuildingHierarchy showPrompt:true pAtLocation:undefined = (
	
	buildingRoot = getRootBuilding pBuildingHierarchy
	
	if buildingRoot != undefined then (
		
		nextParent = getNextParent pBuildingHierarchy buildingRoot
		
		newFloor = createNewFloor()
		
		insertFloorAbove nextParent newFloor buildingRoot
		
		updateBuildingHierarchy buildingRoot pBuildingHierarchy
-- 		selectObjectInHierarchy newFloor pBuildingHierarchy
		
-- 		select (getnodebyname (trimLeft pBuildingHierarchy.selected) )
-- 		modPanel.setCurrentObject selection[1].baseObject
		
		select newFloor
		
	) else if showPrompt==true then (
		
		promptNoBuildingSelected()
		
	)
)

function addShape pBuildingHierarchy showPrompt:true pTargetSpline:undefined = (
	
	buildingRoot = getRootBuilding pBuildingHierarchy
	
	if buildingRoot != undefined then (
		
		nextParent = getNextParent pBuildingHierarchy buildingRoot
		
		newShape = createNewShape()
		newShape.parent = nextParent
		
		if pTargetSpline != undefined then (
			
			swapSpline newShape pTargetSpline
			in coordsys pTargetSpline newShape.pos=[pTargetSpline.pos.x, pTargetSpline.pos.y, 0]
			in coordsys newShape.parent newShape.pos=[newShape.pos.x,newShape.pos.y,0]
				
		) else (
			
			in coordsys newShape.parent newShape.pos = [0,0,0]
				
		)
		
		applyFunctionToBuildingObjects updateScriptedController buildingRoot pAffectShapes:False pAffectFloors:True
		
		updateBuildingHierarchy buildingRoot pBuildingHierarchy
-- 		selectObjectInHierarchy newShape pBuildingHierarchy
		
-- 		select (getnodebyname (trimLeft pBuildingHierarchy.selected) )
-- 		modPanel.setCurrentObject selection[1].baseObject
		
		select newShape
		
	) else if showPrompt==true then (
		
		promptNoBuildingSelected()
		
	)
)

function moveUp pBuildingHierarchy showPrompt:true = (
	
	buildingRoot = getRootBuilding pBuildingHierarchy
	
	if buildingRoot != undefined then (
		
		thisObject = getnodebyname( trimLeft pBuildingHierarchy.selected )
		
		applyFunctionToBuildingObjects clearZPositionController buildingRoot pAffectShapes:False pAffectFloors:True
		
		parentUp thisObject
		
		applyFunctionToBuildingObjects updateScriptedController buildingRoot pAffectShapes:False pAffectFloors:True
		
		updateBuildingHierarchy buildingRoot pBuildingHierarchy
-- 		selectObjectInHierarchy thisObject pBuildingHierarchy
		
-- 		select (getnodebyname (trimLeft pBuildingHierarchy.selected) )
-- 		modPanel.setCurrentObject selection[1].baseObject
		select thisObject
		
	) else if showPrompt == true then (
		
		promptNoBuildingSelected()
		
	)
)

function moveDown pBuildingHierarchy showPrompt:true = (
	
	buildingRoot = getRootBuilding pBuildingHierarchy
	
	if buildingRoot != undefined then (
		
		thisObject = getnodebyname( trimLeft pBuildingHierarchy.selected )
		
		applyFunctionToBuildingObjects clearZPositionController buildingRoot pAffectShapes:False pAffectFloors:True
		
		parentDown thisObject
		
		applyFunctionToBuildingObjects updateScriptedController buildingRoot pAffectShapes:False pAffectFloors:True
		
		updateBuildingHierarchy buildingRoot pBuildingHierarchy
-- 		selectObjectInHierarchy thisObject pBuildingHierarchy
		
-- 		select (getnodebyname (trimLeft pBuildingHierarchy.selected) )
-- 		modPanel.setCurrentObject selection[1].baseObject
		select thisObject
		
	) else if showPrompt == true then  (
		
		promptNoBuildingSelected()
		
	)
)

function deleteElement pBuildingHierarchy showPrompt:true = (
	
	buildingRoot = getRootBuilding pBuildingHierarchy
	
	if buildingRoot != undefined then (
		
		if pBuildingHierarchy.selected != undefined then (
			
			thisObject = getnodebyname( trimLeft pBuildingHierarchy.selected )
			
			if thisObject != undefined then (
				
				nextObj = getNextParent pBuildingHierarchy buildingRoot 
				
				removeFromBuilding thisObject
				
				updateBuildingHierarchy buildingRoot pBuildingHierarchy
				
			)
		)
		
	) else if showPrompt==true then (
		
		promptNoBuildingSelected()
		
	)
	
	buildingRoot
)

function deleteWholeBuilding = (
	
	currentObj = selection[1]
	
	if currentObj != undefined and isBuilding currentObj then (
		
		if queryBox "Warning: this will delete the entire building. Do you want to continue?" then (
			
			buildingRoot = getRootBuilding undefined pObj:currentObj
			
			applyFunctionToBuildingObjects clearZPositionController buildingRoot pAffectShapes:False pAffectFloors:True			
			accumulator = #()
			visitChildren buildingRoot accumulator pNodeNames:False
			
			unregisterDeleteCallbacks()
			
			delete accumulator
			delete buildingRoot
			
			registerDeleteCallbacks()
			
		)
		
	) else (
		
		promptNoBuildingSelected()
		
	)
)

function getModifierIndex pObj pModifierType = (
	
	result = 0
	
	for i=1 to pObj.modifiers.count while result == 0 do (
		
		if classof pObj.modifiers[i] == classof pObj.modifiers[pModifierType] then (
			
			result = i
			
		)
	)
	
	result 
)

function deleteModifierIfExists pObj pModifierType = (
	
	modifierIndex = (getModifierIndex pObj pModifierType)
	
	if modifierIndex != 0 then (
		
		deleteModifier pObj modifierIndex
		
	)
)

function swapSpline pCurrentObj pTargetSpline pObjectNameOverride:undefined = (
	
	-- Test whether or not the target is a shape by accessing its superclass.
	--if (superclassof pTargetSpline) as string == "shape" then (
	if (superclassof pTargetSpline) as string == "shape" then (
	
		deleteModifierIfExists pCurrentObj #Substitute
		
		try (
			
			-- Convert the target shape to an editable spline if it isn't.
			workingSpline = pTargetSpline
			
			targetSplineClass = (classof pTargetSpline) as string
 			if targetSplineClass == "SplineShape" or targetSplineClass == "line" then (
				-- Do nothing - we're clear.
			) else (
				
				workingSpline = convertTo pTargetSpline SplineShape
				
			)
			
			-- Create a Substitute modifier using the target spline.
			substituteModifier = Substitute()
			substituteModifier.objectReference = workingSpline
			
			if pObjectNameOverride != undefined then (
				
				substituteModifier.objectName = pObjectNameOverride
				
			) else (
				
				substituteModifier.objectName = workingSpline.name
				
			)
			
			substituteModifier.SubstituteType = "Type: Instance"
			
			addModifier pCurrentObj substituteModifier before:pCurrentObj.modifiers.count
			
		) catch (
			
			format "*** swapSpline exception: % ***\n" (getCurrentException())
			
			deleteModifierIfExists pCurrentObj #Substitute
			
		)
		
		modPanel.setCurrentObject pCurrentObj.baseObject
	)
)

function setAllBuildingXrayMode pBoolean = (
	
	allObjects = objects
	
	for i = 1 to allObjects.count do (
		
		obj = allObjects[i]
		
		if isShape obj then (
			
			obj.xray = pBoolean
			
		) else if isFloor obj or isBuildingRoot obj then (
			
			if pBoolean then (
				unhide obj
			) else (
				hide obj
			)
			
		)
	)
)

function getShapesInBuilding pBuildingRoot pShapeNodes pVisibleOnly:True = (
	
	accumulator = #()
	visitChildren pBuildingRoot accumulator pNodeNames:False
	
	for i=1 to accumulator.count do (
		
		obj = accumulator[i]
		
		if isShape obj then (
			
			if pVisibleOnly then (
				
				if obj.isVisible then (
					
					append pShapeNodes obj 
					
				)
				
			) else (
				
				append pShapeNodes obj 
				
			)
		)
	)
)

function isObjectInArray pArr pObj = (
	
	result = false
	
	for i = 1 to pArr.count while result == false do (
		
		result = pArr[i] == pObj
		
	)
	
	result
)

function centerPivotAtBottomCenter pObj = (
	boundingBox = nodeLocalBoundingBox pObj
	minPoint = boundingBox[1]
	maxPoint = boundingBox[2]
	x = minPoint[1] + (maxPoint[1] - minPoint[1]) / 2.0
	y = minPoint[2] + (maxPoint[2] - minPoint[2]) / 2.0
	z = minPoint[3]
	pObj.pivot = [x,y,z]
)

function bakeBuildingDialog = (
	
	global bakeBuildingRollout
	rollout bakeBuildingRollout "Building Baker" width:329 height:320
	(
		
		local buildingsToBake = #()

		label topLbl "CTRL-Click to select which buildings to bake as a single object." pos:[6,8] width:306 height:16		
		
		GroupBox selectedBuildingsGrp "Selected Buildings" pos:[8,32] width:304 height:128
		listbox selectedBuildingsList "" pos:[16,56] width:288 height:7 readOnly:true
		
		GroupBox bakedOffsetGrp "Baked Result Offset" pos:[8,168] width:304 height:48 
		spinner xSpn "X: " pos:[48,192] width:56 height:16 range:[-1e+032,1e+032,0] type:#worldunits 
		spinner ySpn "Y: " pos:[136,192] width:56 height:16 range:[-1e+032,1e+032,0] type:#worldunits
		spinner zSpn "Z: " pos:[224,192] width:56 height:16 range:[-1e+032,1e+032,0] type:#worldunits
		
		button bakeBtn "Bake" pos:[8,224] width:144 height:32
		button bakeExportBtn "Bake and Export to FBX" pos:[168,224] width:144 height:32
		
		GroupBox progressGrp "Progress" pos:[8,264] width:304 height:48
		progressBar bakingProgressBar "" pos:[16,288] width:288 height:16 value:0 color:(color 57 181 74) orient:#horizontal
		
		function getUniqueBuildingsFromSelection = (
			
			uniqueBuildings = #()
			
			currentSelection = selection
			
			for i = 1 to currentSelection.count do (
				
				obj = currentSelection[i]
				
				if isBuilding obj then (
			
					buildingRoot = getRootBuilding undefined pObj:obj
					
					if not (isObjectInArray uniqueBuildings buildingRoot) then (
						
						append uniqueBuildings buildingRoot
						
					)
				)
			)
			
			uniqueBuildings
		)
		
		function refresh = (
			
			buildingsToBake = getUniqueBuildingsFromSelection()
			
			buildingNames = #()
			
			for i=1 to buildingsToBake.count do (
				
				append buildingNames buildingsToBake[i].name
				
			)
			
			selectedBuildingsList.items = buildingNames
			
		)
		
		function hookRefreshCallback = (
			callbacks.addScript #selectionSetChanged "bakeBuildingRollout.refresh()" id:#bakeBuildingRollout_callbacks
		)
		
		function unhookRefreshCallback = (
			callbacks.RemoveScripts #selectionSetChanged id:#bakeBuildingRollout_callbacks	
		)
		
		
		on bakeBuildingRollout open do
		(
			
			xSpn.value = bake_Move_Vector[1]
			ySpn.value = bake_Move_Vector[2]
			zSpn.value = bake_Move_Vector[3]
			
			hookRefreshCallback()
			
			bakeBuildingRollout.refresh()
		)
		on bakeBuildingRollout close do
		(
			unhookRefreshCallback ()
		)
		on bakeBtn pressed do 
		(
			if buildingsToBake.count > 0 then (
				
				unhookRefreshCallback()
				
				bakedBuilding = bakeBuildingArray buildingsToBake pProgressBar:bakingProgressBar
				
				in coordsys local move bakedBuilding bake_Move_Vector			
				
				hookRefreshCallback()
				
				select bakedBuilding
				
			) else (
				
				promptNoBuildingSelected()
				
			)
		)
		on bakeExportBtn pressed do 
		(
			if buildingsToBake.count > 0 then (
				
				saveFilename = getSaveFileName caption:"Export Building to FBX" types:"FBX(*.fbx)"

				if saveFilename != undefined then (
				
					unhookRefreshCallback()
					
					bakedBuilding = bakeBuildingArray buildingsToBake pProgressBar:bakingProgressBar
					
					select bakedBuilding
					
					in coordsys world bakedBuilding.pos = [0,0,0]
					
					FbxExporterSetParam "EmbedTextures" true -- embed building textures by default.
					
					exportFile saveFilename #noPrompt selectedOnly:true using:FBXEXP
					
 					delete bakedBuilding
					
					hookRefreshCallback()
				)
				
			) else (
				
				promptNoBuildingSelected()
				
			)
		)
		
		on xSpn changed val do 
		(
			bake_Move_Vector[1] = xSpn.value
		)
		on ySpn changed val do 
		(
			bake_Move_Vector[2] = ySpn.value
		)
		on zSpn changed val do 
		(
			bake_Move_Vector[3] = zSpn.value
		)
		
	)
	
	global bakeBuildingRolloutFloater
	if bakeBuildingRolloutFloater != undefined then closeRolloutFloater bakeBuildingRolloutFloater
	bakeBuildingRolloutFloater = newRolloutFloater "Building Baker" 335 348
	addRollout bakeBuildingRollout bakeBuildingRolloutFloater

)


function bakeBuildingArray pBuildingArray pProgressBar:undefined = (
	
	if pProgressBar != undefined then (
		pProgressBar.value = 0
	)
	
	bakedBuildings = #()
		
	-- Bake each building individually
	for i=1 to pBuildingArray.count do (
		
		result = bakeBuilding pBuildingArray[i]
		
		if pProgressBar != undefined then (
			pProgressBar.value = ( 100. * i / pBuildingArray.count )
		)
		
		if result != undefined then (
			append bakedBuildings result
		)
		
	)
	
	-- Combine the baked buildings into a single one.
	finalBuildingShape = bakedBuildings[bakedBuildings.count] 
	for i = 1 to bakedBuildings.count-1 do (
		
		polyop.attach bakedBuildings[i] finalBuildingShape 
		finalBuildingShape = bakedBuildings[i]
		
	)
	
	pProgressBar.value = 100
	
	centerPivotAtBottomCenter finalBuildingShape 
	
	pProgressBar.value = 0
	
	finalBuildingShape
)

function bakeBuilding pTargetObj = (
		
-- 	currentObj = selection[1]
	currentObj = pTargetObj
	
	if currentObj != undefined and isBuilding currentObj then (
		
		buildingRoot = getRootBuilding undefined pObj:currentObj
		
		shapeNodes = #() 
		
		getShapesInBuilding buildingRoot shapeNodes
		
		if shapeNodes.count >= 1	then (
			
			-- Copy the shapes
			maxops.clonenodes shapeNodes newNodes:&copiedNodes cloneType:#copy
			
			-- Select the copied nodes.
			select copiedNodes
			
			-- unlink the current selection.
			max unlink 
			
			-- Collapse all the copies' modifier stacks and turn them into editable poly's
			convertedResults = #()
			for i = 1 to copiedNodes.count do (
				
				result = convertToPoly copiedNodes[i]
				append convertedResults result
				
			)
			
			--Get the bottom-most shape in the list
			groundShape = convertedResults[convertedResults.count] 
			for i = 1 to convertedResults.count-1 do (
				
				polyop.attach convertedResults[i] groundShape
				groundShape = convertedResults[i]
				
			)
			
			-- Get a string representation of the current time.
			-- This will be used to create a unique name for the baked building's multi material.
			UTCTimeArray = getUniversalTime()
			timeString = ""
			for i = 1 to UTCTimeArray.count do (
				
				timeString += (UTCTimeArray[i] as string)
				
			)
			
			-- Generate a unique name for the building.
			--bakedBuildingName = uniquename "BakedBuilding"
			bakedBuildingPrefix = "BakedBuilding"
			
			bakedBuildingName = bakedBuildingPrefix + "_" + timeString
			
			/*
			-- Get a string representation of the current time.
			-- This will be used to create a unique name for the baked building's multi material.
			UTCTimeArray = getUniversalTime()
			timeString = ""
			for i = 1 to UTCTimeArray.count do (
				
				timeString += (UTCTimeArray[i] as string)
				
			)
			*/
			
			-- Uniquely identify the name of the new multi-material to avoid conflicts during importing into other scenes.
			if groundShape.material != undefined then (
				
				groundShape.material.name = (bakedBuildingPrefix + "_MULTI_MAT_[" + timeString + "]" ) 
				
			)
			
			-- Assign the baked building's name.
			groundShape.name = bakedBuildingName
			
			-- Delete the remaining custom attributes
			custAttributes.delete groundShape buildingAttr baseObject:true
			custAttributes.delete groundShape elementAttr baseObject:true
			custAttributes.delete groundShape shapeAttr baseObject:true			
			
			-- Move the baked building over.
-- 			move groundShape default_Bake_Move_Vector
			
			-- Center the object's pivot.
			centerPivotAtBottomCenter groundShape
			
			disableXRay groundShape
			
			groundShape
			
		) else (
		
			messageBox "No Elements to Copy in Building." title:"Building Maker" beep:false
			undefined
		)
		
	) else (
		
		promptNoBuildingSelected()
		undefined
	)
)

function copyFloor pBuildingHierarchy = (
	
	currentObj = selection[1]
	
	if currentObj != undefined and isFloor currentObj then (
		
		buildingRoot = getRootBuilding pBuildingHierarchy
		
		if buildingRoot != undefined then (
			
			nextParent = currentObj
			
			-- collect the next parent's shape children.
			shapeChildren = (splitShapeAndFloorChildren nextParent)[1]
			
			newFloor = createNewFloor()
			
			for i = 1 to shapeChildren.count do (
				
				newShape = createNewShape pCopyFromShape:shapeChildren[i]
				newShape.parent = newFloor
				in coordsys parent newShape.pos = [shapeChildren[i].pos.x,shapeChildren[i].pos.y,0]
			)
			
			insertFloorAbove nextParent newFloor buildingRoot
			
			in coordsys parent newFloor.pos = [0,0,0]
			
			updateBuildingHierarchy buildingRoot pBuildingHierarchy
			selectObjectInHierarchy newFloor pBuildingHierarchy
			
			select (getnodebyname (trimLeft pBuildingHierarchy.selected) )
			modPanel.setCurrentObject selection[1].baseObject
		
		) else if showPrompt==true then (
			
			promptNoBuildingSelected()
			
		)
		
	) else (
		
		messageBox "No level selected to copy." title:"Building Maker" beep:false
		
	)
	
)

function getSimilarShapesInBuilding pCurrentShape = (
	
	similarShapes = #()
	
	if getModifierIndex pCurrentShape #Substitute != 0 then (
		
		buildingRoot = getRootBuilding undefined pObj:pCurrentShape
			
		shapeNodes = #() 
			
		getShapesInBuilding buildingRoot shapeNodes pVisibleOnly:False
		
		for i = 1 to shapeNodes.count do (
			
			lShape = shapeNodes[i]
				
			if lShape != pCurrentShape and getModifierIndex lShape #Substitute != 0 \
			   and lShape.modifiers[#Substitute].objectReference == pCurrentShape.modifiers[#Substitute].objectReference \
			   then (
				
				append similarShapes lShape
				
			)
		)
	)
	
	similarShapes
	
)

function preDeleteCallback = (
	
	nodeToDelete = callbacks.notificationParam()
	
	if isBuilding nodeToDelete then (
	
		objs = objects
		
		for i = 1 to objs.count do (
			
			obj = objs[i]
			
			if isBuildingRoot obj then (
				
				applyFunctionToBuildingObjects clearZPositionController obj pAffectShapes:False pAffectFloors:True
				
			)
		)		
	)
)

function postDeleteCallback = (
	
	objs = objects
	
	for i = 1 to objs.count do (
		
		obj = objs[i]
		
		if isBuildingRoot obj then (
			
			applyFunctionToBuildingObjects updateScriptedController obj pAffectShapes:False pAffectFloors:True
			
		)
	)
)

function registerDeleteCallbacks = (
	callbacks.addScript #nodePreDelete "preDeleteCallback()" id:#buildingMaker_deleteCallbacks
	callbacks.addScript #nodePostDelete "postDeleteCallback()" id:#buildingMaker_deleteCallbacks
)

function unregisterDeleteCallbacks = (
	callbacks.removeScripts #nodePreDelete id:#buildingMaker_deleteCallbacks
	callbacks.removeScripts #nodePostDelete id:#buildingMaker_deleteCallbacks
)

-- =========================================
-- MAIN
-- =========================================
unregisterDeleteCallbacks()
registerDeleteCallbacks()

global buildingMakerRolloutFloater
if buildingMakerRolloutFloater != undefined then closeRolloutFloater buildingMakerRolloutFloater
buildingMakerRolloutFloater = newRolloutFloater "Building Maker v.1.0" 525 755
addRollout buildingRollout buildingMakerRolloutFloater

) -- close top-level parenthesis to avoid code echoing in the listener.