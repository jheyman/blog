---
layout: page
title: Visio layer automatic highlighter
tagline: VBA code to highlight elements contained in a given layer
tags: Visio, VBA

---
{% include JB/setup %}

I often need to show different views of a given complex structure, and I do not want to make separate diagrams since this would turn out to be completely unmaintainable and prone to many inconsistencies between the individual diagrams. For all but the simplest diagrams, this is not practical. So I like using the **Layers** in Visio, creating one layer per target view, and adding the shapes related to this view in said layer.

However, Visio layers have one annoying shortcoming: when a given object is included in **several** layers, Visio just does not provide a proper way to give a specific color to the shape depending on the active layer. Yes, Layers do have a "color" property that can be set in the Layer menu, and yes Visio will color shapes based on this layer color setting, but this only works when shapes belong to a single layer. As soon as a shape is part of several layers, Visio does not even try to use the predefined layer's colors and defaults to displaying the original shape's color:

![image]({{ site.baseurl }}/assets/images/VisioLayerHighlighter/visio_layerColors.png)

Notice how the shape belonging to layer 1 only took the red color of layer1, while the other shapes that belong to several layers did NOT pick-up the color of the corresponding layers. 

Well this makes sense, as Visio has no way to know which layer of the multiple ones applied to a shape should take "priority", because (as far as I know) there is no Z-ordering of layers. So anyway, I started looking for a simple way to highlight the shapes belonging to one given layer by giving them a predefined color, while fading all other shapes not belonging to this layer by giving them another darker color. This, and a way to select which layer is currently highlighted, would fulfill my original need.

---

### Table of Contents

* TOC
{:toc}

### VBA to the rescue
 
Using VBA (Visual Basic for Applications), it is quite easy to change any of the properties of shapes on the page. The layer highlighter scheme is as follows:

* a combox box is added to the page, and filled with a selection of layer names
* the VBA code reacts to the layer selection from the combox box by:
	* parsing all shapes on the page, and for each shape:
		* creating a backup of the original line color, line width, and text color of the shape in a dynamically created user property  
		* determining if it belongs to the selected layer:
			* if so  => change its line color, line weight, and text color to specific predefined values chosen for highlighting this specific layer.
			* if not => change its line color, line weight, and text color to specific predefined chosen for fading this specific layer.
		* if the selected layer is "None", restore the original line color/line width/text color

### Layer selector

The combobox selector is added to the page by going to the Developer tab, switching to Design mode, and then inserting the combox box from the insert activeX controls menu:

![image]({{ site.baseurl }}/assets/images/VisioLayerHighlighter/visio_insert_combobox.png)

To populate the combobox with the list of selectable layers, I just added these few lines in the callback function that gets executed when the Visio document is opened:

	Private Sub Document_DocumentOpened(ByVal Doc As IVDocument)		
	    ' Create the combox entries
	    ComboBox1.AddItem ("layer1")
	    ComboBox1.AddItem ("layer2")
	    ComboBox1.AddItem ("layer3")
	    ComboBox1.AddItem ("None")
	    ComboBox1.Text = ComboBox1.List(3)
	End Sub

The last line makes sure that upon opening the document, the selection is set to "None" by default:

![image]({{ site.baseurl }}/assets/images/VisioLayerHighlighter/visio_Nolayerhighlighted.png)

**Note** : I struggled a bit to find where to adjust the text size in the combox box, to make it practical when viewing the diagram all zoomed out. The combox box text size can be modified by editing the "Font" line in the combo box properties. There is a small "..." button on the right, that allows not only to select the Font name, but also the text size. 

The test file I used covers various cases to make sure the code works as intended:

* shapes that do not belong to any layer
* shapes that belong to one layer only
* shapes that belong to multiple layers
* grouped shaped (more on this later)

