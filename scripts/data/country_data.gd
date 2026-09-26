class_name CountryData
extends Resource

@export var id := "ar"
@export var title := "Argentina"
@export var description := ""
@export var facade := "res://assets/city/buildings/cafe.png"
@export var accent := Color("d3b17b")
@export var pavement := Color("c8c4af")
@export var greenery := "res://assets/city/vegetation/tree.png"
@export var home_kind := "Casa"
@export var shop_names: Array[String] = []
@export var cities: Array[CityData] = []
