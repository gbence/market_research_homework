#!/usr/bin/env ruby

File.unlink('skeleton.tmp')
DIR = File.dirname(__FILE__) + '/views/questions'
@qn = 0

Dir.mkdir(DIR) unless File.exists?(DIR)

def skeleton(*args)
  @qn += 1
  File.open('skeleton.tmp', 'a') do |f|
    f.write(%{# q#{'%03d' % [@qn]}: '#{args.first}', #{args[1..-1].map{|a| a.inspect}.join(', ')}
post '/:questionnaire/q#{'%03d' % [@qn]}' do
  Answer.create(:answer => params[:a], :number => @n, :questionnaire => @q)
  redirect_to_q #{@qn+1}
end\n
})
  end
end

def single_choice(question, choices)
  skeleton(question, choices)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  %p.suggestion A lehetőségek közül egyet válasszon!
  = single_choice #{choices.map { |c| "'#{c}'" }.join(", ")}
  = submit
})
  end
end

def multiple_choice(question, choices)
  skeleton(question, choices)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  %p.suggestion A lehetőségek közül többet is választhat!
  = multiple_choice #{choices.map { |c| "'#{c}'" }.join(", ")}
  = submit
})
  end
end

def multiple_choice_with_free(question, choices)
  skeleton(question, choices)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  %p.suggestion A lehetőségek közül többet is választhat!
  = multiple_choice_with_free #{choices.map { |c| "'#{c}'" }.join(", ")}
  = submit
})
  end
end

def table_single_choice(question, choices, header, table)
  skeleton(question, choices, table)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  = table [ #{table.map { |e| "'#{e.to_s}'" }.join(', ')} ], [ '#{header}' ] + [nil]*#{choices.size} do |item|
    = single_choice_for item, #{choices.map { |c| "'#{c}'" }.join(", ")}
  = submit
})
  end
end

def table_check_box(question, header, table)
  skeleton(question, table)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  = table [ #{table.map { |e| "'#{e.to_s}'" }.join(', ')} ], [ nil, '#{header}' ] do |item|
    = check_box_for item
  = submit
})
  end
end

def table_multiple_choice(question, choices, header, table)
  skeleton(question, choices, table)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  = table [ #{table.map { |e| "'#{e.to_s}'" }.join(', ')} ], [ '#{header}' ] + [nil]*#{choices.size} do |item|
    = multiple_choice_for item, #{choices.map { |c| "'#{c}'" }.join(", ")}
  = submit
})
  end
end

def free_number(question)
  skeleton(question)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  %p.suggestion Kérjük egy pozitív egész számot írjon a mezőbe (arab számokkal :) )!
  = free_text
  = submit
})
  end
end

def free_text(question)
  skeleton(question)
  File.open('%s/q%03d.haml' % [ DIR, @qn ], 'w') do |f|
    f.write(%{= form_for_q #{@qn} do
  = ask '#{question}'
  %p.suggestion Kérjük írja le véleményét, szabadon!
  = free_text
  = submit
})
  end
end

single_choice 'Használ mobiltelefont?', [ 'Igen', 'Nem' ]
multiple_choice 'Melyik szolgáltatónál van előfizetése?', [ 'Pannon', 'T-Mobile', 'Vodafone' ]
single_choice 'Meg van elégedve a Pannon szolgáltatásával?', [ 'Igen', 'Nem' ]
single_choice 'Meg van elégedve a T-Mobile szolgáltatásával?', [ 'Igen', 'Nem' ]
single_choice 'Meg van elégedve a Vodafone szolgáltatásával?', [ 'Igen', 'Nem' ]
single_choice 'Milyen típusú mobiltelefon szolgáltatást vesz igénybe?', [ 'Előfizetéses', 'Kártyás' ]
single_choice 'Milyen gyakran tölti fel egyenlegét?', [ 'Hetente', 'Két hetente', 'Havonta', 'Két havonta', 'Félévente', 'Ritkábban' ]
single_choice 'Egy alkalommal mekkora összeget tölt fel a kártyájára?', [ '1.000 - 2.000 Ft', '2.001 - 4.000 Ft', '4.001 - 8.000 Ft', '8.001 - 15.000 Ft', '15.000 Ft-nál is többet' ]
single_choice 'Havonta átlagosan mennyibe kerül az Ön mobiltelefon használata?', [ '0 - 3.000 Ft', '3.001 - 6.000 Ft', '6.001 - 10.000 Ft', '10.001 - 20.000 Ft', 'Több, mint 20.000 Ft' ]
single_choice 'Mennyit fizet munkáltatója (cége) az Ön mobiltelefon használata után?', [ 'Semennyit sem', '1 - 3.000 Ft-ot', '3.001 - 6.000 Ft-ot', '6.001 - 10.000 Ft-ot', '10.001 - 20.000 Ft-ot', 'Több, mint 20.000 Ft-ot', 'A teljes számlámat fizeti' ]
single_choice 'Mióta használ mobiltelefont?', [ 'Kevesebb, mint 1 éve', '1 - 3 éve', '4 - 6 éve', '7 - 10 éve', 'Több, mint 10 éve' ]
single_choice 'Hány mobiltelefon számot használ?', [ '1', '2', '3', 'Több' ]
#single_choice 'Szeretne váltani mobiltelefon-szolgáltatást?', [ 'Igen', 'Nem' ]

