local function get_banner_text()
    local addr = pso.read_u32(0x00a46c78)
    
    if addr ~= 0 then
        local text = pso.read_wstr(addr + 0x1c, 0x0400)
        return text
    end
    
    return ""
end

local function clean_pso_text(text)
    return string.gsub(text, string.char(9) .. "C%d", "")
end

local function parse_hbr_banner(banner_text)
    local parsed = {
        total = 0,
        dar_boost = 0,
        rank = "NO RANK",
        quests = {}
    }
    
    banner_text = clean_pso_text(banner_text)
    local banner_end_part = string.match(banner_text, "(Total Points.+)$")
    local banner_mid_part = string.sub(banner_text, 35, -(#banner_end_part + 1 + 3))
    
    for split in string.gmatch(banner_mid_part, "[^,]+") do
        local quest = string.match(split, "^  (.+):")
        local score = tonumber(string.match(split, "(%d+)$") or "0")
        local entry = {
            quest = quest,
            score = score
        }
        table.insert(parsed.quests, entry)
    end
    
    parsed.total = string.match(banner_end_part, "%d+")
    parsed.dar_boost = string.match(banner_end_part, "%d+ %(%+(%d+)")
    parsed.rank = string.match(banner_end_part, "Ranking: (..?)")
    
    return parsed
end

local hbr = nil
local counter = 0
local update_interval = 30 * 5

local function present()
    counter = counter + 1
    
    imgui.Begin("HBR score")
    
    if counter % update_interval == 0 then
        local banner = get_banner_text()
        if string.find(banner, "Hunters Boost Completion") then
            hbr = parse_hbr_banner(banner)
        end
        counter = 0
    end
    
    if hbr ~= nil then
        for k, v in pairs(hbr.quests) do
            imgui.Text(v.quest .. ": " .. v.score)
        end
        imgui.Text("Total: " .. hbr.total .. " (+" .. hbr.dar_boost .. " DAR)")
        imgui.Text("Rank: " .. hbr.rank)
    end
    
    imgui.End()
end

local function init()
    return
    {
        name = "hbrscoreviewer",
        version = "0.0.1",
        author = "esc",
        description = "Displays your HBR score. Type /hbr to update it.",
        present = present
    }
end

return
{
    __addon =
    {
        init = init
    }
}