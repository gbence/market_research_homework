%w( rubygems haml digest/sha1 dm-core dm-timestamps dm-aggregates dm-types sinatra ).each { |lib| require lib }
%w( haml_helpers ).each { |lib| require 'lib/'+lib }

log = File.new(File.dirname(__FILE__) + "/sinatra.log", "a")
#STDOUT.reopen(log)
#STDERR.reopen(log)
class << log
  def method_missing(name, *args)
    self.write("%10s: %s\n" % [ name.to_s, args.map{|a| "'%s'" % [a] }.join(', ') ])
    self.flush
  end
end

module Haml::Helpers
  def single_choice(*choices)
    haml(%{
%ul.single-choice
  - choices.each_with_index do |choice,index|
    %li
      %input{ :type => 'radio', :name => 'a', :value => choice, :id => 'choice_'+index.to_s }
      = choice
    }, :layout => false, :locals => { :choices => choices }).chomp + "\n"
  end

  def multiple_choice(*choices)
    haml(%{
%ul.multiple-choice
  - choices.each_with_index do |choice,index|
    %li
      %input{ :type => 'checkbox', :name => 'a[]', :value => choice, :id => 'choice_'+index.to_s }
      = choice
    }, :layout => false, :locals => { :choices => choices }).chomp + "\n"
  end

  def table(items, header, &block)
    block_output = ''
    items.each { |item| block_output += capture_haml(item, &block)}
    %{<table><thead><tr>#{header.map{|h| "<th>#{h}</th>"}.join('')}</tr></thead><tbody>#{block_output}</tbody></table>}
  end

  def single_choice_for(item, *choices)
    @parity ||= 0; @parity += 1
    %{<tr class="#{@parity%2==0 ? 'even' : 'odd'}"><td>#{item}</td>#{choices.map{|c| %{<td><input type="radio" name="a[#{item}]" value="#{c}" id="choice_#{(item+c).hash.abs}"/><label for="choice_#{(item+c).hash.abs}">#{c}</label></td>}}.join('')}</tr>}
  end

  def check_box_for(item)
    @parity ||= 0; @parity += 1
    %{<tr><td><input type="checkbox" name="a[]" id="check_#{item.hash.abs}" value="#{item}"/></td><td><label for="check_#{item.hash.abs}">#{item}</label></td></tr>}
  end
end

class Questionnaire
  include DataMapper::Resource

  property :id, Serial
  property :hash, String, :length => 40, :nullable => false, :default => Proc.new { |r,p| Digest::SHA1.hexdigest(Time.now.tv_usec.to_s + 'gbence' + rand.to_s) }
  timestamps :created_at, :updated_at

  has n, :answers, :order => [:number.asc]
end

class Answer
  include DataMapper::Resource

  property :id, Serial
  property :answer, Yaml
  property :number, Integer
  belongs_to :questionnaire
end

configure :development do
  DataMapper.setup(:default, :adapter => 'sqlite3', :database => 'db/development.sqlite3')
  DataMapper.auto_migrate!
end

configure :production do
  DataMapper.setup(:default, :adapter => 'sqlite3', :database => 'db/production.sqlite3')
end

enable :sessions

def flash
  session[:flash] = {} if !session[:flash].is_a?(Hash)
  session[:flash]
end

# questionnaire :marketing do
#   single_choice 'Használ mobiltelefont?', [ 'igen', 'nem' ], :as => :hasznal_mobiltelefont
#   group :if => lambda { hasznal_mobiltelefont == 'igen' } do
#     single_choice 'Melyik szolgáltatónál van előfizetése?', [ 'Pannon', 'T-Mobile', 'Vodafone' ]
#     single_choice 'Milyen típusú mobiltelefon szolgáltatást vesz igénybe?', [ 'Előfizetéses', 'Kártyás' ], :as => :szolgaltatas_tipus
#     group :if => lambda { szolgaltatas_tipus == 'Kártyás' } do
#       single_choice 'Milyen gyakran tölti fel egyenlegét?', [ 'Hetente', 'Két hetente', 'Havonta', 'Két havonta', 'Félévente', 'Ritkábban' ]
#       single_choice 'Egy alkalommal mekkora összeget tölt fel a kártyájára?', [ '1000 - 2000', '3000 - 4000', '5000 - 7000', '8000 - 15000' ]
#     end
#     single_choice 'Mióta használ mobiltelefont?', [ 'kevesebb, mint 1 éve', '1 - 3 éve', '4 - 6 éve', '7 - 10 éve', 'több, mint 10 éve' ]
#     single_choice 'Igen / nem?', [ 'igen', 'nem' ]
#   end
#   single_choice 'Nemigen', [ 'nem', 'igen' ]
# end

get '/hf.css' do
  content_type 'text/css', :charset => 'utf-8'
  sass :hf
end

before do
  _, q, n = request.path_info.split('/')
  log.info params.inspect
  @q = Questionnaire.first(:hash => q) if q
  @n = (n.gsub(/^q/, '').to_i rescue 0) if n
end

def redirect_to_q n
  redirect '/%s/q%03d' % [ @q.hash, n ]
end

get '/' do
  @q = Questionnaire.create :created_at => Time.now, :updated_at => Time.now
  session[:hash] = @q.hash
  redirect '/%s' % [@q.hash]
end

get '/:questionnaire' do
  redirect '/' unless @q
  haml :intro
end

get '/:questionnaire/:qn' do
  redirect '/' unless @q
  redirect '/' unless @q.hash == session[:hash]
  haml :"questions/#{params[:qn]}", :layout => :questions
end

# # q001: 'Használ mobiltelefont?' [ 'igen' => :q2, 'nem' => .. ]
# post '/:questionnaire/q001' do
#   Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
#   # TODO
#   case params[:a]
#   when 'Igen'
#     redirect_to_q 2
#   when 'Nem'
#     redirect_to_q 15
#   else
#     flash[:error] = 'Kérem válaszoljon az egyik pont megjelölésével!'
#     redirect_to_q 1
#   end
# end
# 
# # q002: 'Melyik szolgáltatónál van előfizetése?', [ 'Pannon', 'T-Mobile', 'Vodafone' ]
# post '/:questionnaire/q002' do
#   Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
#   redirect_to_q 3
# end
# 
# # q003: 'Milyen típusú mobiltelefon szolgáltatást vesz igénybe?', [ 'Előfizetéses' => :q6, 'Kártyás' ]
# post '/:questionnaire/q003' do
#   Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
#   case params[:a]
#   when 'Előfizetéses'
#     redirect_to_q 6
#   when 'Kártyás'
#     redirect_to_q 4
#   else
#     flash[:error] = 'Kérem válaszoljon az egyik pont megjelölésével!'
#     redirect_to_q 3
#   end
# end

# q001: 'Használ mobiltelefont?', ["Igen", "Nem"]
post '/:questionnaire/q001' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 2
end

# q002: 'Melyik szolgáltatónál van előfizetése?', ["Pannon", "T-Mobile", "Vodafone"]
post '/:questionnaire/q002' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 3
end

# q003: 'Meg van elégedve a Pannon szolgáltatásával?', ["Igen", "Nem"]
post '/:questionnaire/q003' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 4
end

# q004: 'Meg van elégedve a T-Mobile szolgáltatásával?', ["Igen", "Nem"]
post '/:questionnaire/q004' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 5
end

# q005: 'Meg van elégedve a Vodafone szolgáltatásával?', ["Igen", "Nem"]
post '/:questionnaire/q005' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 6
end

# q006: 'Milyen típusú mobiltelefon szolgáltatást vesz igénybe?', ["El\305\221fizet\303\251ses", "K\303\241rty\303\241s"]
post '/:questionnaire/q006' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 7
end

# q007: 'Milyen gyakran tölti fel egyenlegét?', ["Hetente", "K\303\251t hetente", "Havonta", "K\303\251t havonta", "F\303\251l\303\251vente", "Ritk\303\241bban"]
post '/:questionnaire/q007' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 8
end

# q008: 'Egy alkalommal mekkora összeget tölt fel a kártyájára?', ["1.000 - 2.000 Ft", "2.001 - 4.000 Ft", "4.001 - 8.000 Ft", "8.001 - 15.000 Ft", "15.000 Ft-n\303\241l is t\303\266bbet"]
post '/:questionnaire/q008' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 9
end

# q009: 'Havonta átlagosan mennyibe kerül az Ön mobiltelefon használata?', ["0 - 3.000 Ft", "3.001 - 6.000 Ft", "6.001 - 10.000 Ft", "10.001 - 20.000 Ft", "T\303\266bb, mint 20000 Ft"]
post '/:questionnaire/q009' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 10
end

# q010: 'Mennyit fizet munkáltatója (cége) az Ön mobiltelefon használata után?', ["Semennyit sem", "1 - 3.000 Ft-ot", "3.001 - 6.000 Ft-ot", "6.001 - 10.000 Ft-ot", "10001 - 20000 Ft-ot", "T\303\266bb, mint 20000 Ft-ot", "A teljes sz\303\241ml\303\241mat fizeti"]
post '/:questionnaire/q010' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 11
end

# q011: 'Mióta használ mobiltelefont?', ["Kevesebb, mint 1 \303\251ve", "1 - 3 \303\251ve", "4 - 6 \303\251ve", "7 - 10 \303\251ve", "T\303\266bb, mint 10 \303\251ve"]
post '/:questionnaire/q011' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 12
end

# q012: 'Hány mobiltelefon számot használ?', ["1", "2", "3", "T\303\266bb"]
post '/:questionnaire/q012' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 13
end

# q013: 'Ismeri az alábbi mobil-szolgáltatásokat?', ["Igen", "Nem"], ["Aut\303\263p\303\241lya matrica v\303\241s\303\241rl\303\241s", "Parkol\303\263jegy v\303\241s\303\241rl\303\241s", "Mozijegy v\303\241s\303\241rl\303\241s", "Apr\303\263hirdet\303\251s felad\303\241s", "Lott\303\263 v\303\241s\303\241rl\303\241s", "Cseng\305\221hang let\303\266lt\303\251s", "J\303\241t\303\251k let\303\266lt\303\251s", "Mobil TV", "Film let\303\266lt\303\251s", "Zene let\303\266lt\303\251s", "BKV-jegy v\303\241s\303\241rl\303\241s", "Koncert-jegy v\303\241s\303\241rl\303\241s", "M\303\272zeum-jegy v\303\241s\303\241rl\303\241s"]
post '/:questionnaire/q013' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 14
end

# q014: 'Használta már az alábbi mobil-szolgáltatásokat?', ["Igen", "Nem"], ["Aut\303\263p\303\241lya matrica v\303\241s\303\241rl\303\241s", "Parkol\303\263jegy v\303\241s\303\241rl\303\241s", "Mozijegy v\303\241s\303\241rl\303\241s", "Apr\303\263hirdet\303\251s felad\303\241s", "Lott\303\263 v\303\241s\303\241rl\303\241s", "Cseng\305\221hang let\303\266lt\303\251s", "J\303\241t\303\251k let\303\266lt\303\251s", "Mobil TV", "Film let\303\266lt\303\251s", "Zene let\303\266lt\303\251s", "BKV-jegy v\303\241s\303\241rl\303\241s", "Koncert-jegy v\303\241s\303\241rl\303\241s", "M\303\272zeum-jegy v\303\241s\303\241rl\303\241s"]
post '/:questionnaire/q014' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 15
end

# q015: 'A szolgáltatások közül melyiket használná szívesen?', ["Aut\303\263p\303\241lya matrica v\303\241s\303\241rl\303\241s", "Parkol\303\263jegy v\303\241s\303\241rl\303\241s", "Mozijegy v\303\241s\303\241rl\303\241s", "Apr\303\263hirdet\303\251s felad\303\241s", "Lott\303\263 v\303\241s\303\241rl\303\241s", "Cseng\305\221hang let\303\266lt\303\251s", "J\303\241t\303\251k let\303\266lt\303\251s", "Mobil TV", "Film let\303\266lt\303\251s", "Zene let\303\266lt\303\251s", "BKV-jegy v\303\241s\303\241rl\303\241s", "Koncert-jegy v\303\241s\303\241rl\303\241s", "M\303\272zeum-jegy v\303\241s\303\241rl\303\241s"]
post '/:questionnaire/q015' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 16
end

# q016: 'Használta már külföldön mobiltelefonját?', ["Igen", "Nem"]
post '/:questionnaire/q016' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 17
end

# q017: 'Külföldön milyen mobiltelefon szolgáltatásokat vett igénybe?', ["Telefon\303\241l\303\241s", "SMS", "MMS", "Hangposta", "Internetez\303\251s / WAP"]
post '/:questionnaire/q017' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 18
end

# q018: 'Az alábbi állítások közül melyik igaz Önre?', ["Csak akkor haszn\303\241lom a telefonomat k\303\274lf\303\266ld\303\266n, ha nagyon musz\303\241j.", "Nem telefon\303\241lok, ink\303\241bb SMS-ezek.", "Kicsit visszafogom magam a magas roaming d\303\255jak miatt.", "Ugyan\303\272gy telefon\303\241lok \303\251s SMS-ezek, mint otthon."]
post '/:questionnaire/q018' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 19
end

# q019: 'Rendelkezik mobilinternet előfizetéssel?', ["Igen", "Nem"]
post '/:questionnaire/q019' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 20
end

# q020: 'Melyik szolgáltatónál van mobilinternet előfizetése?', ["Pannon", "T-Mobile", "Vodafone"]
post '/:questionnaire/q020' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 21
end

# q021: 'Ön szerint mi jellemzi legjobban a Pannon mobilinternet szolgáltatás?', ["Megb\303\255zhat\303\263an m\305\261k\303\266dik.", "\303\201ltal\303\241ban megy, de vannak probl\303\251m\303\241k.", "Csak n\303\251h\303\241ny helyen megy, ott is lassan.", "Alig tudom haszn\303\241lni, mindig vannak vele probl\303\251m\303\241k."]
post '/:questionnaire/q021' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 22
end

# q022: 'Ön szerint mi jellemzi legjobban a T-Mobile mobilinternet szolgáltatás?', ["Megb\303\255zhat\303\263an m\305\261k\303\266dik.", "\303\201ltal\303\241ban megy, de vannak probl\303\251m\303\241k.", "Csak n\303\251h\303\241ny helyen megy, ott is lassan.", "Alig tudom haszn\303\241lni, mindig vannak vele probl\303\251m\303\241k."]
post '/:questionnaire/q022' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 23
end

# q023: 'Ön szerint mi jellemzi legjobban a Vodafone mobilinternet szolgáltatás?', ["Megb\303\255zhat\303\263an m\305\261k\303\266dik.", "\303\201ltal\303\241ban megy, de vannak probl\303\251m\303\241k.", "Csak n\303\251h\303\241ny helyen megy, ott is lassan.", "Alig tudom haszn\303\241lni, mindig vannak vele probl\303\251m\303\241k."]
post '/:questionnaire/q023' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 24
end

# q024: 'Rendelkezik az Ön készüléke a következő funkciókkal?', ["Igen", "Nem", "Nem tudom"], ["Internet/WAP", "Mobilk\303\263d", "Sz\303\241mol\303\263g\303\251p", "Konferenciah\303\255v\303\241s", "Hangposta", "\303\211breszt\305\221\303\263ra", "MMS", "Kihangos\303\255t\303\241s", "Bluetooth", "J\303\241t\303\251kok", "Chat", "GPS", "Szundi", "F\303\251nyk\303\251pez\303\251s", "Vide\303\263 r\303\266gz\303\255t\303\251s", "SMS", "MP3 lej\303\241tsz\303\241s", "Jegyzet", "Hat\303\241rid\305\221napl\303\263", "Bej\303\266v\305\221 h\303\255v\303\241s eln\303\251m\303\255t\303\241sa", "T\303\266bb telefonsz\303\241m ment\303\251se egy n\303\251vhez", "Cseng\305\221hang rendel\303\251se n\303\251vhez", "Gyorsh\303\255v\303\241s", "SMS sablon", "H\303\255v\303\241skorl\303\241toz\303\241s", "EMS (k\303\251p\303\274zenet)", "Java t\303\241mogat\303\241s", "H\303\255v\303\241ssz\305\261r\303\251s", "Valuta\303\241rfolyam", "Diktafon", "Emailez\303\251s", "H\303\255v\303\241sv\303\241rakoztat\303\241s", "\303\234t\303\251s\303\241ll\303\263s\303\241g", "V\303\255z\303\241ll\303\263s\303\241g", "R\303\241di\303\263", "Nagym\303\251ret\305\261 mem\303\263riak\303\241rtya"]
post '/:questionnaire/q024' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 25
end

# q025: 'Milyen gyakran használja az alábbi funkciókat?', ["Mindig", "Gyakran", "\303\201ltal\303\241ban", "Ritk\303\241n", "Soha"], ["Internet/WAP", "Mobilk\303\263d", "Sz\303\241mol\303\263g\303\251p", "Konferenciah\303\255v\303\241s", "Hangposta", "\303\211breszt\305\221\303\263ra", "MMS", "Kihangos\303\255t\303\241s", "Bluetooth", "J\303\241t\303\251kok", "Chat", "GPS", "Szundi", "F\303\251nyk\303\251pez\303\251s", "Vide\303\263 r\303\266gz\303\255t\303\251s", "SMS", "MP3 lej\303\241tsz\303\241s", "Jegyzet", "Hat\303\241rid\305\221napl\303\263", "Bej\303\266v\305\221 h\303\255v\303\241s eln\303\251m\303\255t\303\241sa", "T\303\266bb telefonsz\303\241m ment\303\251se egy n\303\251vhez", "Cseng\305\221hang rendel\303\251se n\303\251vhez", "Gyorsh\303\255v\303\241s", "SMS sablon", "H\303\255v\303\241skorl\303\241toz\303\241s", "EMS (k\303\251p\303\274zenet)", "Java t\303\241mogat\303\241s", "H\303\255v\303\241ssz\305\261r\303\251s", "Valuta\303\241rfolyam", "Diktafon", "Emailez\303\251s", "H\303\255v\303\241sv\303\241rakoztat\303\241s", "\303\234t\303\251s\303\241ll\303\263s\303\241g", "V\303\255z\303\241ll\303\263s\303\241g", "R\303\241di\303\263", "Nagym\303\251ret\305\261 mem\303\263riak\303\241rtya"]
post '/:questionnaire/q025' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 26
end

# q026: 'A felsorolt funkciók közül melyiket használná szivesen?', ["Internet/WAP", "Mobilk\303\263d", "Sz\303\241mol\303\263g\303\251p", "Konferenciah\303\255v\303\241s", "Hangposta", "\303\211breszt\305\221\303\263ra", "MMS", "Kihangos\303\255t\303\241s", "Bluetooth", "J\303\241t\303\251kok", "Chat", "GPS", "Szundi", "F\303\251nyk\303\251pez\303\251s", "Vide\303\263 r\303\266gz\303\255t\303\251s", "SMS", "MP3 lej\303\241tsz\303\241s", "Jegyzet", "Hat\303\241rid\305\221napl\303\263", "Bej\303\266v\305\221 h\303\255v\303\241s eln\303\251m\303\255t\303\241sa", "T\303\266bb telefonsz\303\241m ment\303\251se egy n\303\251vhez", "Cseng\305\221hang rendel\303\251se n\303\251vhez", "Gyorsh\303\255v\303\241s", "SMS sablon", "H\303\255v\303\241skorl\303\241toz\303\241s", "EMS (k\303\251p\303\274zenet)", "Java t\303\241mogat\303\241s", "H\303\255v\303\241ssz\305\261r\303\251s", "Valuta\303\241rfolyam", "Diktafon", "Emailez\303\251s", "H\303\255v\303\241sv\303\241rakoztat\303\241s", "\303\234t\303\251s\303\241ll\303\263s\303\241g", "V\303\255z\303\241ll\303\263s\303\241g", "R\303\241di\303\263", "Nagym\303\251ret\305\261 mem\303\263riak\303\241rtya"]
post '/:questionnaire/q026' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 27
end

# q027: 'Milyen gyakran cseréli mobiltelefon készülékét?', ["1 - 2 havonta", "3 -\302\2406 havonta", "7 - 12 havonta", "13 - 24 havonta", "25 - 36 havonta", "Ritk\303\241bban"]
post '/:questionnaire/q027' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 28
end

# q028: 'Általában miért vásárol új készüléket?', ["Design", "\303\232j technol\303\263giai \303\272jdons\303\241g (streaming, chat, mobil TV, stb.)", "Lej\303\241rt h\305\261s\303\251gszerz\305\221d\303\251s", "Kedvezm\303\251nyes aj\303\241nlat, akci\303\263", "Egy\303\251b, k\303\251rj\303\274k r\303\251szletezze:"]
post '/:questionnaire/q028' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 29
end

# q029: 'Hány készüléke volt az elmúlt 5 évben?', ["1 \342\200\223 3", "4 \342\200\223 6", "7 \342\200\223 9", "10, vagy ann\303\241l is t\303\266bb"]
post '/:questionnaire/q029' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 30
end

# q030: 'Milyen készüléket használ?', ["Alcatel", "BlackBerry", "iPhone", "LG", "Motorola", "Nokia", "Panasonic", "Sagem", "Samsung", "Siemens", "Sony Ericsson", "egy\303\251b:"]
post '/:questionnaire/q030' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 31
end

# q031: 'Milyen árkategóriájú készüléket használ?', ["0 - 5.000 Ft", "5.001 - 20.000 Ft", "20.001 - 60.000 Ft", "60.001 - 120.000 Ft", "120.001 Ft, vagy ann\303\241l is t\303\266bb", "Nem tudom"]
post '/:questionnaire/q031' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 32
end

# q032: 'Hány működőképes készüléke van, beleértve a nem használt készülékeket is?', ["1", "2", "3", "4", "5", "T\303\266bb"]
post '/:questionnaire/q032' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 33
end

# q033: 'Hány készüléket tart éjjel-nappal bekapcsolva?', ["0", "1", "2", "3", "4", "5", "T\303\266bb"]
post '/:questionnaire/q033' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 34
end

# q034: 'Milyen gyakran van bekapcsolva az aktívan használt készüléke?', ["\303\211jjel-nappal", "Nappal", "Csak munkaid\305\221ben", "Alkalmank\303\251nt"]
post '/:questionnaire/q034' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 35
end

# q035: 'Hol hallott a mobilkód szolgáltatásról?', ["Internet", "Magazinok", "Sz\303\263r\303\263lapok", "Ismer\305\221st\305\221l", "Egy\303\251b:"]
post '/:questionnaire/q035' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 36
end

# q036: 'Használt már vagy használja a mobilkódot?', ["Igen", "Nem"]
post '/:questionnaire/q036' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 37
end

# q037: 'Támogatja a mobiltelefon készüléke kódolvasó alkalmazás futtatását?', ["Igen", "Nem"]
post '/:questionnaire/q037' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 38
end

# q038: 'Sikerült letöltenie kódolvasó alkalmazást?', ["Igen", "Nem"]
post '/:questionnaire/q038' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 39
end

# q039: 'Olvasott már le sikeresen mobilkódot mobiltelefon készülékével?', ["Igen", "Nem"]
post '/:questionnaire/q039' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 40
end

# q040: 'Mire használta vagy használja a mobilkódot?', ["Nyerem\303\251nyj\303\241t\303\251k", "Inform\303\241ci\303\263szerz\303\251s", "N\303\251vjegyk\303\241rtya bejegyz\303\251sek gyors olvas\303\241sa", "Egy\303\251b:"]
post '/:questionnaire/q040' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 41
end

# q041: 'Milyen kódolvasót használ?', ["I-nigma", "QuickMark", "Telefonba be\303\251p\303\255tett kliens", "Egy\303\251b:"]
post '/:questionnaire/q041' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 42
end

# q042: 'Értékelje a mobilkódot! Van értelme? Ön szerint miért jó, miért rossz?', 
post '/:questionnaire/q042' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 43
end

# q043: 'Neme?', ["F\303\251rfi", "N\305\221"]
post '/:questionnaire/q043' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 44
end

# q044: 'Kora?', 
post '/:questionnaire/q044' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 45
end

# q045: 'Mennyi a háztartásában az egy főre jutó nettó jövedelem?', 
post '/:questionnaire/q045' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 46
end

# q046: 'Hányan élnek egy háztartásban?', 
post '/:questionnaire/q046' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 47
end

# q047: 'Lakhelye?', ["Budapest", "Megyesz\303\251khely vagy megyei jog\303\272 v\303\241ros", "Kisebb telep\303\274l\303\251s"]
post '/:questionnaire/q047' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q 48
end

