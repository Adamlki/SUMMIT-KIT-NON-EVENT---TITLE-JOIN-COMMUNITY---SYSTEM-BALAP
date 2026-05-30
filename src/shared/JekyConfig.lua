local JekyConfig = {}

-- ============================================================
-- ROLE CONFIG
-- ============================================================
JekyConfig.RoleRules = {
    Owner     = { UserIds = {}, Usernames = { "adamzz3372" } },
    Developer = { UserIds = {}, Usernames = { "" } },
    HeadAdmin = { UserIds = {}, Usernames = { "" } },
    Admin     = { UserIds = {}, Usernames = { "" } },
    Moderator = { UserIds = {}, Usernames = { "" } },
    Streamer  = { UserIds = {}, Usernames = { "" } },
    Community = { UserIds = {}, Usernames = { "" } },
}
JekyConfig.RoleOrder = { "Owner","Developer","HeadAdmin","Admin","Moderator","Streamer","Community" }
JekyConfig.RoleDisplay = {
    Owner="👑OWNER", Developer="DEVELOPER", HeadAdmin="HEAD ADMIN",
    Admin="ADMIN", Moderator="MODERATOR", Streamer="STREAMER", Community="COMMUNITY",
}
JekyConfig.RoleColors = {
    Owner=Color3.fromRGB(255,215,0), Developer=Color3.fromRGB(0,255,255),
    HeadAdmin=Color3.fromRGB(148,0,211), Admin=Color3.fromRGB(255,69,0),
    Moderator=Color3.fromRGB(50,205,50), Streamer=Color3.fromRGB(255,0,0),
    Community=Color3.fromRGB(255,182,193),
}
JekyConfig.RoleUsesGradient = { Owner=true, Community=true }

JekyConfig.AdminRoles = {
    Owner = true,
    Developer = true,
    HeadAdmin = true,
    Admin = true,
}