SERVICES = [ 'Autópálya matrica vásárlás',
             'Parkolójegy vásárlás',
             'Mozijegy vásárlás',
             'Apróhirdetés feladás',
             'Lottó vásárlás',
             'Csengőhang letöltés',
             'Játék letöltés',
             'Mobil TV',
             'Film letöltés',
             'Zene letöltés',
             'BKV-jegy vásárlás',
             'Koncert-jegy vásárlás',
             'Múzeum-jegy vásárlás' ]

table_single_choice 'Ismeri az alábbi mobil-szolgáltatásokat?', [ 'Igen', 'Nem' ], 'Szolgáltatás', SERVICES
table_single_choice 'Használta már az alábbi mobil-szolgáltatásokat?', [ 'Igen', 'Nem' ], 'Szolgáltatás', SERVICES
table_check_box 'A szolgáltatások közül melyiket használná szívesen?', 'Szolgáltatás', SERVICES

single_choice 'Használta már külföldön mobiltelefonját?', [ 'Igen', 'Nem' ]
multiple_choice 'Külföldön milyen mobiltelefon szolgáltatásokat vett igénybe?', [ 'Telefonálás', 'SMS', 'MMS', 'Hangposta', 'Internetezés / WAP' ]
multiple_choice 'Az alábbi állítások közül melyik igaz Önre?', [ 'Csak akkor használom a telefonomat külföldön, ha nagyon muszáj.', 'Nem telefonálok, inkább SMS-ezek.', 'Kicsit visszafogom magam a magas roaming díjak miatt.', 'Ugyanúgy telefonálok és SMS-ezek, mint otthon.' ]

single_choice 'Rendelkezik mobilinternet előfizetéssel?', [ 'Igen', 'Nem' ]
multiple_choice 'Melyik szolgáltatónál van mobilinternet előfizetése?', [ 'Pannon', 'T-Mobile', 'Vodafone' ]
single_choice 'Ön szerint mi jellemzi legjobban a Pannon mobilinternet szolgáltatás?', [ 'Megbízhatóan működik.', 'Általában megy, de vannak problémák.', 'Csak néhány helyen megy, ott is lassan.', 'Alig tudom használni, mindig vannak vele problémák.' ]
single_choice 'Ön szerint mi jellemzi legjobban a T-Mobile mobilinternet szolgáltatás?', [ 'Megbízhatóan működik.', 'Általában megy, de vannak problémák.', 'Csak néhány helyen megy, ott is lassan.', 'Alig tudom használni, mindig vannak vele problémák.' ]
single_choice 'Ön szerint mi jellemzi legjobban a Vodafone mobilinternet szolgáltatás?', [ 'Megbízhatóan működik.', 'Általában megy, de vannak problémák.', 'Csak néhány helyen megy, ott is lassan.', 'Alig tudom használni, mindig vannak vele problémák.' ]

PHONE = [ 'Internet/WAP',
          'Mobilkód',
          'Számológép',
          'Konferenciahívás',
          'Hangposta',
          'Ébresztőóra',
          'MMS',
          'Kihangosítás',
          'Bluetooth',
          'Játékok',
          'Chat',
          'GPS',
          'Szundi',
          'Fényképezés',
          'Videó rögzítés',
          'SMS',
          'MP3 lejátszás',
          'Jegyzet',
          'Határidőnapló',
          'Bejövő hívás elnémítása',
          'Több telefonszám mentése egy névhez',
          'Csengőhang rendelése névhez',
          'Gyorshívás',
          'SMS sablon',
          'Híváskorlátozás',
          'EMS (képüzenet)',
          'Java támogatás',
          'Hívásszűrés',
          'Valutaárfolyam',
          'Diktafon',
          'Emailezés',
          'Hívásvárakoztatás',
          'Ütésállóság',
          'Vízállóság',
          'Rádió',
          'Nagyméretű memóriakártya' ]

