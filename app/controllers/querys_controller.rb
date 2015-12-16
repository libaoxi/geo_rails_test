class QuerysController < ApplicationController

  require 'open-uri'
  require 'nokogiri'

  include NumRu
  protect_from_forgery :except => [:adj, :monitor_data, :get_weather_air_data]

  @@alt = true


  def adj_5days
    if params[:var]
      varnames = [params[:var]]
    else
      varnames = ["CO_120", "NOX_120", "SO2_120",
       "CO_96", "NOX_96", "SO2_96" , 
       "CO_72", "NOX_72", "SO2_72" , 
       "CO_48", "NOX_48", "SO2_48" ,
       "CO_24", "NOX_24", "SO2_24" ]
    end
    #puts varnames
	path = '/mnt/share/Temp/BackupADJ/'

    if params[:city_name]
		path = '/mnt/share/Temp/BackupADJ_baoding/'
	end
    #if @@alt
    #  @@alt = false
    #  puts 'langfang'
    #  path = '/mnt/share/Temp/BackupADJ/'
    #else
    #  @@alt = true
    #  puts 'baoding'
    #  path = '/mnt/share/Temp/BackupADJ_baoding/'
    #end
    nt = Time.now
    i = 0
    begin
      #puts i
      strtime = (nt-60*60*24*i).strftime("%Y-%m-%d")
      ncfile = path + 'CUACE_09km_adj_'+strtime+'.nc'
      i = i + 1
    end until File::exists?(ncfile)

    #puts ncfile
    file = NetCDF.open(ncfile)
    @dataArr = Hash.new
    varnames.each do |var|
      data = file.var(var).get
      @dataArr[var] = data[0..-1,0..-1,0,0].to_a
    end
    #render json: @dataArr.to_json
    ret_data = Hash.new
    ret_data[:time]= strtime 
    ret_data[:data]= @dataArr 
    respond_to do |format|
      format.html { render json: ret_data}
      if params[:callback]
        format.js { render :json => ret_data.to_json, :callback => params[:callback] }
      else
        format.json { render json: ret_data}
      end
    end

  end

  def adj
    if params[:var]
      varnames = [params[:var]]
    else
      varnames = ["CO_120", "NOX_120", "SO2_120"]
    end
    #puts varnames
    path = '/mnt/share/Temp/BackupADJ/'
    #if @@alt
    #  @@alt = false
    #  puts 'langfang'
    #  path = '/mnt/share/Temp/BackupADJ/'
    #else
    #  @@alt = true
    #  puts 'baoding'
    #  path = '/mnt/share/Temp/BackupADJ_baoding/'
    #end
    nt = Time.now
    i = 0
    begin
      #puts i
      strtime = (nt-60*60*24*i).strftime("%Y-%m-%d")
      ncfile = path + 'CUACE_09km_adj_'+strtime+'.nc'
      i = i + 1
    end until File::exists?(ncfile)

    #puts ncfile
    file = NetCDF.open(ncfile)
    @dataArr = Hash.new
    varnames.each do |var|
      data = file.var(var).get
      @dataArr[var] = data[0..-1,0..-1,0,0].to_a
    end
    #render json: @dataArr.to_json
    respond_to do |format|
      format.html { render json: @dataArr}
      if params[:callback]
        format.js { render :json => @dataArr.to_json, :callback => params[:callback] }
      else
        format.json { render json: @dataArr}
      end
    end

  end

  def aqis_by_city
    pinyin = params[:city]
    h = HourlyCityForecastAirQuality.new
    chf = h.city_forecast(pinyin)
    render json: chf
  end



  def cities
    cs = City.pluck(:city_name, :city_name_pinyin)
    render json: cs
  end

  def all_cities2
    achf = []
    ac = City.where("id < 388").pluck(:city_name_pinyin)
    h = HourlyCityForecastAirQuality.new
    ac.each do |c|
      ch = h.city_forecast(c) 
      achf << ch if ch
    end

    puts achf
    render json: achf
  end

  def all_cities
    achf = []
    cs = City.where("id < 388")
    cs.each do |c|
      cf = Hash.new
      hf = []
      #hs = c.hourly_city_forecast_air_qualities.order(publish_datetime: :desc).limit(120).where("forecast_datetime > ?", Time.now)
      hs = c.hourly_city_forecast_air_qualities.order(:publish_datetime).last(120)
      return nil unless hs.first
      cf[:city_name] = c.city_name
      cf[:publish_datetime] = hs.first.publish_datetime.strftime('%Y-%m-%d_%H')