-- ============================================================
-- SUMMIT CONFIG
-- ============================================================
JekyConfig.SummitLevels = {
    {Min=-1,Title="OVERLOADED"},{Min=0,Title="NEWBIE EXPLORER"},{Min=1,Title="BRAVE GUARDIAN"},
    {Min=20,Title="SWIFT WANDERER"},{Min=40,Title="NOBLE TRAVELER"},{Min=60,Title="FIERCE WARRIOR"},
    {Min=80,Title="MIGHTY CAPTAIN"},{Min=100,Title="GRAND CONQUEROR"},{Min=120,Title="DEEP DIVER"},
    {Min=140,Title="SKY SOARER"},{Min=160,Title="SUPREME RULER"},{Min=180,Title="LOYAL PROTECTOR"},
    {Min=200,Title="BRAVE DEFENDER"},{Min=220,Title="PROUD SUPPORTER"},{Min=240,Title="TRUE ENTHUSIAST"},
    {Min=260,Title="ELITE GUARD"},{Min=280,Title="GRAND ENTERTAINER"},{Min=300,Title="MELODIC SINGER"},
    {Min=320,Title="SKILLED PLAYER"},{Min=340,Title="GRACEFUL DANCER"},{Min=360,Title="CREATIVE ARTIST"},
    {Min=380,Title="WISE WRITER"},{Min=400,Title="AVID READER"},{Min=420,Title="MASTER TEACHER"},
    {Min=440,Title="EAGER STUDENT"},{Min=460,Title="BRILLIANT CREATOR"},{Min=480,Title="EXPERT DESIGNER"},
    {Min=500,Title="GRAND BUILDER"},{Min=520,Title="NEAT ORGANIZER"},{Min=540,Title="WISE MANAGER"},
    {Min=560,Title="THOROUGH TESTER"},{Min=580,Title="PATIENT WATCHER"},{Min=600,Title="WARM GREETER"},
    {Min=620,Title="GRATEFUL RECEIVER"},{Min=640,Title="GENEROUS PROVIDER"},{Min=660,Title="SMART BUYER"},
    {Min=680,Title="SKILLED SELLER"},{Min=700,Title="STRONG CARRIER"},{Min=720,Title="EXPERT RIDER"},
    {Min=740,Title="CALM PASSENGER"},{Min=760,Title="CAREFUL DRIVER"},{Min=780,Title="HELPFUL GUIDE"},
    {Min=800,Title="WISE MENTOR"},{Min=820,Title="PRECISE FILLER"},{Min=840,Title="DYNAMIC CHANGER"},
    {Min=860,Title="STEADY INCREMENTER"},{Min=880,Title="SMART REDUCER"},{Min=900,Title="POWER MULTIPLIER"},
    {Min=920,Title="FAIR DIVIDER"},{Min=940,Title="ACCURATE COUNTER"},{Min=960,Title="EXACT MEASURER"},
    {Min=980,Title="BALANCED WEIGHER"},{Min=1000,Title="MASTER MIXER"},{Min=1020,Title="CLEAN FILTER"},
    {Min=1040,Title="PERFECT SIFTER"},{Min=1060,Title="SHARP GRINDER"},{Min=1080,Title="FINE CARVER"},
    {Min=1100,Title="DEEP DRILLER"},{Min=1120,Title="SMOOTH SANDER"},{Min=1140,Title="ELEGANT DECORATOR"},
    {Min=1160,Title="VIBRANT PAINTER"},{Min=1180,Title="BRIGHT POLISHER"},{Min=1200,Title="GLEAMING SHINER"},
    {Min=1220,Title="GLOSSY WAXER"},{Min=1240,Title="CLEAN ERASER"},{Min=1260,Title="STRAIGHT RULER"},
    {Min=1280,Title="STRONG LIFTER"},{Min=1300,Title="WIDE SPREADER"},{Min=1320,Title="HIGH RAISER"},
    {Min=1340,Title="LOW LOWERER"},{Min=1360,Title="TIGHT ROLLER"},{Min=1380,Title="FAR REACHER"},
    {Min=1400,Title="FIRM GRASPER"},{Min=1420,Title="WILD SHAKER"},{Min=1440,Title="RAPID VIBRATOR"},
    {Min=1460,Title="LOUD ECHOER"},{Min=1480,Title="HEAVY THUNDERER"},{Min=1500,Title="GREAT ROARER"},
    {Min=1520,Title="DEEP DIGGER"},{Min=1540,Title="QUICK REPLACER"},{Min=1560,Title="MEGA DOUBLER"},
    {Min=1580,Title="STRONG CLASPER"},{Min=1600,Title="FAST MOVER"},{Min=1620,Title="SWIFT RAIDER"},
    {Min=1640,Title="SMOOTH SLIDER"},{Min=1660,Title="HEAVY CRUSHER"},{Min=1680,Title="STEADY HERDER"},
    {Min=1700,Title="SWEET TEMPTER"},{Min=1720,Title="SHARP SCRATCHER"},{Min=1740,Title="ACTIVE USER"},
    {Min=1760,Title="BOLD SHAVER"},{Min=1780,Title="PRECISE CUTTER"},{Min=1800,Title="FIRM EVICTORER"},
    {Min=1820,Title="GREAT MEMORIZER"},{Min=1840,Title="WISE PUNISHER"},{Min=1860,Title="FAIR JUDGE"},
    {Min=1880,Title="JUST LEGALIZER"},{Min=1900,Title="STRONG BLOCKER"},{Min=1920,Title="FIERCE REPELLER"},
    {Min=1940,Title="MEGA DESTROYER"},{Min=1960,Title="GRAND ENTERTAINER"},{Min=1980,Title="LIFE GIVER"},
    {Min=2000,Title="TOTAL ELIMINATOR"},
}

