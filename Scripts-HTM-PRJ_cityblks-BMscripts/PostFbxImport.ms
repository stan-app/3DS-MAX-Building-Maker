-- PostFbxImport.ms
-- Date: March 1, 2014
--
-- Run this script on the selected items after an FBX file has been imported.
--
-- This script takes care of showing the materials, centering the pivot, and 
-- re-scaling the object's UV's and textures so they are consistent with the scene's
-- real-world units.
--
-- Brought to you by: the Autodesk Scripting and SDK Learning Channel - Autodesk M&E
-- © Copyright 2014 Autodesk, Inc. All rights reserved.
-- Conceived & Designed by Amer Yassine - Autodesk M&E
-- Written & Developed by Martin Ashton - Autodesk M&E
-- [ youtube.com/3dsmaxhowtos | youtube.com/scriptingandsdkhowtos ]
-- [ 3dsmaxhowto@autodesk.com | scriptingandsdkhowto@autodesk.com ]


function centerPivotAtBottomCenter pObj = (
	
	boundingBox = nodeLocalBoundingBox pObj
	minPoint = boundingBox[1]
	maxPoint = boundingBox[2]
	x = minPoint[1] + (maxPoint[1] - minPoint[1]) / 2.0
	y = minPoint[2] + (maxPoint[2] - minPoint[2]) / 2.0
	z = minPoint[3]
	pObj.pivot = [x,y,z]
	
)

function adjustBitmap pBitmap pScalingFactor = (
	
	if pBitmap != undefined then (
	
		pBitmap.coords.realWorldScale = on
		
		pBitmap.coords.U_Offset = 0
		pBitmap.coords.V_Offset = 0
		
		pBitmap.coords.U_Tiling = pBitmap.coords.U_Tiling * pScalingFactor
	    pBitmap.coords.V_Tiling = pBitmap.coords.V_Tiling * pScalingFactor
		
	)
)

function postFBXImport pNode = (

	if isValidNode pNode then (
		
		-- Get the previous scale and position.
		currentPosition = pNode.pos
		currentScale = pNode.scale
		
		-- Adjust the pivot.
		pNode.scale = [1,1,1]
		
		xformModifier = XForm()
		xformModifier.gizmo.scale = currentScale
		
		addmodifier pNode xformModifier
		
		centerPivotAtBottomCenter pNode
		
		convertToPoly pNode
		
		pNode.pos = currentPosition
		
		-- Adjust the materials into real world coordinates and show them.
		realWorldUnitScale = currentScale[1]
		
		try (
		
			if ( pNode.material != undefined ) then (
			
				if ( pNode.material.count != undefined ) then (
				
					for i = 1 to pNode.material.count do (
						
						mat = pNode.material[i]
						
						adjustBitmap mat.diff_color_map ( 1.0 / realWorldUnitScale )
						adjustBitmap mat.refl_color_map ( 1.0 / realWorldUnitScale )
						
						mat.ShowInViewport = true
					)
					
				) else (
					
					adjustBitmap pNode.material.diff_color_map ( 1.0 / realWorldUnitScale )
					adjustBitmap pNode.material.refl_color_map ( 1.0 / realWorldUnitScale )
					
					pNode.material.ShowInViewport = true
					
				)
			)
			
			-- Add an unwrapUVW modifier to the selection.
			
			max modify mode
			
			unwrapUVW = Unwrap_UVW()
			
			addmodifier pNode unwrapUVW
			
			subobjectLevel = 3
			
			numFaces = unwrapUVW.numberPolygons()
			
			unwrapUVW.selectFaces #{1..numFaces}
			
			unwrapUVW.ScaleSelectedXY realWorldUnitScale realWorldUnitScale [0,0,0]
			
			convertToPoly pNode
			
			max create mode
		
		) catch (
			
			format "*** % ***\n" (getCurrentException())
			
		)
	)	
)

currentSelection = selection

for i = 1 to currentSelection.count do (
	
	postFBXImport currentSelection[i]
	
)