extends Control
class_name FlowChartConnector

#dependencies-------------------------------------------------------------------
var line : Line2D
var arrow_end : Polygon2D

#arrow data---------------------------------------------------------------------
var blk_1 : FlowChartBase
var blk_2 : FlowChartBase
#which direction the first segment of the line points
var direction : Vector2
#var end_direction : Vector2


#arrow settings-----------------------------------------------------------------
#arrow color
var color : Color = Color.BLACK
#arrow line thickness
var thickness : int = 4
#how much margin to add to bounding boxes
#that determine whether to render the arrow in the first place
#(if they intersect, it wont render)
var bounding_margin : int = 15
#gap between the arrow ends and the blocks
var arrow_gap : int = 2
#how close to the edge the arrow line will get until it adds a bend
var tolerance : int = 20

var arrow_end_width : int = 30
var arrow_end_length : int = 12


#might have flip button
#if i can figure out how to get hover from line2d

# Called when the node enters the scene tree for the first time.
func _ready():
	line = Line2D.new()
	line.default_color = color
	line.width = thickness
	add_child(line)
	line.owner = self
	
	arrow_end = Polygon2D.new()
	arrow_end.color = color
	add_child(arrow_end)
	arrow_end.owner = self


func connector_update():
	#first, check if the blocks are too close (bounding box plus some margin)
	var rect_1 : Rect2 = blk_1.get_rect()
	rect_1.grow(bounding_margin)
	var rect_2 : Rect2 = blk_2.get_rect()
	rect_2.grow(bounding_margin)
	
	#if they intersect, dont render arrow
	"TODO v0.2"#i think this is broken for some reason
	if rect_1.intersects(rect_2):
		visible = false
		return
	visible = true
	
	
	var blk_1_ct : Vector2 = blk_1.size * 0.5 + blk_1.position
	var blk_2_ct : Vector2 = blk_2.size * 0.5 + blk_2.position
	var blk_1_size_h : Vector2 = blk_1.size * 0.5
	var blk_2_size_h : Vector2 = blk_2.size * 0.5
	var blk_relative : Vector2 = blk_2_ct - blk_1_ct
	var direction_normal : Vector2 = direction.rotated(PI * 0.5)
	var points : PackedVector2Array = PackedVector2Array()
	
	
	var condition = false 
	if direction != Vector2.ZERO:
		#get center of side where arrow starts
		var f_pos = blk_1.position + blk_1_size_h * direction
		
		#get center of side where arrow ends
		var s_pos = blk_2.position + blk_2_size_h * direction_normal
		
		var is_outside_tolerance = ((s_pos - f_pos) * direction).length() < (blk_1_size_h * direction).length()
		
		#fixes direction vector not regenerating when dragging one block
		#directly through the other
		var is_on_opposite_side = (blk_2_ct - blk_1_ct).dot(direction) < -0.5
		
		if is_outside_tolerance or is_on_opposite_side:
			condition = true
	
	#regenerate direction vector
	if direction == Vector2.ZERO or condition:
		if abs(blk_relative.x) > abs(blk_relative.y):
			direction = Vector2(sign(blk_relative.x), 0)
		else:
			direction = Vector2(0, sign(blk_relative.y))
		
		#this is the only place where the direction vector gets changed
		direction_normal = direction.rotated(PI * 0.5)
	
	#i dont know how to simplify this
	
	#determine whether the arrow will need a corner in it
	#i check whether the blocks sides normal to the direction vector are too far
	#for a straight arrow with no corner
	#___
	#  |
	#  V
	#   ___
	
	#getting the distance between the blocks based on the direction of the first part of the arrow
	var blk_relative_distance_vec : Vector2 = blk_relative * direction_normal
	var blk_relative_distance : float
	
	#set it to negative if the x or y are negative
	#since length() does not consider the direction
	if blk_relative_distance_vec.x < 0 or blk_relative_distance_vec.y < 0:
		blk_relative_distance = -blk_relative_distance_vec.length()
	else:
		blk_relative_distance = blk_relative_distance_vec.length()
	
	
	#length of the blocks sides that stand normal (90 deg) to the direction vector, halved
	var block_offset_max = abs((blk_1.size * direction_normal).length() + (blk_2.size * direction_normal).length()) * 0.5
	
	#check if direction is valid for positioning of blocks, considering tolerance
	#if the parallel sides of the blocks are too far from each other, add a mid point
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	if block_offset_max - tolerance < abs(blk_relative_distance):
		#print("too far for tolerance")
		
		"TODO v0.2"#add arrow gap to start calculation
		var start : Vector2 = blk_1_ct
		var mid : Vector2
		
		var blk_relative_abs : Vector2 = blk_relative
		
		blk_relative_abs.x = abs(blk_relative.x)
		blk_relative_abs.y = abs(blk_relative.y)
		
		
		mid = start + blk_relative_abs * direction
		var end : Vector2 = mid
		
		
		var end_to_mid_unit : Vector2 = (blk_2_ct - mid).normalized()
		end = end + -end_to_mid_unit * blk_2_size_h + end_to_mid_unit * blk_relative_abs + -end_to_mid_unit * (arrow_end_length + arrow_gap)
		
		
		points.append(start + blk_1_size_h * direction)
		points.append(mid)
		points.append(end)
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	else:
		#print("close enough for tolerance")
		#get the center of the edge that the direction variable is pointing to
		var start : Vector2 = blk_1_ct + blk_1_size_h * direction
		var end : Vector2 = blk_1_ct + blk_2_size_h * -direction
		end = end + (blk_relative * direction * sign(blk_relative))
		
		"TODO v0.2"#add arrow gap to start point calculation
		#(for straight and corner arrows)
		#start = start + direction * arrow_gap
		
		#block 1 size in normal direction
		var blk_1_size_dn : float = (blk_1.size * direction_normal).length()
		#block 2 size in normal direction
		var blk_2_size_dn : float = (blk_2.size * direction_normal).length()
		#
		var offset = (blk_relative * direction_normal).length()
		
		#if block 1 is wider
		"TODO v0.2"#rework comments here
		if blk_1_size_dn > blk_2_size_dn:
