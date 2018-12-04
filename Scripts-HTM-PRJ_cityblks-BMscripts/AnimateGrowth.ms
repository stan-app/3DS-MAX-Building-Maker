--================================
-- AnimateGrowth.ms v.1.0.1
-- Date: March 31, 2014
--
-- Brought to you by: the Autodesk Scripting and SDK Learning Channel - Autodesk M&E
-- © Copyright 2014 Autodesk, Inc. All rights reserved.
-- Conceived & Written by Martin Ashton - Autodesk M&E
-- [ youtube.com/scriptingsdkhowtos]
-- [ scriptingandsdkhowto@autodesk.com ]
--
-- Usage: After creating a building with Building Maker, select the bottom-most point helper
-- (i.e. the bottom "Level" of the building), and run this script.
-- 
-- You can modify the "startFrame" variable to set the frame at which the growth animation begins.
--
-- You can modify the "framesToGrow" variable to affect the speed at which the building grows.
-- I suggest keeping this value at or above 4 (Default: 30).
--
--================================
(
	startFrame = 0
	
	framesToGrow = 30
	
	function getChildElements pItem = (
		
		childElements = for child in pItem.children where (classof child) == Editable_mesh collect child
		
	)

	function getChildLevels pItem = (
		
		childLevels = for child in pItem.children where (classof child) == Point collect child
		
	)
	
	animatedItems = 0
	
	function animateElement pElement = (
		
		currentHeightMult = pElement.ShapeAttributes.numVerticalTiles
		--currentStartOutline = pElement.modifiers[#Bevel].Starting_Outline
		currentScale = pElement.scale
		
		startAnimTime = animatedItems * framesToGrow + startFrame
		endAnimTime = (animatedItems + 1) * framesToGrow + startFrame
		
		animatedItems = animatedItems + 0.75
		
		print ("start time: " + ( startAnimTime as string ) )
		print ("end time: " + ( endAnimTime as string ) )
		
		outlineAnimStart = startAnimTime
		outlineAnimEnd = heightAnimStart = outlineAnimStart + (endAnimTime - startAnimTime) / 2
		heightAnimEnd = endAnimTime
		
		-- Animate the growth.
		with animate on (
			
			at time 0 ( pElement.scale = [0,0,0] )
			
			at time outlineAnimStart ( pElement.scale = [0,0,0] )
			
			at time outlineAnimEnd ( pElement.scale = [ currentScale[1], currentScale[2], 0.1 ] )
			
			at time heightAnimEnd ( pElement.scale = [ currentScale[1], currentScale[2], currentScale[3] ] )
			
		)
		
	)

	function applyToElements pLevel pFn = (
		
		elements = getChildElements pLevel
		levels = getChildLevels pLevel
		
		print elements
		print levels
		
		for element in elements do (
			
			pFn element
			
		)
		
		
		for level in levels do (
			
			applyToElements level pFn
			
		)
		
	)
	
	item = getCurrentSelection()
	
	applyToElements (item[1]) animateElement
	
)