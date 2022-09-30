local Public = {}

local table_shuffle = table.shuffle_table

local ScenarioTable = require 'maps.scrap_towny_ffa.table'
local Color = require 'utils.color_presets'

local colors = {}
colors[1] = {name = 'Almond', rgb = {239, 222, 205}}
colors[2] = {name = 'Antique Brass', rgb = {205, 149, 117}}
colors[3] = {name = 'Apricot', rgb = {253, 217, 181}}
colors[4] = {name = 'Aquamarine', rgb = {120, 219, 226}}
colors[5] = {name = 'Asparagus', rgb = {135, 169, 107}}
colors[6] = {name = 'Atomic Tangerine', rgb = {255, 164, 116}}
colors[7] = {name = 'Banana Mania', rgb = {250, 231, 181}}
colors[8] = {name = 'Beaver', rgb = {159, 129, 112}}
colors[9] = {name = 'Bittersweet', rgb = {253, 124, 110}}
colors[10] = {name = 'Black', rgb = {0, 0, 0}}
colors[11] = {name = 'Blizzard Blue', rgb = {172, 229, 238}}
colors[12] = {name = 'Blue', rgb = {31, 117, 254}}
colors[13] = {name = 'Blue Bell', rgb = {162, 162, 208}}
colors[14] = {name = 'Blue Gray', rgb = {102, 153, 204}}
colors[15] = {name = 'Blue Green', rgb = {13, 152, 186}}
colors[16] = {name = 'Blue Violet', rgb = {115, 102, 189}}
colors[17] = {name = 'Blush', rgb = {222, 93, 131}}
colors[18] = {name = 'Brick Red', rgb = {203, 65, 84}}
colors[19] = {name = 'Brown', rgb = {180, 103, 77}}
colors[20] = {name = 'Burnt Orange', rgb = {255, 127, 73}}
colors[21] = {name = 'Burnt Sienna', rgb = {234, 126, 93}}
colors[22] = {name = 'Cadet Blue', rgb = {176, 183, 198}}
colors[23] = {name = 'Canary', rgb = {255, 255, 153}}
colors[24] = {name = 'Caribbean Green', rgb = {28, 211, 162}}
colors[25] = {name = 'Carnation Pink', rgb = {255, 170, 204}}
colors[26] = {name = 'Cerise', rgb = {221, 68, 146}}
colors[27] = {name = 'Cerulean', rgb = {29, 172, 214}}
colors[28] = {name = 'Chestnut', rgb = {188, 93, 88}}
colors[29] = {name = 'Copper', rgb = {221, 148, 117}}
colors[30] = {name = 'Cornflower', rgb = {154, 206, 235}}
colors[31] = {name = 'Cotton Candy', rgb = {255, 188, 217}}
colors[32] = {name = 'Dandelion', rgb = {253, 219, 109}}
colors[33] = {name = 'Denim', rgb = {43, 108, 196}}
colors[34] = {name = 'Desert Sand', rgb = {239, 205, 184}}
colors[35] = {name = 'Eggplant', rgb = {110, 81, 96}}
colors[36] = {name = 'Electric Lime', rgb = {206, 255, 29}}
colors[37] = {name = 'Fern', rgb = {113, 188, 120}}
colors[38] = {name = 'Forest Green', rgb = {109, 174, 129}}
colors[39] = {name = 'Fuchsia', rgb = {195, 100, 197}}
colors[40] = {name = 'Fuzzy Wuzzy', rgb = {204, 102, 102}}
colors[41] = {name = 'Gold', rgb = {231, 198, 151}}
colors[42] = {name = 'Goldenrod', rgb = {252, 217, 117}}
colors[43] = {name = 'Granny Smith Apple', rgb = {168, 228, 160}}
colors[44] = {name = 'Gray', rgb = {149, 145, 140}}
colors[45] = {name = 'Green', rgb = {28, 172, 120}}
colors[46] = {name = 'Green Blue', rgb = {17, 100, 180}}
colors[47] = {name = 'Green Yellow', rgb = {240, 232, 145}}
colors[48] = {name = 'Hot Magenta', rgb = {255, 29, 206}}
colors[49] = {name = 'Inchworm', rgb = {178, 236, 93}}
colors[50] = {name = 'Indigo', rgb = {93, 118, 203}}
colors[51] = {name = 'Jazzberry Jam', rgb = {202, 55, 103}}
colors[52] = {name = 'Jungle Green', rgb = {59, 176, 143}}
colors[53] = {name = 'Laser Lemon', rgb = {254, 254, 34}}
colors[54] = {name = 'Lavender', rgb = {252, 180, 213}}
colors[55] = {name = 'Lemon Yellow', rgb = {255, 244, 79}}
colors[56] = {name = 'Macaroni and Cheese', rgb = {255, 189, 136}}
colors[57] = {name = 'Magenta', rgb = {246, 100, 175}}
colors[58] = {name = 'Magic Mint', rgb = {170, 240, 209}}
colors[59] = {name = 'Mahogany', rgb = {205, 74, 76}}
colors[60] = {name = 'Maize', rgb = {237, 209, 156}}
colors[61] = {name = 'Manatee', rgb = {151, 154, 170}}
colors[62] = {name = 'Mango Tango', rgb = {255, 130, 67}}
colors[63] = {name = 'Maroon', rgb = {200, 56, 90}}
colors[64] = {name = 'Mauvelous', rgb = {239, 152, 170}}
colors[65] = {name = 'Melon', rgb = {253, 188, 180}}
colors[66] = {name = 'Midnight Blue', rgb = {26, 72, 118}}
colors[67] = {name = 'Mountain Meadow', rgb = {48, 186, 143}}
colors[68] = {name = 'Mulberry', rgb = {197, 75, 140}}
colors[69] = {name = 'Navy Blue', rgb = {25, 116, 210}}
colors[70] = {name = 'Neon Carrot', rgb = {255, 163, 67}}
colors[71] = {name = 'Olive Green', rgb = {186, 184, 108}}
colors[72] = {name = 'Orange', rgb = {255, 117, 56}}
colors[73] = {name = 'Orange Red', rgb = {255, 43, 43}}
colors[74] = {name = 'Orange Yellow', rgb = {248, 213, 104}}
colors[75] = {name = 'Orchid', rgb = {230, 168, 215}}
colors[76] = {name = 'Outer Space', rgb = {65, 74, 76}}
colors[77] = {name = 'Outrageous Orange', rgb = {255, 110, 74}}
colors[78] = {name = 'Pacific Blue', rgb = {28, 169, 201}}
colors[79] = {name = 'Peach', rgb = {255, 207, 171}}
colors[80] = {name = 'Periwinkle', rgb = {197, 208, 230}}
colors[81] = {name = 'Piggy Pink', rgb = {253, 221, 230}}
colors[82] = {name = 'Pine Green', rgb = {21, 128, 120}}
colors[83] = {name = 'Pink Flamingo', rgb = {252, 116, 253}}
colors[84] = {name = 'Pink Sherbert', rgb = {247, 143, 167}}
colors[85] = {name = 'Plum', rgb = {142, 69, 133}}
colors[86] = {name = 'Purple Heart', rgb = {116, 66, 200}}
colors[87] = {name = "Purple Mountain's Majesty", rgb = {157, 129, 186}}
colors[88] = {name = 'Purple Pizzazz', rgb = {254, 78, 218}}
colors[89] = {name = 'Radical Red', rgb = {255, 73, 108}}
colors[90] = {name = 'Raw Sienna', rgb = {214, 138, 89}}
colors[91] = {name = 'Raw Umber', rgb = {113, 75, 35}}
colors[92] = {name = 'Razzle Dazzle Rose', rgb = {255, 72, 208}}
colors[93] = {name = 'Razzmatazz', rgb = {227, 37, 107}}
colors[94] = {name = 'Red', rgb = {238, 32, 77}}
colors[95] = {name = 'Red Orange', rgb = {255, 83, 73}}
colors[96] = {name = 'Red Violet', rgb = {192, 68, 143}}
colors[97] = {name = "Robin's Egg Blue", rgb = {31, 206, 203}}
colors[98] = {name = 'Royal Purple', rgb = {120, 81, 169}}
colors[99] = {name = 'Salmon', rgb = {255, 155, 170}}
colors[100] = {name = 'Scarlet', rgb = {252, 40, 71}}
colors[101] = {name = "Screamin' Green", rgb = {118, 255, 122}}
colors[102] = {name = 'Sea Green', rgb = {159, 226, 191}}
colors[103] = {name = 'Sepia', rgb = {165, 105, 79}}
colors[104] = {name = 'Shadow', rgb = {138, 121, 93}}
colors[105] = {name = 'Shamrock', rgb = {69, 206, 162}}
colors[106] = {name = 'Shocking Pink', rgb = {251, 126, 253}}
colors[107] = {name = 'Silver', rgb = {205, 197, 194}}
colors[108] = {name = 'Sky Blue', rgb = {128, 218, 235}}
colors[109] = {name = 'Spring Green', rgb = {236, 234, 190}}
colors[110] = {name = 'Sunglow', rgb = {255, 207, 72}}
colors[111] = {name = 'Sunset Orange', rgb = {253, 94, 83}}
colors[112] = {name = 'Tan', rgb = {250, 167, 108}}
colors[113] = {name = 'Teal Blue', rgb = {24, 167, 181}}
colors[114] = {name = 'Thistle', rgb = {235, 199, 223}}
colors[115] = {name = 'Tickle Me Pink', rgb = {252, 137, 172}}
colors[116] = {name = 'Timberwolf', rgb = {219, 215, 210}}
colors[117] = {name = 'Tropical Rain Forest', rgb = {23, 128, 109}}
colors[118] = {name = 'Tumbleweed', rgb = {222, 170, 136}}
colors[119] = {name = 'Turquoise Blue', rgb = {119, 221, 231}}
colors[120] = {name = 'Unmellow Yellow', rgb = {255, 255, 102}}
colors[121] = {name = 'Violet (Purple)', rgb = {146, 110, 174}}
colors[122] = {name = 'Violet Blue', rgb = {50, 74, 178}}
colors[123] = {name = 'Violet Red', rgb = {247, 83, 148}}
colors[124] = {name = 'Vivid Tangerine', rgb = {255, 160, 137}}
colors[125] = {name = 'Vivid Violet', rgb = {143, 80, 157}}
colors[126] = {name = 'White', rgb = {255, 255, 255}}
colors[127] = {name = 'Wild Blue Yonder', rgb = {162, 173, 208}}
colors[128] = {name = 'Wild Strawberry', rgb = {255, 67, 164}}
colors[129] = {name = 'Wild Watermelon', rgb = {252, 108, 133}}
colors[130] = {name = 'Wisteria', rgb = {205, 164, 222}}
colors[131] = {name = 'Yellow', rgb = {252, 232, 131}}
colors[132] = {name = 'Yellow Green', rgb = {197, 227, 132}}
colors[133] = {name = 'Yellow Orange', rgb = {255, 174, 66}}

