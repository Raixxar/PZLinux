PZLinux = PZLinux or {}

PZLinux.MissionLocations = PZLinux.MissionLocations or {}
PZLinux.MissionLocations.version = 2
PZLinux.MissionLocations.mapBuild = "B42.20"

PZLinux.MissionLocations.cities = PZLinux.MissionLocations.cities or {
    [1] = "Irvington",
    [2] = "Ekron",
    [3] = "Brandenburg",
    [4] = "Echo Creek",
    [5] = "Riverside",
    [6] = "Fallas Lake",
    [7] = "Rosewood",
    [8] = "March Ridge",
    [9] = "Muldraugh",
    [10] = "West Point",
    [11] = "Valley Station",
    [12] = "Louisville",
    [13] = "Coalfield",
}

local function PZLinuxMissionLocationsEmptyCityPools()
    local pools = {}
    for cityId in pairs(PZLinux.MissionLocations.cities) do
        pools[cityId] = {}
    end
    return pools
end

PZLinux.MissionLocations.pools = PZLinux.MissionLocations.pools or {}

PZLinux.MissionLocations.pools.packages = PZLinux.MissionLocations.pools.packages or {
    byCityId = {
        [1] = {
            { id = "pkg_irvington_fire_department_01", description = "At the Irvington Fire Department.", x = 2493, y = 14050, z = 0, city = "Irvington", building = "Fire Department", tags = { "package", "fire_station" }, enabled = true },
            { id = "pkg_irvington_tobacco_01", description = "At the Irvington Tobacco store.", x = 2578, y = 14472, z = 0, city = "Irvington", building = "Tobacco", tags = { "package", "shop" }, enabled = true },
            { id = "pkg_irvington_metalhead_tool_shop_01", description = "At Metalhead Tool Shop in Irvington.", x = 2376, y = 14478, z = 0, city = "Irvington", building = "Metalhead Tool Shop", tags = { "package", "tools", "shop" }, enabled = true },
            { id = "pkg_irvington_zippe_market_01", description = "At Zippe Market in Irvington.", x = 2235, y = 14465, z = 0, city = "Irvington", building = "Zippe Market", tags = { "package", "market" }, enabled = true },
            { id = "pkg_irvington_gun_shop_01", description = "At the Irvington Gun Shop.", x = 1855, y = 14154, z = 0, city = "Irvington", building = "Gun Shop", tags = { "package", "gun_shop", "danger" }, enabled = true },
            { id = "pkg_irvington_mass_genfac_01", description = "At Mass-Genfac CO in Irvington.", x = 3106, y = 14481, z = 0, city = "Irvington", building = "Mass-Genfac CO", tags = { "package", "industrial" }, enabled = true },
            { id = "pkg_irvington_f_arable_01", description = "At F.Arable near Irvington.", x = 3754, y = 14682, z = 0, city = "Irvington", building = "F.Arable", tags = { "package", "farm" }, enabled = true },
        },
        [2] = {},
        [3] = {
            { id = "pkg_brandenburg_middle_school_01", description = "At Brandenburg Middle School.", x = 2076, y = 6181, z = 0, city = "Brandenburg", building = "Middle School", tags = { "package", "school" }, enabled = true },
            { id = "pkg_brandenburg_fire_01", description = "At Brandenburg Fire.", x = 2081, y = 6294, z = 0, city = "Brandenburg", building = "Brandenburg Fire", tags = { "package", "fire_station" }, enabled = true },
            { id = "pkg_brandenburg_brunos_dc_01", description = "At Bruno's US DCARS in Brandenburg.", x = 2009, y = 6514, z = 0, city = "Brandenburg", building = "Bruno's US DCARS", tags = { "package", "vehicle", "shop" }, enabled = true },
            { id = "pkg_brandenburg_golden_sunset_01", description = "At Golden Sunset Nursing Home in Brandenburg.", x = 2234, y = 5746, z = 0, city = "Brandenburg", building = "Golden Sunset Nursing Home", tags = { "package", "medical" }, enabled = true },
        },
        [4] = {
            { id = "pkg_echo_creek_diner_01", description = "At the Echo Creek Diner.", x = 3573, y = 10907, z = 0, city = "Echo Creek", building = "Diner", tags = { "package", "food" }, enabled = true },
            { id = "pkg_echo_creek_speedy_go_01", description = "At Speedy GO Trucking & Transport in Echo Creek.", x = 3668, y = 10885, z = 0, city = "Echo Creek", building = "Speedy GO Trucking & Transport", tags = { "package", "industrial", "transport" }, enabled = true },
        },
        [5] = {},
        [6] = {},
        [7] = {
            { id = "pkg_rosewood_zippe_market_01", description = "At Zippe Market in Rosewood.", x = 8096, y = 11552, z = 0, city = "Rosewood", building = "Zippe Market", tags = { "package", "market" }, enabled = true },
            { id = "pkg_rosewood_balted_goods_01", description = "At Balted Goods in Rosewood.", x = 8057, y = 11568, z = 0, city = "Rosewood", building = "Balted Goods", tags = { "package", "shop" }, enabled = true },
            { id = "pkg_rosewood_spiffos_01", description = "At Spiffo's in Rosewood.", x = 8079, y = 11348, z = 0, city = "Rosewood", building = "Spiffo's", tags = { "package", "food" }, enabled = true },
            { id = "pkg_rosewood_pizza_whirled_01", description = "At Pizza Whirled in Rosewood.", x = 8079, y = 11307, z = 0, city = "Rosewood", building = "Pizza Whirled", tags = { "package", "food" }, enabled = true },
            { id = "pkg_rosewood_harry_denton_01", description = "At Mechanic Harry Denton in Rosewood.", x = 8245, y = 11257, z = 0, city = "Rosewood", building = "Mechanic Harry Denton", tags = { "package", "garage" }, enabled = true },
            { id = "pkg_rosewood_gigamart_01", description = "At GigaMart in Rosewood.", x = 8019, y = 11260, z = 0, city = "Rosewood", building = "GigaMart", tags = { "package", "market" }, enabled = true },
        },
        [8] = {
            { id = "pkg_march_ridge_nourish_food_mart_01", description = "At Nourish Food Mart in March Ridge.", x = 10115, y = 12804, z = 0, city = "March Ridge", building = "Nourish Food Mart", tags = { "package", "market" }, enabled = true },
            { id = "pkg_march_ridge_school_01", description = "At March Ridge School.", x = 10011, y = 12657, z = 0, city = "March Ridge", building = "March Ridge School", tags = { "package", "school" }, enabled = true },
        },
        [9] = {
            { id = "pkg_muldraugh_pizza_whirled_01", description = "At Pizza Whirled in Muldraugh.", x = 10608, y = 10110, z = 0, city = "Muldraugh", building = "Pizza Whirled", tags = { "package", "food" }, enabled = true },
            { id = "pkg_muldraugh_greenes_01", description = "At Greene's in Muldraugh.", x = 10612, y = 10264, z = 0, city = "Muldraugh", building = "Greene's", tags = { "package", "shop" }, enabled = true },
            { id = "pkg_muldraugh_police_station_01", description = "At the Muldraugh Police Station.", x = 10637, y = 10419, z = 0, city = "Muldraugh", building = "Police Station", tags = { "package", "police", "danger" }, enabled = true },
            { id = "pkg_muldraugh_diner_01", description = "At the Muldraugh Diner.", x = 10617, y = 10564, z = 0, city = "Muldraugh", building = "Diner", tags = { "package", "food" }, enabled = true },
            { id = "pkg_muldraugh_fossoil_01", description = "At Fossoil in Muldraugh.", x = 10634, y = 9765, z = 0, city = "Muldraugh", building = "Fossoil", tags = { "package", "gas_station" }, enabled = true },
            { id = "pkg_muldraugh_food_market_01", description = "At Food Market in Muldraugh.", x = 10856, y = 9752, z = 0, city = "Muldraugh", building = "Food Market", tags = { "package", "market" }, enabled = true },
            { id = "pkg_muldraugh_laundromat_01", description = "At the Muldraugh Laundromat.", x = 10611, y = 9465, z = 0, city = "Muldraugh", building = "Laundromat", tags = { "package", "shop" }, enabled = true },
        },
        [10] = {
            { id = "pkg_west_point_the_drake_01", description = "At The Drake in West Point.", x = 11914, y = 6855, z = 0, city = "West Point", building = "The Drake", tags = { "package", "bar" }, enabled = true },
            { id = "pkg_west_point_thunder_sas_01", description = "At Thunder SAS in West Point.", x = 11822, y = 6869, z = 0, city = "West Point", building = "Thunder SAS", tags = { "package", "gas_station" }, enabled = true },
            { id = "pkg_west_point_snacks_n_stuff_01", description = "At Snacks N Stuff in West Point.", x = 11530, y = 6885, z = 0, city = "West Point", building = "Snacks N Stuff", tags = { "package", "shop" }, enabled = true },
            { id = "pkg_west_point_train_station_01", description = "At the West Point Train Station.", x = 12168, y = 6942, z = 0, city = "West Point", building = "Train Station", tags = { "package", "transport" }, enabled = true },
        },
        [11] = {},
        [12] = {
            { id = "pkg_louisville_milk_n_more_01", description = "At Milk N More in Louisville.", x = 12673, y = 2131, z = 0, city = "Louisville", building = "Milk N More", tags = { "package", "market" }, enabled = true },
            { id = "pkg_louisville_topcrown_plaza_01", description = "At Topcrown Plaza in Louisville.", x = 12651, y = 1642, z = 0, city = "Louisville", building = "Topcrown Plaza", tags = { "package", "mall" }, enabled = true },
            { id = "pkg_louisville_conven_u_mart_01", description = "At Conven-U-Mart in Louisville.", x = 12385, y = 1565, z = 0, city = "Louisville", building = "Conven-U-Mart", tags = { "package", "market" }, enabled = true },
            { id = "pkg_louisville_awl_work_01", description = "At Awl Work and Sew Play in Louisville.", x = 13185, y = 1560, z = 0, city = "Louisville", building = "Awl Work and Sew Play", tags = { "package", "shop" }, enabled = true },
        },
        [13] = {
            { id = "pkg_coalfield_gun_shop_01", description = "At the Coalfield Gun Shop.", x = 3799, y = 8510, z = 0, city = "Coalfield", building = "Gun Shop", tags = { "package", "gun_shop", "danger" }, enabled = true },
        },
    },
}

