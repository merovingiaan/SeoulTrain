require 'sinatra'
require 'sinatra/reloader'
require 'mechanize'

MAIN_HTML = :template

agent = Mechanize.new
agent.request_headers = {
  'User-Agent' => 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.0)',
  'Cookie' => 'WMONID=ZGhEJOE5bAt'
}

@@station_list = {}

# use for tests
get '/transports/raw/:number' do
  content_type :xml

  number = params[:number]
  agent.get("http://210.96.13.90/api/rest/subwayInfo/getStatnByRoute?subwayId=100#{number}").body
end
get '/transports/raw/:number/:station' do
  content_type :xml

  number = params[:number]
  station = params[:station]

  if params.has_key? 'arrival'
    url = "http://210.96.13.90/api/rest/subwayInfo/getArvlByInfo?subwayId=100#{number}&statnId=#{station}"
  else
    url = "http://210.96.13.90/api/rest/subwayInfo/getStatnById?subwayId=100#{number}&statnId=#{station}"
  end
  agent.get(url).body
end
# end

get '/transports/:number' do
  content_type :html

  @number = params[:number]
  data = agent.get("http://210.96.13.90/api/rest/subwayInfo/getStatnByRoute?subwayId=100#{@number}")
  @code = data.at('//msgHeader/headerCd').text
  @msg = data.at('//msgHeader/headerMsg').text
  @items = data.search('//msgBody/itemList')

  erb MAIN_HTML
end

get '/transports/:number/:station' do
  content_type :html

  @data = {
    success: true,
    name: '',
    content: {}
  }
  @number, @station = params[:number], params[:station]
  stn_info = agent.get("http://210.96.13.90/api/rest/subwayInfo/getStatnById?subwayId=100#{@number}&statnId=#{@station}")
  stn_arrival = agent.get("http://210.96.13.90/api/rest/subwayInfo/getArvlByInfo?subwayId=100#{@number}&statnId=#{@station}")
  @items = agent.get("http://210.96.13.90/api/rest/subwayInfo/getStatnByRoute?subwayId=100#{@number}").search('//msgBody/itemList')

  p stn_arrival.at('//msgHeader/headerCd').text
  p stn_info.at('//msgHeader/headerCd').text

  unless stn_info.at('//msgHeader/headerCd').text == '0' and \
    stn_arrival.at('//msgHeader/headerCd').text == '0'
    @data[:success] = false
    @code = '-1'
  else
    @code = '0'

    first_station = stn_info.at('//msgBody/itemList/statnFnm').text
    second_station = stn_info.at('//msgBody/itemList/statnTnm').text

    @data[:name] = stn_info.at('//msgBody/itemList/statnNm').text
    @data[:sideStation] = {
      before: second_station, after: first_station
    }
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
        :trainBeforeStation => ( stn.at('cStatnNm').text.include?(first_station) ? first_station : second_station ), # 전 역
        :trainAfterStation => ( stn.at('cStatnNm').text.include?(first_station) ? second_station : first_station ), # 다음 역
      }

      if line_name == '외선'
        @data[:content][:outerLine] << data
      elsif line_name == '내선'
        @data[:content][:innerLine] << data
      end
    end
  end

  erb MAIN_HTML
end

get '/' do
  content_type :html
  erb MAIN_HTML
end