#blk 1 wider
#-------------------------------------------------------------------------------
			print("blk 1 wider")
			#stay centered on the thinner block
			start = blk_2_ct + blk_1_size_h * direction
			end = blk_2_ct + blk_2_size_h * -direction
			start = start + (blk_relative * -direction * sign(blk_relative))
			
			#offset - wider block + thinner block
			#that way offset only goes above 0 when the blocks are
			#far enough from each other
			
			offset = (offset - blk_1_size_dn * 0.5) + blk_2_size_dn * 0.5
			offset = max(offset, 0) * 0.5
			
			#then flip direction again for when the arrow is on different sides
			if direction.x < 0 or direction.y > 0:
				offset = -offset
			
			offset = offset * direction_normal * -sign(blk_relative)
			print(offset)
			
			#add offset
			start = start + offset
			end = end + offset
#blk 2 wider
#-------------------------------------------------------------------------------
		else:
			offset = (offset - blk_2_size_dn * 0.5) + blk_1_size_dn * 0.5
			offset = max(offset, 0) * 0.5
			
			#then flip direction again for when the arrow is on different sides
			if direction.x > 0 or direction.y < 0:
				offset = -offset
			
			print("blk 2 wider")
			offset = offset * direction_normal * -sign(blk_relative)
			print(offset)
			
			start = start + offset
			end = end + offset
#-------------------------------------------------------------------------------
		
		
		#offset
		end = end - direction * (arrow_end_length + arrow_gap)
		points.append(start)
		points.append(end)
	#-----------------------------------------------------------------------------------------------
	#-----------------------------------------------------------------------------------------------
	
	#assign finalized point array to line2d
	line.points = points
	
	
	#construct arrow tip
	var polygons : PackedVector2Array = PackedVector2Array()
	polygons.append(Vector2.UP * arrow_end_length)
	polygons.append(Vector2.RIGHT * (arrow_end_width * 0.5))
	polygons.append(Vector2.LEFT * (arrow_end_width * 0.5))
	arrow_end.polygon = polygons
	
	
	#set arrow end position to end of line
	#use atan(y, x) to rotate arrow end accordingly
	if points.size() > 1:
		arrow_end.position = points[points.size() - 1]
		var arrow_end_vec : Vector2 = points[points.size() - 1] - points[points.size() - 2]
		arrow_end_vec = arrow_end_vec.normalized()
		arrow_end.rotation = atan2(arrow_end_vec.y, arrow_end_vec.x) + PI * 0.5
	