The callback to handle combox selection from the user is a simple `Select/Case` statement that calls the highlighting function:

	Private Sub ComboBox1_Change()
	    Select Case ComboBox1.Value
	        ' Format :
	        ' highlight_shapes <layer_name>, <highlight_line_color>, <highlight_text_color>, <highlight_line_width>, <faded_line_color>, <faded_text_color>
	    Case "layer1":
	        highlight_shapes "layer1", "RGB(255, 0, 0)", "RGB(0, 0, 0)", "4 pt", "RGB(127, 127, 127)", "RGB(127, 127, 127)"
	    Case "layer2":
	        highlight_shapes "layer2", "RGB(0, 255, 0)", "RGB(0, 0, 0)", "4 pt", "RGB(127, 127, 127)", "RGB(127, 127, 127)"
	    Case "layer3":
	        highlight_shapes "layer3", "RGB(0, 0, 255)", "RGB(0, 0, 0)", "4 pt", "RGB(127, 127, 127)", "RGB(127, 127, 127)"
	    Case "None":
	        highlight_shapes "None", "<none>", "<none>", "<none>", "<none>", "<none>"
	    End Select
	End Sub

### Parsing all shapes

Parsing all shapes on the current Page is as simple as :

	For Each shp In Visio.ActivePage.Shapes
		(...Do something with the shape...)
	Next shp

However there is a small catch: in Visio, shapes can be grouped. A group of shapes is itself a Shape, that contains sub-shapes. So when looping over the `Visio.ActivePage.Shapes`, one gets the top-level shapes only, i.e. shapes that are not in any group and top-level group shapes, but not the sub-shapes inside a group. For this highlighting effect, because changing the line color/text color/line width of a group of shapes will not give the intended result, what we want is modifying the properties of each individual "leaf" shape. 

So I wrote a small function that recursively collects all shapes contained inside a group shape, down to the lowest grouping level:

	Public Function subShapes(ByVal shp As Shape) As collection
	Dim collection As New collection
	Dim tempcollection As New collection
	     ' If shape is a group, need to parse grouped sub-shapes:
	     If shp.Type = visTypeGroup Then
	         ' add all the grouped shaped in the list
	         For Each subshp In shp.Shapes
	             Set tempcollection = subShapes(subshp)
	             For Each tempShp In tempcollection
	                collection.Add tempShp
	             Next tempShp
	         Next
	         ' also add the group Shape itself in the list
	         collection.Add shp
	     Else
	        ' shape is not a group: just add this shape only to the list.
	         collection.Add shp
	     End If   
	     Set subShapes = collection
	End Function


Then a higher level function parses shapes on the page, and in the case of a group Shape, collects sub-shapes using the previous function: 


	Public Function findAllShapes() As collection
	Dim collection As New collection
	Dim tempcollection As New collection
	Dim x As Shape
	Dim shp As Shape
	    For Each shp In Visio.ActivePage.Shapes
	        Set tempcollection = subShapes(shp)
	        For Each tempShp In tempcollection
	            collection.Add tempShp
	        Next tempShp
	    Next shp
	    Set findAllShapes = collection 
	End Function


### Highlighting the shapes

The backup of the shape's original line color is done by dynamically creating a user property using the `AddNamedRow` function, then storing the current line color in it:

	If Not shp.CellExists("Prop.originalLineColorBackup", 0) Then
	    shp.AddNamedRow visSectionProp, "originalLineColorBackup", visTagDefault
	    shp.Cells("Prop.originalLineColorBackup") = shp.Cells("Linecolor")
	End If	

and similarly for line width, and text color.

Once we detect that a shape belongs to the selected layer, changing its line color, line width, and text color properties is as simple as:

	shp.Cells("Linecolor").FormulaU = highlight_line_color
	shp.CellsSRC(visSectionCharacter, 0, visCharacterColor).FormulaU = highlight_text_color
	shp.CellsSRC(visSectionObject, visRowLine, visLineWeight).FormulaU = highlight_line_width

### Results

Selecting Layer1 results in this to be displayed:

![image]({{ site.baseurl }}/assets/images/VisioLayerHighlighter/visio_layer1highlighted.png)

selecting Layer2 gives:

![image]({{ site.baseurl }}/assets/images/VisioLayerHighlighter/visio_layer2highlighted.png)

while selecting Layer3 shows:

![image]({{ site.baseurl }}/assets/images/VisioLayerHighlighter/visio_layer3highlighted.png)

### Source code

The VBA source code and Visio test files are available [here](https://github.com/jheyman/visiolayerhighlighter)