table_single_choice 'Rendelkezik az Ön készüléke a következő funkciókkal?', [ 'Igen', 'Nem', 'Nem tudom' ], 'Funkció', PHONE
table_single_choice 'Milyen gyakran használja az alábbi funkciókat?', [ 'Mindig', 'Gyakran', 'Általában', 'Ritkán', 'Soha' ], 'Funkció', PHONE
table_check_box 'A felsorolt funkciók közül melyiket használná szivesen?', 'Funkció', PHONE

single_choice 'Milyen gyakran cseréli mobiltelefon készülékét?', [ '1 - 2 havonta', '3 - 6 havonta', '7 - 12 havonta', '13 - 24 havonta', '25 - 36 havonta', 'Ritkábban' ]
multiple_choice_with_free 'Általában miért vásárol új készüléket?', [ 'Design', 'Új technológiai újdonság (streaming, chat, mobil TV, stb.)', 'Lejárt hűségszerződés', 'Kedvezményes ajánlat, akció', 'Egyéb, kérjük részletezze:' ]
single_choice 'Hány készüléke volt az elmúlt 5 évben?', [ '1 – 3', '4 – 6', '7 – 9', '10, vagy annál is több' ]
multiple_choice_with_free 'Milyen készüléket használ?', [ 'Alcatel', 'BlackBerry', 'iPhone', 'LG', 'Motorola', 'Nokia', 'Panasonic', 'Sagem', 'Samsung', 'Siemens', 'Sony Ericsson', 'egyéb:' ]
single_choice 'Milyen árkategóriájú készüléket használ?', [ '0 - 5.000 Ft', '5.001 - 20.000 Ft', '20.001 - 60.000 Ft', '60.001 - 120.000 Ft', '120.001 Ft, vagy annál is több', 'Nem tudom' ]
single_choice 'Hány működőképes készüléke van, beleértve a nem használt készülékeket is?', [ '1', '2', '3', '4', '5', 'Több' ]
single_choice 'Hány készüléket tart éjjel-nappal bekapcsolva?', [ '0', '1', '2', '3', '4', '5', 'Több' ]
single_choice 'Milyen gyakran van bekapcsolva az aktívan használt készüléke?', [ 'Éjjel-nappal', 'Nappal', 'Csak munkaidőben', 'Alkalmanként' ]

multiple_choice_with_free 'Hol hallott a mobilkód szolgáltatásról?', [ 'Internet', 'Magazinok', 'Szórólapok', 'Ismerőstől', 'Egyéb:' ]
single_choice 'Használt már vagy használja a mobilkódot?', [ 'Igen', 'Nem' ]
single_choice 'Támogatja a mobiltelefon készüléke kódolvasó alkalmazás futtatását?', [ 'Igen', 'Nem' ]
single_choice 'Sikerült letöltenie kódolvasó alkalmazást?', [ 'Igen', 'Nem' ]
single_choice 'Olvasott már le sikeresen mobilkódot mobiltelefon készülékével?', [ 'Igen', 'Nem' ]
multiple_choice_with_free 'Mire használta vagy használja a mobilkódot?', [ 'Nyereményjáték', 'Információszerzés', 'Névjegykártya bejegyzések gyors olvasása', 'Egyéb:' ]
multiple_choice_with_free 'Milyen kódolvasót használ?', [ 'I-nigma', 'QuickMark', 'Telefonba beépített kliens', 'Egyéb:' ]
#multiple_choice_with_free 'Milyen félelmei vannak az alkalmazással kapcsolatban?', [ 'Nem tudom milyen egyéb díjak vannak még az adatforgalmi díjon kívül', 'Titkos adatok kiadása.', 'Vírusok letöltése.', 'Egyéb:' ]
free_text 'Értékelje a mobilkódot! Van értelme? Ön szerint miért jó, miért rossz?'

single_choice 'Neme?', [ 'Férfi', 'Nő' ]
free_number 'Kora?'
free_number 'Mennyi a háztartásában az egy főre jutó nettó jövedelem?'
free_number 'Hányan élnek egy háztartásban?'
single_choice 'Lakhelye?', [ 'Budapest', 'Megyeszékhely vagy megyei jogú város', 'Kisebb település' ]
