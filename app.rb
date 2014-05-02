# encoding: utf-8
RACK_ENV  = ENV['RACK_ENV'] ||= 'development' unless defined?(RACK_ENV)
RACK_ENV_SYM = RACK_ENV.to_sym unless defined?(RACK_ENV_SYM)
require 'sinatra'
require 'sinatra/reloader' if RACK_ENV_SYM == :development
require 'mechanize'

TEMPLATE = :template
set :views, File.dirname(__FILE__) + '/views'

URL_LIST = "http://210.96.13.90/api/rest/subwayInfo/getStatnByRoute?subwayId=100%{id}"
URL_STATION_INFO = "http://210.96.13.90/api/rest/subwayInfo/getStatnById?subwayId=100%{id}&statnId=%{station}"
URL_STATION_ARRIVAL = "http://210.96.13.90/api/rest/subwayInfo/getArvlByInfo?subwayId=100%{id}&statnId=%{station}"

agent = Mechanize.new
agent.request_headers = {
  'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)',
  'Cookie' => 'WMONID=ZGhEJOE5bAt' # don't feel needed
}


get '/transports/raw/:number' do
  content_type :xml

  number = params[:number]
  agent.get(URL_LIST % { id: number }).body
end

get '/transports/raw/:number/:station' do
  content_type :xml

  number = params[:number]
  station = params[:station]

  if params.has_key? 'arrival'
    url = URL_STATION_ARRIVAL % { id: number, station: station }
  else
    url = URL_STATION_INFO % { id: number, station: station }
  end
  agent.get(url).body
end

get '/transports/:number' do
  content_type :html

  @number = params[:number]
  data = agent.get(URL_LIST % { id: @number })
  @code = data.at('//msgHeader/headerCd').text
  @msg = data.at('//msgHeader/headerMsg').text
  @items = data.search('//msgBody/itemList')

  erb TEMPLATE
end

get '/transports/:number/:station' do
  content_type :html

  @data = {
    success: true,
    name: '',
    content: {}
  }
  @number, @station = params[:number], params[:station]
  @items = agent.get(URL_LIST % { id: @number }).search('//msgBody/itemList')
  stn_info = agent.get(URL_STATION_INFO % { id: @number, station: @station })
  stn_arrival = agent.get(URL_STATION_ARRIVAL % { id: @number, station: @station })

  info_code, info_msg = stn_info.at('//msgHeader/headerCd').text, \
                         stn_info.at('//msgHeader/headerMsg').text
  arrival_code, arrival_msg = stn_arrival.at('//msgHeader/headerCd').text, \
                                stn_arrival.at('//msgHeader/headerMsg').text

  unless info_code == '0' and arrival_code == '0'
    @data[:success] = false
    @code = '-1'
    @msg = ( info_code == '0' ? arrival_msg : info_msg )
  else
    @code = '0'

    first_station = stn_info.at('//msgBody/itemList/statnFnm').text
    second_station = stn_info.at('//msgBody/itemList/statnTnm').text

    @data[:name] = stn_info.at('//msgBody/itemList/statnNm').text
    @data[:sideStation] = { before: second_station, after: first_station }
    @data[:content][:address] = stn_info.at('//msgBody/itemList/adres').text
    @data[:content][:operPblinstt] = stn_info.at('//msgBody/itemList/operPblinstt').text
    @data[:content][:outerLine] = [] # 외선순환
    @data[:content][:innerLine] = [] # 내선순환

    stn_arrival.search('//msgBody/itemList').each do |stn|
      line_name = stn.at('updnLine').text
      data = {
        :trainAt => stn.at('arvlMsg3').text, # 현재 열차 위치
        :trainArrivalTime => stn.at('arvlMsg2').text, # 열차 예상 도착시간
        :trainLineName => stn.at('trainLineNm').text, # 열차 방향 - 방면 ( 성수행 - 잠실나루방면 )
        :trainBeforeStation => ( stn.at('cStatnNm').text.include?(first_station) \
                                 ? first_station : second_station ), # 전 역
        :trainAfterStation => ( stn.at('cStatnNm').text.include?(first_station) \
                                 ? second_station : first_station ), # 다음 역
      }

      # (maybe) works only in seoul metro lines
      if line_name == '외선'
        @data[:content][:outerLine] << data
      elsif line_name == '내선'
        @data[:content][:innerLine] << data
      end
    end
  end

  erb TEMPLATE
end

get '/' do
  content_type :html
  erb TEMPLATE
end