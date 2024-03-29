local AddOnName, AddOn
local Date, DateFormat, Util, df

function check_df(fmt,str,no_check)
    local df = DateFormat(fmt)
    local d = df:parse(str)
    if not no_check then
        assert(df:tostring(d) == str)
    end
end

function parse_date(s)
    return df:parse(s)
end

function parse_utc(s)
    local d = parse_date(s)
    return d:toUTC()
end

describe("Date", function()
    setup(function()
        AddOnName, AddOn = loadfile("Test/TestSetup.lua")(true, 'Models_Date')
        local p = AddOn.Package('Models')
        Date, DateFormat = p.Date, p.DateFormat
        Util = AddOn:GetLibrary('Util')
        df = DateFormat()
    end)
    
    teardown(function()
        After()
    end)
    
    describe("creation", function()
        it("from no args", function()
            local d = Date()
            assert(d)
            --print(tostring(d))
        end)
        it("from utc", function()
            local d = Date('utc')
            assert(d)
            --print(tostring(d))
        end)
        it("from other date", function()
            local d1 = Date()
            local d2 = Date()
            assert(d1 == d2)
        end)
    end)
    describe("misc", function()
        it("dow", function()
            local d = Date(2022, 12, 14, 00, 00, 00)
            assert(d:weekday_name(true) == "Wednesday")
            assert(d:weekday_name() == "Wed")
            assert(d:wday() == 4)
        end)
        it("scratch", function()
            local d, w = Date(2022, 12, 14, 00, 00, 00), 5
            -- find previous tuesday
            while(d:wday() ~= 3) do
                d:add{day = -1}
            end

            assert(d:month() == 12)
            assert(d:day() == 13)
            assert(d:year() == 2022)

            -- go back n weeks
            d:add{day = -(w * 7)}
            assert(d:month() == 11)
            assert(d:day() == 08)
            assert(d:year() == 2022)
        end)
    end)
    describe("comparison", function()
        it("gt", function()
            local d = Date()
            d:add{day = 1}
            assert(d > Date())
        end)
        it("lt", function()
            local d = Date()
            d:add{day = 1}
            assert(Date() < d)
        end)
    end)
    describe("intervals", function()
        it("difference in minutes", function()
            local d1 = Date(1202)
            local d2 = Date(1500)
            assert(tostring(d2:diff(d1)) == "4 min 58 sec ")
        end)
        it("difference in years", function()
            local d1 = Date(1976, 08, 19, 00, 00, 00)
            local d2 = Date(2020, 04, 02, 18, 34, 30)
            assert(tostring(d2:diff(d1)) == "43 years 7 months 14 days 18 hours 34 min 30 sec ")
        end)
    end)
    describe("conversion", function()
        it("to/from utc #travisignore", function()
            -- the conversion to locals below will fail on different TZs
            local d = Date(1976, 08, 19, 00, 00, 00)
            assert("1976-08-19T06:00:00Z" == tostring(d:toUTC()))
            assert("1976-08-19T00:00:00-06:00" == tostring(d:toLocal()))
            d = Date(1585928063)
            assert("2020-04-03T15:34:23Z" == tostring(d))
            assert("2020-04-03T15:34:23Z" == tostring(d:toUTC()))
            assert("2020-04-03T09:34:23-06:00" == tostring(d:toLocal()))
        end)
    end)
    describe("format", function()
        it("can parse dates", function()
            check_df('dd/mm/yy','02/04/10')
            check_df('mm/dd/yyyy','04/02/2010')
            check_df('yyyy-mm-dd','2011-02-20')
            check_df('yyyymmdd','20070320')
            check_df('m/d/yyyy','1/5/2001',true)
            check_df('HH:MM','23:10')
            
            local iso = DateFormat 'yyyy-mm-dd'
            local d = iso:parse '2010-04-10'
            assert(d:day() == 10)
            assert(d:month() == 4)
            assert(d:year() == 2010)
            
            local fav = DateFormat "mm/dd/yyyy HH:MM:SS"
            d = fav:parse '04/02/2020 19:05:43'
            local s = fav:tostring(d)
            local dc = fav:parse(s)
            assert(d == dc)
        end)
        it("can parse UTC dates", function()
            assert(parse_utc '2010-05-10 12:35:23Z' == Date(2010,05,10,12,35,23))
            assert(parse_utc '2008-10-03T14:30+02'==  Date(2008,10,03,12,30))
            assert(parse_utc '2008-10-03T14:00-02:00'== Date(2008,10,03,16,0))
        end)
        
        it("can parse weird dates", function()
            assert(parse_date '15:30'== Date {hour=15,min=30})
            assert(parse_date '8.05pm'== Date {hour=20,min=5})
            assert(parse_date '28/10/02'==  Date {year=2002,month=10,day=28})
            -- fail due to leading and trailing space
            --assert(parse_date ' 5 Feb 2012 '==  Date {year=2012,month=2,day=5})
            --assert(parse_date '20 Jul '==  Date {month=7,day=20})
            assert(parse_date '05/04/02 15:30:43'==  Date{year=2002,month=4,day=5,hour=15,min=30,sec=43})
            assert(parse_date 'march' ==  Date {month=3})
            assert(parse_date '2010-05-23T0130'==  Date{year=2010,month=5,day=23,hour=1,min=30})
            assert(parse_date '2008-10-03T14:30:45'==  Date{year=2008,month=10,day=3,hour=14,min=30,sec=45})
            -- fails due to comma
            --assert(parse_date '18 July, 2013 12:00:00' == Date{year=2013,month=07,day=18,hour=12,min=0,sec=0})
        end)
        
        it("can format date(s)", function()
            local fav = DateFormat "mm/dd/yyyy HH:MM:SS"
            assert(fav:format(Date()))
            assert(fav:format(time()))
            assert("10/02/2019 18:30:01" == fav:format(Date(2019, 10, 02, 18, 30, 01)))
        end)
    end)
    describe("backwards compatability", function()
        it("parses timestamp", function()
            local df = DateFormat  "mm/dd/yyyy HH:MM:SS"
            local d = df:parse("03/02/2019 20:03:30")
            assert(d:month() == 3)
            assert(d:day() == 2)
            assert(d:year() == 2019)
            assert(d:hour() == 20)
            assert(d:min() == 3)
            assert(d:sec() == 30)
        end)
        it("converts to/from UTC", function()
            local d1 = Date()
            local d2 = d1:toUTC()
            local d3 = d2:toLocal()
            assert(d1 == d3)
        end)
        it("calculates interval #travisignore", function()
            local d1 = Date(2019, 10, 02, 18, 30, 01)
            local d2 = Date(2022, 02, 04, 02 ,00, 49)
            local y, m, d, hh, mi, ss = d2:diff(d1):Duration()
            assert(y == 2)
            assert(m == 4)
            assert(d == 4)
            assert(hh == 8)
            assert(mi == 30)
            assert(ss == 48)
        end)
    end)
end)