local function is_color_used(color, town_centers)
    for _, center in pairs(town_centers) do
        if center.color then
            if center.color.r == color.r and center.color.g == color.g and center.color.b == color.b then
                return true
            end
        end
    end
end

function Public.get_random_color()
    local this = ScenarioTable.get_table()
    local town_centers = this.town_centers
    local rgb
    local color = {}
    local name
    local shuffle_index = {}
    for i = 1, #colors, 1 do
        shuffle_index[i] = i
    end
    table_shuffle(shuffle_index)
    for i = 1, #colors, 1 do
        rgb = colors[shuffle_index[i]].rgb
        name = colors[shuffle_index[i]].name
        local red = rgb[1] / 255
        local green = rgb[2] / 255
        local blue = rgb[3] / 255
        color.r = red
        color.g = green
        color.b = blue
        if not is_color_used(color, town_centers) then
            --log("color = " .. name)
            return {name = name, color = color}
        end
    end
end

local function random_color(cmd)
    local player = game.players[cmd.player_index]
    if not player or not player.valid then
        return
    end
    local force = player.force
    if force.name == 'player' or force.name == 'rogue' then
        player.print('You are not member of a town!', Color.fail)
        return
    end
    local this = ScenarioTable.get_table()
    local town_center = this.town_centers[force.name]

    local crayon = Public.get_random_color()

    town_center.color = crayon.color
    rendering.set_color(town_center.town_caption, town_center.color)
    for _, p in pairs(force.players) do
        if p.index == player.index then
            player.print('Your town color is now ' .. crayon.name, crayon.color)
        else
            player.print(player.name .. ' has set the town color to ' .. crayon.name, crayon.color)
        end
        p.color = crayon.color
        p.chat_color = crayon.color
    end
end

commands.add_command(
    'random-color',
    'Randomly color your town..',
    function(cmd)
        random_color(cmd)
    end
)

return Public
