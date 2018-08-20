local hbr_rank = { 0, 12, 18, 24, 30, 36, 42, 48, 54, 60, 72, 96, 132, 156, 180, 204, 228, 252, 276, 300 }

local function next_rank(total)
    local total_hbr = tonumber(total)

    for i = 1,#hbr_rank do
        if hbr_rank[i] >= (total_hbr+1) then
            return hbr_rank[i]
        end
    end

    return 1
end

local function get_banner_text()
    local addr = pso.read_u32(0x00a46c78)

    if addr ~= 0 then
    local text = pso.read_wstr(addr + 0x1c, 0x0200)
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
        quests = {},
        next = 0,
        tnr = 0
    }

    banner_text = clean_pso_text(banner_text)
    local banner_end_part = string.match(banner_text, "(Total Points.+)$")
    local banner_mid_part = string.sub(banner_text, 14, -(#banner_end_part + 1 + 3))
  
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
    parsed.rank = string.match(banner_end_part, "Ranking: (..?)") or "?"
    parsed.next = next_rank(parsed.total)
    parsed.tnr = parsed.next - parsed.total

    return parsed
end

local hbr = nil
local counter = 0
local update_interval = 30 * 5

local function present()
    counter = counter + 1

    imgui.Begin("HBR+")

    if counter % update_interval == 0 then
        local banner = get_banner_text()
        if string.find(banner, "HBR Counts") then
            hbr = parse_hbr_banner(banner)
        end
        counter = 0
    end

    if hbr ~= nil then
        local finished = tonumber(hbr.total) >= hbr_rank[#hbr_rank - 1]
        for k, v in pairs(hbr.quests) do
            if finished then
                imgui.TextColored(0.5, 0.5, 0.5, 1, v.score .. " | " .. v.quest)
            else
                local diff = v.score - hbr.next
                if diff >= 0 then imgui.TextColored(0, 255, 0, 1, v.score .. " (+" .. diff .. ") " .. v.quest)
                else imgui.TextColored(255, 0, 0, 1, v.score .. " (" .. diff .. ") " .. v.quest) end
            end
        end

        local dar_boost = tonumber(hbr.dar_boost)
        local rdr_boost = dar_boost - 25
        if dar_boost > 25 then
            imgui.Text("Total: " .. hbr.total .. " (+25 DAR / +" .. rdr_boost .. " RDR)")
        else
            imgui.Text("Total: " .. hbr.total .. " (+" .. dar_boost .. " DAR)")
        end
        if hbr.tnr > 0 then
            imgui.Text("Rank: " .. hbr.rank .. " | Next: " .. hbr.next .. " (-" .. hbr.tnr .. ")")
        end
    end

    imgui.End()
end

local function init()
    return
    {
        name = "HBR+",
        version = "0.0.2",
        author = "esc & zeta",
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