JekyConfig.SummitColors = {
    ["OVERLOADED"]=Color3.fromRGB(138,43,226),["NEWBIE EXPLORER"]=Color3.fromRGB(135,206,250),
    ["BRAVE GUARDIAN"]=Color3.fromRGB(100,150,255),["SWIFT WANDERER"]=Color3.fromRGB(120,220,100),
    ["NOBLE TRAVELER"]=Color3.fromRGB(255,180,80),["FIERCE WARRIOR"]=Color3.fromRGB(220,100,100),
    ["MIGHTY CAPTAIN"]=Color3.fromRGB(100,200,220),["GRAND CONQUEROR"]=Color3.fromRGB(255,100,100),
    ["DEEP DIVER"]=Color3.fromRGB(80,160,255),["SKY SOARER"]=Color3.fromRGB(180,220,255),
    ["SUPREME RULER"]=Color3.fromRGB(255,150,50),["LOYAL PROTECTOR"]=Color3.fromRGB(150,255,150),
    ["BRAVE DEFENDER"]=Color3.fromRGB(255,200,100),["PROUD SUPPORTER"]=Color3.fromRGB(220,180,255),
    ["TRUE ENTHUSIAST"]=Color3.fromRGB(255,220,120),["ELITE GUARD"]=Color3.fromRGB(100,255,200),
    ["GRAND ENTERTAINER"]=Color3.fromRGB(255,120,200),["MELODIC SINGER"]=Color3.fromRGB(200,100,255),
    ["SKILLED PLAYER"]=Color3.fromRGB(100,255,100),["GRACEFUL DANCER"]=Color3.fromRGB(255,100,180),
    ["CREATIVE ARTIST"]=Color3.fromRGB(255,180,100),["WISE WRITER"]=Color3.fromRGB(180,100,255),
    ["AVID READER"]=Color3.fromRGB(100,180,255),["MASTER TEACHER"]=Color3.fromRGB(255,100,100),
    ["EAGER STUDENT"]=Color3.fromRGB(100,255,180),["BRILLIANT CREATOR"]=Color3.fromRGB(255,180,220),
    ["EXPERT DESIGNER"]=Color3.fromRGB(180,255,100),["GRAND BUILDER"]=Color3.fromRGB(100,200,255),
    ["NEAT ORGANIZER"]=Color3.fromRGB(255,200,100),["WISE MANAGER"]=Color3.fromRGB(200,100,200),
    ["THOROUGH TESTER"]=Color3.fromRGB(100,255,220),["PATIENT WATCHER"]=Color3.fromRGB(220,100,150),
    ["WARM GREETER"]=Color3.fromRGB(150,220,100),["GRATEFUL RECEIVER"]=Color3.fromRGB(255,150,180),
    ["GENEROUS PROVIDER"]=Color3.fromRGB(180,150,255),["SMART BUYER"]=Color3.fromRGB(150,255,150),
    ["SKILLED SELLER"]=Color3.fromRGB(255,180,150),["STRONG CARRIER"]=Color3.fromRGB(150,180,255),
    ["EXPERT RIDER"]=Color3.fromRGB(255,220,150),["CALM PASSENGER"]=Color3.fromRGB(220,150,255),
    ["CAREFUL DRIVER"]=Color3.fromRGB(150,255,200),["HELPFUL GUIDE"]=Color3.fromRGB(255,150,220),
    ["WISE MENTOR"]=Color3.fromRGB(220,255,150),["PRECISE FILLER"]=Color3.fromRGB(150,200,255),
    ["DYNAMIC CHANGER"]=Color3.fromRGB(255,200,180),["STEADY INCREMENTER"]=Color3.fromRGB(180,255,180),
    ["SMART REDUCER"]=Color3.fromRGB(255,180,200),["POWER MULTIPLIER"]=Color3.fromRGB(200,180,255),
    ["FAIR DIVIDER"]=Color3.fromRGB(180,255,220),["ACCURATE COUNTER"]=Color3.fromRGB(255,220,180),
    ["EXACT MEASURER"]=Color3.fromRGB(220,180,220),["BALANCED WEIGHER"]=Color3.fromRGB(180,220,255),
    ["MASTER MIXER"]=Color3.fromRGB(255,180,180),["CLEAN FILTER"]=Color3.fromRGB(180,255,200),
    ["PERFECT SIFTER"]=Color3.fromRGB(200,200,255),["SHARP GRINDER"]=Color3.fromRGB(255,200,200),
    ["FINE CARVER"]=Color3.fromRGB(200,255,200),["DEEP DRILLER"]=Color3.fromRGB(255,220,200),
    ["SMOOTH SANDER"]=Color3.fromRGB(200,220,255),["ELEGANT DECORATOR"]=Color3.fromRGB(255,200,220),
    ["VIBRANT PAINTER"]=Color3.fromRGB(220,200,255),["BRIGHT POLISHER"]=Color3.fromRGB(200,255,220),
    ["GLEAMING SHINER"]=Color3.fromRGB(255,220,220),["GLOSSY WAXER"]=Color3.fromRGB(220,255,200),
    ["CLEAN ERASER"]=Color3.fromRGB(255,180,220),["STRAIGHT RULER"]=Color3.fromRGB(220,180,180),
    ["STRONG LIFTER"]=Color3.fromRGB(180,220,180),["WIDE SPREADER"]=Color3.fromRGB(220,220,180),
    ["HIGH RAISER"]=Color3.fromRGB(180,180,220),["LOW LOWERER"]=Color3.fromRGB(220,180,220),
    ["TIGHT ROLLER"]=Color3.fromRGB(180,220,220),["FAR REACHER"]=Color3.fromRGB(220,220,220),
    ["FIRM GRASPER"]=Color3.fromRGB(210,190,170),["WILD SHAKER"]=Color3.fromRGB(190,210,170),
    ["RAPID VIBRATOR"]=Color3.fromRGB(170,190,210),["LOUD ECHOER"]=Color3.fromRGB(210,170,190),
    ["HEAVY THUNDERER"]=Color3.fromRGB(190,170,210),["GREAT ROARER"]=Color3.fromRGB(170,210,190),
    ["DEEP DIGGER"]=Color3.fromRGB(210,190,210),["QUICK REPLACER"]=Color3.fromRGB(190,210,210),
    ["MEGA DOUBLER"]=Color3.fromRGB(210,210,190),["STRONG CLASPER"]=Color3.fromRGB(190,190,190),
    ["FAST MOVER"]=Color3.fromRGB(160,230,160),["SWIFT RAIDER"]=Color3.fromRGB(230,160,160),
    ["SMOOTH SLIDER"]=Color3.fromRGB(160,160,230),["HEAVY CRUSHER"]=Color3.fromRGB(230,230,160),
    ["STEADY HERDER"]=Color3.fromRGB(160,230,230),["SWEET TEMPTER"]=Color3.fromRGB(230,160,230),
    ["SHARP SCRATCHER"]=Color3.fromRGB(200,160,160),["ACTIVE USER"]=Color3.fromRGB(160,200,160),
    ["BOLD SHAVER"]=Color3.fromRGB(160,160,200),["PRECISE CUTTER"]=Color3.fromRGB(200,200,160),
    ["FIRM EVICTORER"]=Color3.fromRGB(160,200,200),["GREAT MEMORIZER"]=Color3.fromRGB(200,160,200),
    ["WISE PUNISHER"]=Color3.fromRGB(180,140,140),["FAIR JUDGE"]=Color3.fromRGB(140,180,140),
    ["JUST LEGALIZER"]=Color3.fromRGB(140,140,180),["STRONG BLOCKER"]=Color3.fromRGB(180,180,140),
    ["FIERCE REPELLER"]=Color3.fromRGB(140,180,180),["MEGA DESTROYER"]=Color3.fromRGB(180,140,180),
    ["LIFE GIVER"]=Color3.fromRGB(120,220,120),["TOTAL ELIMINATOR"]=Color3.fromRGB(120,120,220),
}

