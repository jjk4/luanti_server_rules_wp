local S = minetest.get_translator("server_rules_wp")
local http = minetest.request_http_api()

-- Unterstützt den neuen sowie alten Einstellungsnamen als Fallback
local rules_url = minetest.settings:get("server_rules_wp_url") or minetest.settings:get("server_rules_url")
local cached_rules = S("Rules are currently loading or unavailable.")

local function clean_html(html)
    local text = html
    
    -- 1. Versteckte WordPress-Zeilenumbrüche entfernen
    text = text:gsub("\r", ""):gsub("\n", "")
    
    -- 2. Vor dem Löschen der Tags echte Zeilenumbrüche für Block-Elemente erzwingen
    text = text:gsub("</p>", "\n\n")
    text = text:gsub("<br%s*/?>", "\n")
    text = text:gsub("</h1>", "</h1>\n\n")
    text = text:gsub("</h2>", "</h2>\n\n")
    text = text:gsub("</h3>", "</h3>\n\n")
    text = text:gsub("</h4>", "</h4>\n\n")
    
    -- 3. Listen für Luanti lesbar machen
    text = text:gsub("<ul>", "\n")
    text = text:gsub("</ul>", "\n")
    text = text:gsub("<ol>", "\n")
    text = text:gsub("</ol>", "\n")
    text = text:gsub("<li[^>]*>", "• ")
    text = text:gsub("</li>", "\n")

    -- 4. Nur diese definierten HTML-Tags erlauben wir
    local allowed = {
        ["h1"] = "h1", ["/h1"] = "/h1",
        ["h2"] = "h2", ["/h2"] = "/h2",
        ["h3"] = "h3", ["/h3"] = "/h3",
        ["h4"] = "h4", ["/h4"] = "/h4",
        ["b"] = "b", ["/b"] = "/b",
        ["strong"] = "b", ["/strong"] = "/b",
        ["i"] = "i", ["/i"] = "/i",
        ["em"] = "i", ["/em"] = "/i",
    }
    
    -- Wir verwandeln erlaubte Tags temporär in {tag}. 
    -- Ungültige Tags werden zu einem LEERZEICHEN (damit Wörter wie "Gültigkeit" und "Die" nicht verkleben!)
    text = text:gsub("<(/?)([%w]+)[^>]*>", function(slash, tag)
        tag = tag:lower()
        local key = slash .. tag
        if allowed[key] then
            return "{" .. key .. "}"
        end
        return " " 
    end)
    
    -- 5. Sonderzeichen reparieren
    text = text:gsub("&#8222;", "„")
    text = text:gsub("&#8220;", "“")
    text = text:gsub("&#8221;", "”")
    text = text:gsub("&#8216;", "‘")
    text = text:gsub("&#8217;", "’")
    text = text:gsub("&#8211;", "–")
    text = text:gsub("&#8212;", "—")
    text = text:gsub("&#8230;", "...")
    text = text:gsub("&#39;", "'")
    text = text:gsub("&quot;", '"')
    text = text:gsub("&nbsp;", " ")
    text = text:gsub("&amp;", "&")
    -- Restliche unlesbare HTML-Code-Zahlen (wie &#123;) sicher entfernen
    text = text:gsub("&#%d+;", "")

    -- 6. Die temporären {tags} wieder zu echten <tags> für das Luanti Hypertext-Feld machen.
    -- (Hier lag der Fehler: Der Slash wird jetzt sauber mitkopiert)
    text = text:gsub("{(/?[%w]+)}", function(tag)
        return "<" .. tag .. ">"
    end)
    
    -- 7. Aufräumen von zu vielen Leerzeichen und leeren Zeilen
    text = text:gsub(" +", " ")
    text = text:gsub(" \n", "\n")
    text = text:gsub("\n ", "\n")
    text = text:gsub("\n\n\n+", "\n\n")
    text = text:match("^%s*(.-)%s*$")
    
    return text or S("Error formatting rules.")
end

local function fetch_rules()
    if not rules_url or rules_url == "" then
        minetest.log("error", "[server_rules_wp] No URL configured! Set server_rules_wp_url in minetest.conf")
        cached_rules = S("Error: No URL configured. Please contact admin.")
        return
    end

    if not http then
        minetest.log("error", "[server_rules_wp] HTTP API missing! Add 'secure.http_mods = server_rules_wp' to minetest.conf.")
        cached_rules = S("Error: Mod lacks internet permission. Please contact admin.")
        return
    end

    http.fetch({
        url = rules_url,
        timeout = 10 
    }, function(res)
        if res.succeeded then
            local data = minetest.parse_json(res.data)
            
            if data and data.content and data.content.rendered then
                cached_rules = clean_html(data.content.rendered)
                minetest.log("action", "[server_rules_wp] Rules successfully loaded from WordPress!")
            else
                minetest.log("warning", "[server_rules_wp] JSON parsed, but format is incorrect or page does not exist.")
            end
        else
            minetest.log("error", "[server_rules_wp] Could not reach WordPress. Error code: " .. tostring(res.code))
        end
    end)
end

fetch_rules()

minetest.register_chatcommand("refresh_rules", {
    description = S("Reloads rules from the WordPress page (Admins only)"),
    privs = {server = true},
    func = function(name, param)
        fetch_rules()
        return true, S("Rules are being reloaded in the background...")
    end,
})

minetest.register_chatcommand("rules", {
    description = S("Shows the server rules in a window"),
    func = function(name, param)
        local safe_text = minetest.formspec_escape(cached_rules)
        

        local style_header = "<global color=\"#E0E0E0\" size=16 valign=top>" ..
            "<tag name=\"h1\" color=\"#FFFFFF\" size=28 font=\"bold\">" ..
            "<tag name=\"h2\" color=\"#FFD700\" size=24 font=\"bold\">" ..
            "<tag name=\"h3\" color=\"#FFD700\" size=20 font=\"bold\">" ..
            "<tag name=\"h4\" color=\"#FFCC00\" size=18 font=\"bold\">" ..
            "<tag name=\"b\" color=\"#FFFFFF\" font=\"bold\">" ..
            "<tag name=\"i\" font=\"italic\">"
            
        local full_hypertext = style_header .. safe_text
        


        local formspec = "size[12,9]" ..
            "label[0.2,0.2;" .. minetest.formspec_escape(S("Rules")) .. "]" ..
            "box[0.2,0.6;11.6,0.05;#888888]" ..
            "hypertext[0.2,0.8;11.6,7.5;rules_text;" .. full_hypertext .. "]" ..
            "button_exit[5,8.4;2,0.6;close;" .. minetest.formspec_escape(S("Close")) .. "]"
        
        minetest.show_formspec(name, "server_rules_wp:rules_form", formspec)
        return true, S("Rules are being displayed.")
    end,
})