PZLinux.MissionLocations.pools.vehicles = PZLinux.MissionLocations.pools.vehicles or {
    byCityId = {
        [1] = {
            { id = "veh_irvington_peach_st_01", name = "Vehicle pickup near Peach St", description = "Vehicle pickup near Peach St in Irvington.", x = 2415, y = 14223, z = 0, city = "Irvington", street = "Peach St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_irvington_merino_st_01", name = "Vehicle pickup near Merino St", description = "Vehicle pickup near Merino St in Irvington.", x = 2241, y = 14418, z = 0, city = "Irvington", street = "Merino St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_irvington_irvington_st_01", name = "Vehicle pickup near Irvington St", description = "Vehicle pickup near Irvington St in Irvington.", x = 1890, y = 14491, z = 0, city = "Irvington", street = "Irvington St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_irvington_ky_79_01", name = "Vehicle pickup near KY-79", description = "Vehicle pickup near KY-79 in Irvington.", x = 3049, y = 14478, z = 0, city = "Irvington", street = "KY-79", tags = { "vehicle", "spawn", "road" }, enabled = true },
        },
        [2] = {},
        [3] = {
            { id = "veh_brandenburg_boyd_road_01", name = "Vehicle pickup near Boyd Road", description = "Vehicle pickup near Boyd Road in Brandenburg.", x = 2076, y = 6026, z = 0, city = "Brandenburg", street = "Boyd Road", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_brandenburg_n_brand_st_01", name = "Vehicle pickup near N Brand St", description = "Vehicle pickup near N Brand St in Brandenburg.", x = 1630, y = 5655, z = 0, city = "Brandenburg", street = "N Brand St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_brandenburg_lakeview_lane_01", name = "Vehicle pickup near Lakeview Lane", description = "Vehicle pickup near Lakeview Lane in Brandenburg.", x = 1886, y = 6384, z = 0, city = "Brandenburg", street = "Lakeview Lane", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_brandenburg_ohio_dr_01", name = "Vehicle pickup near Ohio Dr", description = "Vehicle pickup near Ohio Dr in Brandenburg.", x = 2152, y = 6366, z = 0, city = "Brandenburg", street = "Ohio Dr", tags = { "vehicle", "spawn", "road" }, enabled = true },
        },
        [4] = {
            { id = "veh_echo_creek_payne_road_01", name = "Vehicle pickup near Payne Road", description = "Vehicle pickup near Payne Road in Echo Creek.", x = 3583, y = 10914, z = 0, city = "Echo Creek", street = "Payne Road", tags = { "vehicle", "spawn", "road" }, enabled = true },
        },
        [5] = {
            { id = "veh_riverside_rosewood_st_01", name = "Vehicle pickup near Rosewood St", description = "Vehicle pickup near Rosewood St in Riverside.", x = 6483, y = 5364, z = 0, city = "Riverside", street = "Rosewood St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_riverside_ohio_st_01", name = "Vehicle pickup near Ohio St", description = "Vehicle pickup near Ohio St in Riverside.", x = 6569, y = 5330, z = 0, city = "Riverside", street = "Ohio St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_riverside_lincoln_st_01", name = "Vehicle pickup near Lincoln St", description = "Vehicle pickup near Lincoln St in Riverside.", x = 6209, y = 5371, z = 0, city = "Riverside", street = "Lincoln St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_riverside_ark_lane_01", name = "Vehicle pickup near Ark Lane", description = "Vehicle pickup near Ark Lane in Riverside.", x = 6061, y = 5320, z = 0, city = "Riverside", street = "Ark Lane", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_riverside_w_main_st_01", name = "Vehicle pickup near W Main St", description = "Vehicle pickup near W Main St in Riverside.", x = 6091, y = 5212, z = 0, city = "Riverside", street = "W Main St", tags = { "vehicle", "spawn", "street" }, enabled = true },
        },
        [6] = {},
        [7] = {
            { id = "veh_rosewood_doctors_lane_01", name = "Vehicle pickup near Doctors Lane", description = "Vehicle pickup near Doctors Lane in Rosewood.", x = 8056, y = 11509, z = 0, city = "Rosewood", street = "Doctors Lane", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_rosewood_shelf_st_01", name = "Vehicle pickup near Shelf St", description = "Vehicle pickup near Shelf St in Rosewood.", x = 8041, y = 11273, z = 0, city = "Rosewood", street = "Shelf St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_rosewood_jc_carroll_road_01", name = "Vehicle pickup near JC Carroll Road", description = "Vehicle pickup near JC Carroll Road in Rosewood.", x = 8233, y = 11352, z = 0, city = "Rosewood", street = "JC Carroll Road", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_rosewood_south_main_st_01", name = "Vehicle pickup near South Main St", description = "Vehicle pickup near South Main St in Rosewood.", x = 8151, y = 11758, z = 0, city = "Rosewood", street = "South Main St", tags = { "vehicle", "spawn", "street" }, enabled = true },
        },
        [8] = {
            { id = "veh_march_ridge_nelson_dr_01", name = "Vehicle pickup near Nelson Dr", description = "Vehicle pickup near Nelson Dr in March Ridge.", x = 10052, y = 12764, z = 0, city = "March Ridge", street = "Nelson Dr", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_march_ridge_folger_st_01", name = "Vehicle pickup near Folger St", description = "Vehicle pickup near Folger St in March Ridge.", x = 10088, y = 12657, z = 0, city = "March Ridge", street = "Folger St", tags = { "vehicle", "spawn", "street" }, enabled = true },
        },
        [9] = {
            { id = "veh_muldraugh_franklin_st_01", name = "Vehicle pickup near Franklin St", description = "Vehicle pickup near Franklin St in Muldraugh.", x = 10641, y = 9846, z = 0, city = "Muldraugh", street = "Franklin St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_muldraugh_harris_court_01", name = "Vehicle pickup near Harris Court", description = "Vehicle pickup near Harris Court in Muldraugh.", x = 10733, y = 9585, z = 0, city = "Muldraugh", street = "Harris Court", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_muldraugh_s_main_st_01", name = "Vehicle pickup near S Main St", description = "Vehicle pickup near S Main St in Muldraugh.", x = 10770, y = 10584, z = 0, city = "Muldraugh", street = "S Main St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_muldraugh_harris_st_01", name = "Vehicle pickup near Harris St", description = "Vehicle pickup near Harris St in Muldraugh.", x = 10854, y = 9532, z = 0, city = "Muldraugh", street = "Harris St", tags = { "vehicle", "spawn", "street" }, enabled = true },
        },
        [10] = {
            { id = "veh_west_point_5th_st_01", name = "Vehicle pickup near 5th St", description = "Vehicle pickup near 5th St in West Point.", x = 11835, y = 6808, z = 0, city = "West Point", street = "5th St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_west_point_goggins_st_01", name = "Vehicle pickup near Goggins St", description = "Vehicle pickup near Goggins St in West Point.", x = 11371, y = 6826, z = 0, city = "West Point", street = "Goggins St", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_west_point_dixie_highway_01", name = "Vehicle pickup near Dixie Highway", description = "Vehicle pickup near Dixie Highway (Route 31W) in West Point.", x = 12000, y = 7137, z = 0, city = "West Point", street = "Dixie Highway (Route 31W)", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_west_point_oak_st_01", name = "Vehicle pickup near Oak St", description = "Vehicle pickup near Oak St in West Point.", x = 12145, y = 6820, z = 0, city = "West Point", street = "Oak St", tags = { "vehicle", "spawn", "street" }, enabled = true },
        },
        [11] = {},
        [12] = {
            { id = "veh_louisville_virginia_av_01", name = "Vehicle pickup near Virginia Av", description = "Vehicle pickup near Virginia Av in Louisville.", x = 12940, y = 1602, z = 0, city = "Louisville", street = "Virginia Av", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_louisville_w_river_road_01", name = "Vehicle pickup near W River Road", description = "Vehicle pickup near W River Road in Louisville.", x = 12400, y = 1262, z = 0, city = "Louisville", street = "W River Road", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_louisville_greengrass_lane_01", name = "Vehicle pickup near Greengrass Lane", description = "Vehicle pickup near Greengrass Lane in Louisville.", x = 13705, y = 1573, z = 0, city = "Louisville", street = "Greengrass Lane", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_louisville_bass_road_01", name = "Vehicle pickup near Bass Road", description = "Vehicle pickup near Bass Road in Louisville.", x = 13702, y = 1392, z = 0, city = "Louisville", street = "Bass Road", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_louisville_bass_road_02", name = "Vehicle pickup near Bass Road", description = "Vehicle pickup near Bass Road in Louisville.", x = 13638, y = 1412, z = 0, city = "Louisville", street = "Bass Road", tags = { "vehicle", "spawn", "road" }, enabled = true },
            { id = "veh_louisville_bourbon_way_01", name = "Vehicle pickup near Bourbon Way", description = "Vehicle pickup near Bourbon Way in Louisville.", x = 12013, y = 1868, z = 0, city = "Louisville", street = "Bourbon Way", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_louisville_bourbon_way_02", name = "Vehicle pickup near Bourbon Way", description = "Vehicle pickup near Bourbon Way in Louisville.", x = 12016, y = 1646, z = 0, city = "Louisville", street = "Bourbon Way", tags = { "vehicle", "spawn", "street" }, enabled = true },
            { id = "veh_louisville_5th_st_01", name = "Vehicle pickup near 5th St", description = "Vehicle pickup near 5th St in Louisville.", x = 12075, y = 1275, z = 0, city = "Louisville", street = "5th St", tags = { "vehicle", "spawn", "street" }, enabled = true },
        },
        [13] = {},
    },
}

PZLinux.MissionLocations.pools.cargo = PZLinux.MissionLocations.pools.cargo or {
    byCityId = {
        [1] = {
            { id = "cargo_irvington_peach_st_01", description = "Cargo near Peach St in Irvington.", x = 2407, y = 14198, z = 0, city = "Irvington", street = "Peach St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_irvington_ky_79_01", description = "Cargo near KY-79 in Irvington.", x = 2480, y = 14489, z = 0, city = "Irvington", street = "KY-79", tags = { "cargo", "road" }, enabled = true },
            { id = "cargo_irvington_dempsey_st_01", description = "Cargo near Dempsey St in Irvington.", x = 2247, y = 14499, z = 0, city = "Irvington", street = "Dempsey St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_irvington_western_railroad_01", description = "Cargo near Western Railroad in Irvington.", x = 2503, y = 13997, z = 0, city = "Irvington", street = "Western Railroad", tags = { "cargo", "railroad" }, enabled = true },
        },
        [2] = {},
        [3] = {
            { id = "cargo_brandenburg_boyd_road_01", description = "Cargo near Boyd Road in Brandenburg.", x = 2093, y = 6102, z = 0, city = "Brandenburg", street = "Boyd Road", tags = { "cargo", "road" }, enabled = true },
            { id = "cargo_brandenburg_ridge_st_01", description = "Cargo near Ridge St in Brandenburg.", x = 2318, y = 6285, z = 0, city = "Brandenburg", street = "Ridge St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_brandenburg_greer_road_01", description = "Cargo near Greer Road in Brandenburg.", x = 2351, y = 6113, z = 0, city = "Brandenburg", street = "Greer Road", tags = { "cargo", "road" }, enabled = true },
            { id = "cargo_brandenburg_bypass_01", description = "Cargo near Brandenburg Bypass.", x = 1974, y = 6483, z = 0, city = "Brandenburg", street = "Brandenburg Bypass", tags = { "cargo", "road" }, enabled = true },
        },
        [4] = {
            { id = "cargo_echo_creek_payne_road_01", description = "Cargo near Payne Road in Echo Creek.", x = 3529, y = 10928, z = 0, city = "Echo Creek", street = "Payne Road", tags = { "cargo", "road" }, enabled = true },
        },
        [5] = {},
        [6] = {},
        [7] = {
            { id = "cargo_rosewood_quiet_st_01", description = "Cargo near Quiet St in Rosewood.", x = 8103, y = 11473, z = 0, city = "Rosewood", street = "Quiet St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_rosewood_frederick_lane_01", description = "Cargo near Frederick Lane in Rosewood.", x = 8103, y = 11577, z = 0, city = "Rosewood", street = "Frederick Lane", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_rosewood_south_main_st_01", description = "Cargo near South Main St in Rosewood.", x = 8203, y = 11767, z = 0, city = "Rosewood", street = "South Main St", tags = { "cargo", "street" }, enabled = true },
        },
        [8] = {},
        [9] = {
            { id = "cargo_muldraugh_franklin_st_01", description = "Cargo near Franklin St in Muldraugh.", x = 10705, y = 9855, z = 0, city = "Muldraugh", street = "Franklin St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_muldraugh_dixie_highway_01", description = "Cargo near Dixie Highway in Muldraugh.", x = 10588, y = 9739, z = 0, city = "Muldraugh", street = "Dixie Highway", tags = { "cargo", "road" }, enabled = true },
            { id = "cargo_muldraugh_s_main_st_01", description = "Cargo near S Main St in Muldraugh.", x = 10827, y = 9868, z = 0, city = "Muldraugh", street = "S Main St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_muldraugh_irma_dr_01", description = "Cargo near Irma Dr in Muldraugh.", x = 10933, y = 9458, z = 0, city = "Muldraugh", street = "Irma Dr", tags = { "cargo", "street" }, enabled = true },
        },
        [10] = {
            { id = "cargo_west_point_7th_st_01", description = "Cargo near 7th St in West Point.", x = 11681, y = 6826, z = 0, city = "West Point", street = "7th St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_west_point_mulberry_st_01", description = "Cargo near Mulberry St in West Point.", x = 11996, y = 6833, z = 0, city = "West Point", street = "Mulberry St", tags = { "cargo", "street" }, enabled = true },
        },
        [11] = {},
        [12] = {
            { id = "cargo_louisville_n_1st_st_01", description = "Cargo near N 1st St in Louisville.", x = 12614, y = 1507, z = 0, city = "Louisville", street = "N 1st St", tags = { "cargo", "street" }, enabled = true },
            { id = "cargo_louisville_n_shelby_road_01", description = "Cargo near N Shelby Road in Louisville.", x = 13508, y = 1512, z = 0, city = "Louisville", street = "N Shelby Road", tags = { "cargo", "road" }, enabled = true },
            { id = "cargo_louisville_waverly_st_01", description = "Cargo near Waverly St in Louisville.", x = 12938, y = 2996, z = 0, city = "Louisville", street = "Waverly St", tags = { "cargo", "street" }, enabled = true },
        },
        [13] = {
            { id = "cargo_coalfield_downtown_01", description = "Cargo near Downtown Coalfield.", x = 3456, y = 8196, z = 0, city = "Coalfield", street = "Downtown", tags = { "cargo", "downtown" }, enabled = true },
        },
    },
}

PZLinux.MissionLocations.pools.manhunt = PZLinux.MissionLocations.pools.manhunt or {
    byCityId = {
        [1] = {
            { id = "target_irvington_old_church_st_01", description = "The target was last seen near Old Church St in Irvington.", x = 2825, y = 13802, z = 0, city = "Irvington", street = "Old Church St", tags = { "target", "zombie_spawn", "street" }, enabled = false },
        },
        [2] = {},
        [3] = {
            { id = "target_brandenburg_river_front_park_01", description = "The target was last seen near River Front Park in Brandenburg.", x = 2025, y = 5682, z = 0, city = "Brandenburg", street = "River Front Park", tags = { "target", "zombie_spawn", "park" }, enabled = false },
            { id = "target_brandenburg_n_brand_st_01", description = "The target was last seen near N Brand St in Brandenburg.", x = 1642, y = 5576, z = 0, city = "Brandenburg", street = "N Brand St", tags = { "target", "zombie_spawn", "street" }, enabled = false },
        },
        [4] = {},
        [5] = {
            { id = "target_riverside_maria_pl_01", description = "The target was last seen near Maria Pl in Riverside.", x = 6333, y = 5198, z = 0, city = "Riverside", street = "Maria Pl", tags = { "target", "zombie_spawn", "street" }, enabled = false },
            { id = "target_riverside_maria_pl_02", description = "The target was last seen near Maria Pl in Riverside.", x = 6378, y = 5138, z = 0, city = "Riverside", street = "Maria Pl", tags = { "target", "zombie_spawn", "street" }, enabled = false },
            { id = "target_riverside_e_main_st_01", description = "The target was last seen near E Main St in Riverside.", x = 6825, y = 5257, z = 0, city = "Riverside", street = "E Main St", tags = { "target", "zombie_spawn", "street" }, enabled = false },
            { id = "target_riverside_walnut_st_01", description = "The target was last seen near Walnut St in Riverside.", x = 5929, y = 5364, z = 0, city = "Riverside", street = "Walnut St", tags = { "target", "zombie_spawn", "street" }, enabled = false },
            { id = "target_riverside_rag_road_01", description = "The target was last seen near Rag Road in Riverside.", x = 5785, y = 5379, z = 0, city = "Riverside", street = "Rag Road", tags = { "target", "zombie_spawn", "road" }, enabled = false },
        },
        [6] = {},
        [7] = {
            { id = "target_rosewood_frederick_lane_01", description = "The target was last seen near Frederick Lane in Rosewood.", x = 8351, y = 11528, z = 0, city = "Rosewood", street = "Frederick Lane", tags = { "target", "zombie_spawn", "street" }, enabled = false },
            { id = "target_rosewood_horselick_road_01", description = "The target was last seen near Horselick Road outside Rosewood.", x = 7436, y = 11876, z = 0, city = "Rosewood", street = "Horselick Road", tags = { "target", "zombie_spawn", "remote" }, enabled = false },
            { id = "target_rosewood_yew_road_01", description = "The target was last seen near Yew Road in Rosewood.", x = 8801, y = 11603, z = 0, city = "Rosewood", street = "Yew Road", tags = { "target", "zombie_spawn", "road" }, enabled = false },
        },
        [8] = {},
        [9] = {
            { id = "target_muldraugh_dixie_highway_01", description = "The target was last seen near Dixie Highway in Muldraugh.", x = 10609, y = 9221, z = 0, city = "Muldraugh", street = "Dixie Highway (Route 31W)", tags = { "target", "zombie_spawn", "road" }, enabled = true },
        },
        [10] = {
            { id = "target_west_point_7th_st_01", description = "The target was last seen near 7th St in West Point.", x = 11737, y = 6978, z = 0, city = "West Point", street = "7th St", tags = { "target", "zombie_spawn", "street" }, enabled = false },
            { id = "target_west_point_oak_st_01", description = "The target was last seen near Oak St in West Point.", x = 11075, y = 6692, z = 0, city = "West Point", street = "Oak St", tags = { "target", "zombie_spawn", "street" }, enabled = false },
        },
        [11] = {},
        [12] = {
            { id = "target_louisville_e_river_road_01", description = "The target was last seen near E River Road in Louisville.", x = 12983, y = 1133, z = 0, city = "Louisville", street = "E River Road", tags = { "target", "zombie_spawn", "road" }, enabled = false },
            { id = "target_louisville_bourbon_way_01", description = "The target was last seen near Bourbon Way in Louisville.", x = 11990, y = 1662, z = 0, city = "Louisville", street = "Bourbon Way", tags = { "target", "zombie_spawn", "street" }, enabled = false },
        },
        [13] = {},
    },
}

PZLinux.MissionLocations.pools.protect = PZLinux.MissionLocations.pools.protect or {
    byCityId = {
        [1] = {},
        [2] = {
            { id = "protect_ekron_hutchins_dr_01", description = "Protect the building near Hutchins Dr in Ekron.", x = 415, y = 9835, z = 0, city = "Ekron", street = "Hutchins Dr", tags = { "protect", "horde", "building" }, enabled = true },
            { id = "protect_ekron_reese_ave_01", description = "Protect the building near Reese Ave in Ekron.", x = 688, y = 9858, z = 0, city = "Ekron", street = "Reese Ave", tags = { "protect", "horde", "building" }, enabled = true },
        },
        [3] = {
            { id = "protect_brandenburg_boyd_road_01", description = "Protect the building near Boyd Road in Brandenburg.", x = 2073, y = 6311, z = 0, city = "Brandenburg", street = "Boyd Road", tags = { "protect", "horde", "building" }, enabled = true },
            { id = "protect_brandenburg_boyd_road_02", description = "Protect the building near Boyd Road in Brandenburg.", x = 2047, y = 6004, z = 0, city = "Brandenburg", street = "Boyd Road", tags = { "protect", "horde", "building" }, enabled = true },
        },
        [4] = {},
        [5] = {
            { id = "protect_riverside_maria_pl_01", description = "Protect the building near Maria Pl in Riverside.", x = 6428, y = 5205, z = 0, city = "Riverside", street = "Maria Pl", tags = { "protect", "horde", "building" }, enabled = true },
            { id = "protect_riverside_w_main_st_01", description = "Protect the building near W Main St in Riverside.", x = 6087, y = 5248, z = 0, city = "Riverside", street = "W Main St", tags = { "protect", "horde", "building" }, enabled = true },
            { id = "protect_riverside_harbor_st_01", description = "Protect the building near Harbor St in Riverside.", x = 6264, y = 5347, z = 0, city = "Riverside", street = "Harbor St", tags = { "protect", "horde", "building" }, enabled = true },
        },
        [6] = {},
        [7] = {},
        [8] = {},
        [9] = {},
        [10] = {},
        [11] = {},
        [12] = {},
        [13] = {},
    },
}

PZLinux.MissionLocations.pools.mailDrops = PZLinux.MissionLocations.pools.mailDrops or {
    ammo = {
        byCityId = PZLinuxMissionLocationsEmptyCityPools(),
    },
    medical = {
        byCityId = PZLinuxMissionLocationsEmptyCityPools(),
    },
}
PZLinux.MissionLocations.pools.mailDrops.ammo.byCityId = PZLinux.MissionLocations.pools.packages.byCityId
PZLinux.MissionLocations.pools.mailDrops.medical.byCityId = PZLinux.MissionLocations.pools.packages.byCityId

PZLinux.MissionLocations.templates = PZLinux.MissionLocations.templates or {
    package = { id = "pkg_city_place_container_01", description = "At <place>, in <container>.", x = 0, y = 0, z = 0, city = "<city>", tags = { "package" }, enabled = false },
    vehicle = { id = "veh_city_place_01", name = "Vehicle pickup at <place>", x = 0, y = 0, z = 0, city = "<city>", tags = { "vehicle", "spawn" }, enabled = false },
    cargo = { id = "cargo_city_place_01", description = "Cargo near <place>.", x = 0, y = 0, z = 0, city = "<city>", tags = { "cargo", "outdoor" }, enabled = false },
    manhunt = { id = "target_city_place_01", description = "The target was last seen near <place>.", x = 0, y = 0, z = 0, city = "<city>", tags = { "target", "zombie_spawn" }, enabled = false },
    protect = { id = "protect_city_place_01", description = "Protect the building at <place>.", x = 0, y = 0, z = 0, city = "<city>", tags = { "protect", "horde" }, enabled = false },
    mailAmmo = { id = "mail_ammo_city_place_01", name = "Ammo drop at <place>", x = 0, y = 0, z = 0, city = "<city>", tags = { "mail", "ammo" }, enabled = false },
    mailMedical = { id = "mail_medical_city_place_01", name = "Medical drop at <place>", x = 0, y = 0, z = 0, city = "<city>", tags = { "mail", "medical" }, enabled = false },
}

local function PZLinuxMissionLocationIsEnabled(location)
    return location and location.enabled ~= false and tonumber(location.x) and tonumber(location.y)
end

local function PZLinuxMissionLocationKey(location, field)
    if not location or not location.id then return nil end

    local suffix = "Description"
    if field == "name" then
        suffix = "Name"
    end

    return "IGUI_PZLinux_Location_" .. tostring(location.id) .. "_" .. suffix
end

function PZLinuxGetMissionLocationText(location, field)
    if not location then return "" end

    local fallbackField = field == "name" and "rawName" or "rawDescription"
    local fallback = location[fallbackField] or location[field] or location.building or location.street or location.city or ""
    local keyField = field == "name" and "nameKey" or "descriptionKey"
    local key = location[keyField] or PZLinuxMissionLocationKey(location, field)

    if key and getText then
        local translated = getText(key)
        if translated and translated ~= key then
            return translated
        end
    end

    return fallback
end

function PZLinuxGetMissionLocationName(location)
    return PZLinuxGetMissionLocationText(location, "name")
end

function PZLinuxGetMissionLocationDescription(location)
    return PZLinuxGetMissionLocationText(location, "description")
end

local function PZLinuxMissionLocationNormalize(location)
    if not location then return nil end
    location.rawDescription = location.rawDescription or location.description
    location.rawName = location.rawName or location.name or location.building or location.street or location.city
    location.descriptionKey = location.descriptionKey or PZLinuxMissionLocationKey(location, "description")
    location.nameKey = location.nameKey or PZLinuxMissionLocationKey(location, "name")
    location.description = PZLinuxGetMissionLocationDescription(location)
    location.name = PZLinuxGetMissionLocationName(location)
    return location
end

local function PZLinuxMissionLocationCollectEnabled(source)
    local enabled = {}
    for _, location in ipairs(source or {}) do
        if PZLinuxMissionLocationIsEnabled(location) then
            table.insert(enabled, PZLinuxMissionLocationNormalize(location))
        end
    end
    return enabled
end

local function PZLinuxMissionLocationFlattenByCity(byCityId)
    local locations = {}
    for _, cityLocations in pairs(byCityId or {}) do
        for _, location in ipairs(PZLinuxMissionLocationCollectEnabled(cityLocations)) do
            table.insert(locations, location)
        end
    end
    return locations
end

local function PZLinuxMissionLocationResolvePool(poolName)
    local pools = PZLinux.MissionLocations and PZLinux.MissionLocations.pools
    if poolName == "mailDrops.ammo" then
        return pools and pools.mailDrops and pools.mailDrops.ammo
    end
    if poolName == "mailDrops.medical" then
        return pools and pools.mailDrops and pools.mailDrops.medical
    end
    return pools and pools[poolName]
end

function PZLinuxGetMissionLocationPool(poolName, key)
    local pool = PZLinuxMissionLocationResolvePool(poolName)
    if not pool then return {} end

    if pool.byCityId then
        if key ~= nil then
            return PZLinuxMissionLocationCollectEnabled(pool.byCityId[tonumber(key)] or pool.byCityId[key])
        end
        return PZLinuxMissionLocationFlattenByCity(pool.byCityId)
    end

    if key ~= nil then
        return PZLinuxMissionLocationCollectEnabled(pool[key])
    end

    return PZLinuxMissionLocationCollectEnabled(pool)
end

function PZLinuxGetMissionLocationCityIds(poolName)
    local cityIds = {}
    local pool = PZLinuxMissionLocationResolvePool(poolName)
    if not pool or not pool.byCityId then return cityIds end

    for cityId in ipairs(PZLinux.MissionLocations.cities or {}) do
        if #PZLinuxMissionLocationCollectEnabled(pool.byCityId[cityId]) > 0 then
            table.insert(cityIds, cityId)
        end
    end
    return cityIds
end

function PZLinuxGetRandomPoolLocation(poolName, key)
    local locations = PZLinuxGetMissionLocationPool(poolName, key)
    if not locations or #locations == 0 then return nil end
    return locations[ZombRand(#locations) + 1]
end

function PZLinuxGetRandomMissionLocation(group, key)
    local aliases = {
        mails = key and ("mailDrops." .. tostring(key)) or "mailDrops",
        vehicles = "vehicles",
        retrievePackage = "packages",
        package = "packages",
        cargo = "cargo",
        manhunt = "manhunt",
        protect = "protect",
    }
    local poolName = aliases[group] or group
    if group == "mails" then
        return PZLinuxGetRandomPoolLocation(poolName)
    end
    return PZLinuxGetRandomPoolLocation(poolName, key)
end

function PZLinuxGetContractLocationPoolName(contractId)
    contractId = tonumber(contractId)
    if contractId == 2 then return "packages" end
    if contractId == 3 then return "manhunt" end
    if contractId == 7 then return "cargo" end
    if contractId == 8 then return "protect" end
    return nil
end

function PZLinuxGetRandomContractCityId(contractId)
    local poolName = PZLinuxGetContractLocationPoolName(contractId)
    local availableCityIds = poolName and PZLinuxGetMissionLocationCityIds(poolName) or {}
    if #availableCityIds > 0 then
        return availableCityIds[ZombRand(#availableCityIds) + 1]
    end
    return ZombRand(1, #(PZLinux.MissionLocations.cities or {}) + 1)
end

function PZLinuxApplyLocationRewardModifier(reward, z)
    reward = tonumber(reward) or 0
    local zLevel = math.abs(tonumber(z) or 0)
    if zLevel <= 0 then return reward end

    return reward * (1 + zLevel * 0.05)
end

PZLinuxMissionLocations = PZLinuxMissionLocations or {
    mails = {
        ammo = PZLinux.MissionLocations.pools.mailDrops.ammo.byCityId,
        medical = PZLinux.MissionLocations.pools.mailDrops.medical.byCityId,
    },
    contracts = {
        retrievePackage = PZLinux.MissionLocations.pools.packages.byCityId,
        manhunt = PZLinux.MissionLocations.pools.manhunt.byCityId,
        cargo = PZLinux.MissionLocations.pools.cargo.byCityId,
        protect = PZLinux.MissionLocations.pools.protect.byCityId,
    },
    requests = {
        vehicles = PZLinux.MissionLocations.pools.vehicles.byCityId,
    },
}

PZLinuxRequestVehicleLocations = PZLinuxRequestVehicleLocations or PZLinuxGetMissionLocationPool("vehicles")
