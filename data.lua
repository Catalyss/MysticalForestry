local main_menu_simulations = data.raw["utility-constants"]["default"].main_menu_simulations

main_menu_simulations.example_base = {
  checkboard = false,
  save = "__MysticalForestry__/menu-simulations/example_base.zip",
  length = 60*141,
  volume_modifier = 0.6,
  init =
  [[    
    game.simulation.camera_position = {-178 , 8}
    game.simulation.camera_zoom = ]]..(0.370)..[[
    game.tick_paused = false
    game.surfaces.nauvis.daytime = 0
    game.simulation.camera_alt_info = false
    ]],
  update = [[
  ]]
}