#      cf[:update_time] = Time.now.strftime('%Y-%m-%d_%H')
      hs.each do |ch|
        if ch.forecast_datetime > Time.now
      #    ch.AQI = (ch.AQI**2 *0.0004 + 0.3314*ch.AQI - 32.231 ).round if c.city_name_pinyin=='taiyuanshi'
          hf << {forecast_datetime: ch.forecast_datetime.strftime('%Y-%m-%d_%H'), 
                 AQI: ch.AQI.round, 
                 main_pol: ch.main_pol, 
                 grade: ch.grade,
                 pm2_5: ch.pm25,
                 pm10: ch.pm10,
                 SO2: ch.SO2,
                 CO: ch.CO,
                 NO2: ch.NO2,
                 O3: ch.O3,
                 VIS: ch.VIS }
        end
      end
      cf[:forecast_data] = hf
      achf << cf
    end

    render json: achf
  end


  def get_weather_air_data
    city_number = {北京:101010100, 朝阳区:101010300, 顺义:101010400, 怀柔:101010500, 通州:101010600, 昌平:101010700, 延庆:101010800, 丰台:101010900, 石景山:101011000, 大兴:101011100, 房山:101011200, 密云:101011300, 门头沟:101011400, 平谷:101011500, 八达岭:101011600, 佛爷顶:101011700, 汤河口:101011800, 密云上甸子:101011900, 斋堂:101012000, 霞云岭:101012100, 北京城区:101012200, 海淀:101010200, 天津:101030100, 宝坻:101030300, 东丽:101030400, 西青:101030500, 北辰:101030600, 蓟县:101031400, 汉沽:101030800, 静海:101030900, 津南:101031000, 塘沽:101031100, 大港:101031200, 武清:101030200, 宁河:101030700, 上海:101020100, 宝山:101020300, 嘉定:101020500, 南汇:101020600, 浦东:101021300, 青浦:101020800, 松江:101020900, 奉贤:101021000, 崇明:101021100, 徐家汇:101021200, 闵行:101020200, 金山:101020700, 石家庄:101090101, 张家口:101090301, 承德:101090402, 唐山:101090501, 秦皇岛:101091101, 沧州:101090701, 衡水:101090801, 邢台:101090901, 邯郸:101091001, 保定:101090201, 廊坊:101090601, 郑州:101180101, 新乡:101180301, 许昌:101180401, 平顶山:101180501, 信阳:101180601, 南阳:101180701, 开封:101180801, 洛阳:101180901, 商丘:101181001, 焦作:101181101, 鹤壁:101181201, 濮阳:101181301, 周口:101181401, 漯河:101181501, 驻马店:101181601, 三门峡:101181701, 济源:101181801, 安阳:101180201, 合肥:101220101, 芜湖:101220301, 淮南:101220401, 马鞍山:101220501, 安庆:101220601, 宿州:101220701, 阜阳:101220801, 亳州:101220901, 黄山:101221001, 滁州:101221101, 淮北:101221201, 铜陵:101221301, 宣城:101221401, 六安:101221501, 巢湖:101221601, 池州:101221701, 蚌埠:101220201, 杭州:101210101, 舟山:101211101, 湖州:101210201, 嘉兴:101210301, 金华:101210901, 绍兴:101210501, 台州:101210601, 温州:101210701, 丽水:101210801, 衢州:101211001, 宁波:101210401, 重庆:101040100, 合川:101040300, 南川:101040400, 江津:101040500, 万盛:101040600, 渝北:101040700, 北碚:101040800, 巴南:101040900, 长寿:101041000, 黔江:101041100, 万州天城:101041200, 万州龙宝:101041300, 涪陵:101041400, 开县:101041500, 城口:101041600, 云阳:101041700, 巫溪:101041800, 奉节:101041900, 巫山:101042000, 潼南:101042100, 垫江:101042200, 梁平:101042300, 忠县:101042400, 石柱:101042500, 大足:101042600, 荣昌:101042700, 铜梁:101042800, 璧山:101042900, 丰都:101043000, 武隆:101043100, 彭水:101043200, 綦江:101043300, 酉阳:101043400, 秀山:101043600, 沙坪坝:101043700, 永川:101040200, 福州:101230101, 泉州:101230501, 漳州:101230601, 龙岩:101230701, 晋江:101230509, 南平:101230901, 厦门:101230201, 宁德:101230301, 莆田:101230401, 三明:101230801, 兰州:101160101, 平凉:101160301, 庆阳:101160401, 武威:101160501, 金昌:101160601, 嘉峪关:101161401, 酒泉:101160801, 天水:101160901, 武都:101161001, 临夏:101161101, 合作:101161201, 白银:101161301, 定西:101160201, 张掖:101160701, 广州:101280101, 惠州:101280301, 梅州:101280401, 汕头:101280501, 深圳:101280601, 珠海:101280701, 佛山:101280800, 肇庆:101280901, 湛江:101281001, 江门:101281101, 河源:101281201, 清远:101281301, 云浮:101281401, 潮州:101281501, 东莞:101281601, 中山:101281701, 阳江:101281801, 揭阳:101281901, 茂名:101282001, 汕尾:101282101, 韶关:101280201, 南宁:101300101, 柳州:101300301, 来宾:101300401, 桂林:101300501, 梧州:101300601, 防城港:101301401, 贵港:101300801, 玉林:101300901, 百色:101301001, 钦州:101301101, 河池:101301201, 北海:101301301, 崇左:101300201, 贺州:101300701, 贵阳:101260101, 安顺:101260301, 都匀:101260401, 兴义:101260906, 铜仁:101260601, 毕节:101260701, 六盘水:101260801, 遵义:101260201, 凯里:101260501, 昆明:101290101, 红河:101290301, 文山:101290601, 玉溪:101290701, 楚雄:101290801, 普洱:101290901, 昭通:101291001, 临沧:101291101, 怒江:101291201, 香格里拉:101291301, 丽江:101291401, 德宏:101291501, 景洪:101291601, 大理:101290201, 曲靖:101290401, 保山:101290501, 呼和浩特:101080101, 乌海:101080301, 集宁:101080401, 通辽:101080501, 阿拉善左旗:101081201, 鄂尔多斯:101080701, 临河:101080801, 锡林浩特:101080901, 呼伦贝尔:101081000, 乌兰浩特:101081101, 包头:101080201, 赤峰:101080601, 南昌:101240101, 上饶:101240301, 抚州:101240401, 宜春:101240501, 鹰潭:101241101, 赣州:101240701, 景德镇:101240801, 萍乡:101240901, 新余:101241001, 九江:101240201, 吉安:101240601, 武汉:101200101, 黄冈:101200501, 荆州:101200801, 宜昌:101200901, 恩施:101201001, 十堰:101201101, 神农架:101201201, 随州:101201301, 荆门:101201401, 天门:101201501, 仙桃:101201601, 潜江:101201701, 襄樊:101200201, 鄂州:101200301, 孝感:101200401, 黄石:101200601, 咸宁:101200701, 成都:101270101, 自贡:101270301, 绵阳:101270401, 南充:101270501, 达州:101270601, 遂宁:101270701, 广安:101270801, 巴中:101270901, 泸州:101271001, 宜宾:101271101, 内江:101271201, 资阳:101271301, 乐山:101271401, 眉山:101271501, 凉山:101271601, 雅安:101271701, 甘孜:101271801, 阿坝:101271901, 德阳:101272001, 广元:101272101, 攀枝花:101270201, 银川:101170101, 中卫:101170501, 固原:101170401, 石嘴山:101170201, 吴忠:101170301, 西宁:101150101, 黄南:101150301, 海北:101150801, 果洛:101150501, 玉树:101150601, 海西:101150701, 海东:101150201, 海南:101150401, 济南:101120101, 潍坊:101120601, 临沂:101120901, 菏泽:101121001, 滨州:101121101, 东营:101121201, 威海:101121301, 枣庄:101121401, 日照:101121501, 莱芜:101121601, 聊城:101121701, 青岛:101120201, 淄博:101120301, 德州:101120401, 烟台:101120501, 济宁:101120701, 泰安:101120801, 西安:101110101, 延安:101110300, 榆林:101110401, 铜川:101111001, 商洛:101110601, 安康:101110701, 汉中:101110801, 宝鸡:101110901, 咸阳:101110200, 渭南:101110501, 太原:101100101, 临汾:101100701, 运城:101100801, 朔州:101100901, 忻州:101101001, 长治:101100501, 大同:101100201, 阳泉:101100301, 晋中:101100401, 晋城:101100601, 吕梁:101101100, 乌鲁木齐:101130101, 石河子:101130301, 昌吉:101130401, 吐鲁番:101130501, 库尔勒:101130601, 阿拉尔:101130701, 阿克苏:101130801, 喀什:101130901, 伊宁:101131001, 塔城:101131101, 哈密:101131201, 和田:101131301, 阿勒泰:101131401, 阿图什:101131501, 博乐:101131601, 克拉玛依:101130201, 拉萨:101140101, 山南:101140301, 阿里:101140701, 昌都:101140501, 那曲:101140601, 日喀则:101140201, 林芝:101140401, 台北县:101340101, 高雄:101340201, 台中:101340401, 海口:101310101, 三亚:101310201, 东方:101310202, 临高:101310203, 澄迈:101310204, 儋州:101310205, 昌江:101310206, 白沙:101310207, 琼中:101310208, 定安:101310209, 屯昌:101310210, 琼海:101310211, 文昌:101310212, 保亭:101310214, 万宁:101310215, 陵水:101310216, 西沙:101310217, 南沙岛:101310220, 乐东:101310221, 五指山:101310222, 琼山:101310102, 长沙:101250101, 株洲:101250301, 衡阳:101250401, 郴州:101250501, 常德:101250601, 益阳:101250700, 娄底:101250801, 邵阳:101250901, 岳阳:101251001, 张家界:101251101, 怀化:101251201, 黔阳:101251301, 永州:101251401, 吉首:101251501, 湘潭:101250201, 南京:101190101, 镇江:101190301, 苏州:101190401, 南通:101190501, 扬州:101190601, 宿迁:101191301, 徐州:101190801, 淮安:101190901, 连云港:101191001, 常州:101191101, 泰州:101191201, 无锡:101190201, 盐城:101190701, 哈尔滨:101050101, 牡丹江:101050301, 佳木斯:101050401, 绥化:101050501, 黑河:101050601, 双鸭山:101051301, 伊春:101050801, 大庆:101050901, 七台河:101051002, 鸡西:101051101, 鹤岗:101051201, 齐齐哈尔:101050201, 大兴安岭:101050701, 长春:101060101, 延吉:101060301, 四平:101060401, 白山:101060901, 白城:101060601, 辽源:101060701, 松原:101060801, 吉林:101060201, 通化:101060501, 沈阳:101070101, 鞍山:101070301, 抚顺:101070401, 本溪:101070501, 丹东:101070601, 葫芦岛:101071401, 营口:101070801, 阜新:101070901, 辽阳:101071001, 铁岭:101071101, 朝阳:101071201, 盘锦:101071301, 大连:101070201, 锦州:101070701} 
    data = ChinaCitiesHour.get_all_real_data
    datac=data.map{ |data| { city_name: data[:city_name],longitude: data[:longitude],latitude: data[:latitude],data: get_real_weahter( city_number[((data[:city_name].include? '市') ? (data[:city_name].delete('市')) : data[:city_name]).to_sym]) } }
    respond_to do |format|
      format.html { render json: datac}
      if params[:callback]
        format.js { render :json => datac.to_json, :callback => params[:callback] }
      else
        format.json { render json: datac}
      end
    end
  end


  def get_real_weahter(city_number)
  xmldoc = Nokogiri::XML(open('http://wthrcdn.etouch.cn/WeatherApi?citykey='+city_number.to_s))

  weather = {}
  # 气象要素
  elements = %w[aqi updatetime wendu fengli shidu fengxiang sunrise_1 sunset_1 ]
  elements.each do |e|
    weather[e] = parse_xml(xmldoc, e)
  end
  weather
  end


  def parse_xml(doc, node)
    if node=='aqi'
      n=doc.at_css("environment aqi")
    else
      n = doc.at_css(node)
    end
    n ? n.text : ''
  end

  def monitor_data
	  if params[:city_name]
		  data = ChinaCitiesHour.get_real_monitor_data(params[:city_name])
	  else
		  data = ChinaCitiesHour.get_all_real_data
	  end


    respond_to do |format|
      format.html { render json: data}
      if params[:callback]
        format.js { render :json => data.to_json, :callback => params[:callback] }
      else
        format.json { render json: data}
      end
    end
  end
end
