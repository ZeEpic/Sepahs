class_name Tile
extends Area2D

onready var origin_color: Color = modulate # the color assigned at the beginning of the game because it might change as the game goes on, so it needs to remember it's original color
var dark: bool # the variable for storing if this is a darker or lighter tile; true means it's darker