JekyConfig.MinusGradient = { Colors={Color3.fromRGB(138,43,226),Color3.fromRGB(75,0,130),Color3.fromRGB(25,25,112)}, Speed=0.02, RotationSpeed=3 }
JekyConfig.Gradient1K    = { Colors={Color3.fromRGB(0,100,255),Color3.fromRGB(255,255,0),Color3.fromRGB(255,0,0)}, Speed=0.02, RotationSpeed=3 }
JekyConfig.Gradient2K    = { Colors={Color3.fromRGB(255,0,255),Color3.fromRGB(0,255,255),Color3.fromRGB(255,255,0)}, Speed=0.02, RotationSpeed=3 }
JekyConfig.Gradient3K    = { Colors={Color3.fromRGB(255,0,0),Color3.fromRGB(255,127,0),Color3.fromRGB(255,255,0)}, Speed=0.02, RotationSpeed=3 }
JekyConfig.Gradient5K    = { Colors={Color3.fromRGB(148,0,211),Color3.fromRGB(75,0,130),Color3.fromRGB(0,0,255),Color3.fromRGB(0,255,0),Color3.fromRGB(255,255,0),Color3.fromRGB(255,127,0),Color3.fromRGB(255,0,0)}, Speed=0.02, RotationSpeed=4 }

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================
local function contains(t, v)
    for _, x in ipairs(t or {}) do if x == v then return true end end
    return false
end

function JekyConfig.IsAdmin(userId, username)
    for roleName, _ in pairs(JekyConfig.AdminRoles) do
        local rule = JekyConfig.RoleRules[roleName]
        if rule then
            if userId and contains(rule.UserIds, userId) then return true end
            if username and contains(rule.Usernames, username) then return true end
        end
    end
    return false
end

return JekyConfig
