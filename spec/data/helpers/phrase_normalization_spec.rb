require 'spec_helper'

module Sierra
  module Data
    module Helpers
      RSpec.describe PhraseNormalization do
        describe '.standard_normalize' do
          pairs = [
            ['5916808|%1762189', ' 5916808  1762189'],
            ['nchg2df651fe-7079-47a2-b29d-77ea90702dc1',
             'nchg2df651fe     7079 47a2 b29d       77ea90702dc1'],
            ['|z60618545', '60618545'],
            [' ', nil],
            ['32988245|z(OCoLC)62441777|z(OCoLC)77633390|z(OCoLC)77633393'  \
             '|z(OCoLC)77664829|z(OCoLC)77664832|z(OCoLC)77734146|z(OCoLC)' \
             '77768001|z(OCoLC)77819922|z(OCoLC)77867473|z(OCoLC)77879873'  \
             '|z(OCoLC)77948921|z(OCoLC)77992118|z(OCoLC)78156448|z(OCoLC)' \
             '78202144|z(OCoLC)78227074|z(OCoLC)78229478|z(OCoLC)78263835',
             '32988245 ocolc 62441777 ocolc 77633390 ocolc 77633393 ocolc 776' \
             '64829 ocolc 77664832 ocolc 77734146 ocolc 77768001 ocolc 77819'],
            ['1,000,000 dollar dream', ' 1000000 dollar dream'],
            ['1,000 best movies on DVD', '    1000 best movies on dvd'],
            ['$5,000 note $5,000', '$5000 note $5000'],
            ['$500,000.00 real estate mortgage gold bonds : secured by the ' \
             'holdings of the Winter Garden Estates, Asheville, North ' \
             'Carolina ...',
             '$500000       00 real estate mortgage gold bonds secured by the' \
             ' holdings of the winter garden estates asheville north carolin'],
            ['100.000 candeles', '     100      000 candeles']
          ]

          pairs.each do |orig, norm|
            it "normalizes orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.standard_normalize(orig)).to eq(norm)
            end
          end
        end

        describe '.pad_numbers' do
          it 'pads things' do
            expect(PhraseNormalization.pad_numbers('2')).to eq('       2')
          end

          pairs = [
            ['B-1565-11', 'B-    1565-11'],
            ['B-1565--11', 'B-    1565--      11'],
            ['B-1565-1-1', 'B-    1565-       1-       1'],
            ['B-1565-111', 'B-    1565-     111'],
            ['B-1565-11-11', 'B-    1565-11-      11'],
            ['B-1565-a11a', 'B-    1565-a11a'],
            ['nchg2df651fe-7079-47a2-b29d-77ea90702dc1',
             'nchg2df651fe-    7079-47a2-b29d-      77ea90702dc1']
          ]
          pairs.each do |orig, norm|
            it "normalizes orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.pad_numbers(orig)).to eq(norm)
            end
          end
        end

        describe '.number_normalize' do
          isxns = [
            ['147800018X', '147800018x'],
            ['978 11 11 11', '978111111'],
            ['978 aa11 11 11', '978aa111111'],
            ['0252-8169', '02528169']
          ]
          isxns.each do |orig, norm|
            it "normalizes isxns. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.number_normalize(orig)).to eq(norm)
            end
          end

          barcodes = [
            ['00001254305', '00001254305'],
            ['0000 aaa 305', '0000aaa305'],
            ['PL00014362', 'pl00014362'],
            ['HAAA-9621-00003', 'haaa962100003'],
            ['H00139989$', 'h00139989']
          ]
          barcodes.each do |orig, norm|
            it "normalizes barcodes. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.number_normalize(orig)).to eq(norm)
            end
          end
        end

        describe '.sudoc_normalize' do
          pairs = [
            ['Y 4.2:B 43/5/D 67/V.1-3',
             'y    4.    2 :b   43/    5/d   67/v.    1-    3'],
            ['Y4.2: B43/5/D67/v.3',
             'y    4.    2 :b   43/    5/d   67/v.    3'],
            ['1.   14/    2 :f   31/    6/ 2017',
             '    1.   14/    2 :f   31/    6/ 2017'],
            ['NAS 1.26:189082',
             'nas    1.   26 :189082'],
            ['E 1.86/14:',
             'e    1.   86/   14 :'],
            ['Ju 13 .9 :85-2',
             'ju   13.    9 :   85-    2'],
            ['I 49.107:89 (2.21)',
             'i   49.  107 :   89(    2.   21)'],
            ['Y4.SM 1: 115-047',
             'y    4.sm    1 :  115-  047'],
            ['Y 4.L 11/4:S.HRG. 107-186',
             'y    4.l   11/    4 :s.hrg.  107-  186'],
            ['PRVP 42 .2 :G 74 /HUMAN',
             'prvp   42.    2 :g   74/human'],
            ['NAS 1.15:2017- 219071',
             'nas    1.   15 : 2017-219071'],
            ['FEM 1.209:300119, 300122, 300155',
             'fem    1.  209 :300119,300122,300155'],
            ['D 101.11:5-2330-361-14 & P/984',
             'd  101.   11 :    5- 2330-  361-   14&p/  984'],
            ['D 45/7/Maps 3 & 4/2017',
             'd   45/    7/maps    3&    4/ 2017'],
            ['A 13.28:Su 7/7/47091-C 3 - C 8/photo.',
             'a   13.   28 :su    7/    7/47091-c    3-c    8/photo.'],
            ['GP 3.35:DOSṮERR',
             'gp    3.   35 :dosterr'],
            ['FEM  1.209:260537',
             'fem    1.  209 :260537'],
            ['GP 3.35:FAC3̲1FR',
             'gp    3.   35 :fac   31fr'],
            ['J 28 .24/3 :Iℓ 5',
             'j   28.   24/    3 :il    5'],
            [' 1.14/2: F 31/6/2017',
             '    1.   14/    2 :f   31/    6/ 2017'],
            ['ḎḆṈṞṮḺḆ',
             'dbnrtlb']
          ]

          pairs.each do |orig, norm|
            it "normalizes sudocs. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.sudoc_normalize(orig)).to eq(norm)
            end
          end
        end

        describe '.dewey_normalize' do
          pairs = [
            ['373.757 M13e', '     373.757 m13e'],
            ['65-DVD18989', '      65 dvd18989'],
            ['CD-10,928', 'cd    10      928'],
            ['CD,16,707', 'cd    16      707'],
            ['1-2586 reel 13416, no. 06',
             '       1     2586 reel    13416 no.       06'],
            ['1-2586 reel 12619 , no. 01',
             '       1     2586 reel    12619 no.       01'],
            ["Sotheby's 1986.05.19", 'sothebys     1986.05.19'],
            ['NCME #587', 'ncme      587'],
            ['INLS242 Book#2', 'inls242 book        2'],
            ['942.007 $B G14e', '     942.007 b g14e'],
            ['1-2586 reel 970+971, no. 12,1',
             '       1     2586 reel      970      971 no.       12        1'],
            ['J Gutieârrez 1947a', 'j gutiearrez     1947a'],
            ['1-662 Ser. QQ & ZZ Guide',
             '       1      662 ser. qq and zz guide'],
            ["Sotheby's 2003.01.16-17,19",
             'sothebys     2003.01.16       17       19'],
            ['1-2586 reel 1409, no. 14; reel no. 1410,',
             '       1     2586 reel     1409 no.       14 reel no.     1410'],
            ['823 S43,1898 v.19', '     823 s43     1898 v.19'],
            ['Serial 1-30 reel 151-152,1120-1121',
             'serial        1       30 reel      151  152     1120     1121'],
            ['Serial 1-30 reel 1497,1874-1875',
             'serial        1       30 reel 1497     1874     1875'],
            ['CpX D257', 'cpx d257'],
            ['832 S33, 1948', '     832 s33     1948'],
            ['Y 1 .4/1:', 'y        1 .4        1'],
            ['1-2586 reel 1761,no. 05',
             '       1     2586 reel     1761 no.       05'],
            ['426 Series 1.4,1.5', '     426 series        1.4        1.5'],
            ['822 F915歔o', '     822 f915{22444c}o']
          ]

          pairs.each do |orig, norm|
            it "normalizes dewey/local nos. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.dewey_normalize(orig)).to eq(norm)
            end
          end

          failing_pairs = [
            ['J838 Kr 252 ss', 'j838 kr{7F00FC}ss'],
            ['FC-1̲5093', 'fc        15093']
          ]

          # fringe-y cases that don't currently succeed
          failing_pairs.each do |orig, norm|
            xit "normalizes dewey/local nos. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.dewey_normalize(orig)).to eq(norm)
            end
          end
        end

        describe '.lc_normalize' do
          pairs = [
            ['HC111.A1 E25', 'hc  111 a1 e25'],
            ['CJ2666 .H68 1979', 'cj 2666 h68 1979'],
            ['TX715.2.S68 F677 2011', 'tx  715.2 s68 f677 2011'],
            ['QA3 .A57 no. 754', 'qa    3 a57 no  754'],
            ['PQ2489  1927 v. 43', 'pq 2489 1927 v   43'],
            ['M287 .P54 op.8 P3', 'm   287 p54 op8 p3'],
            ['BR55 .M5 v.9, no.7', 'br   55 m5 v    9 no    7'],
            ['K46 .N5 no. 5240-5241', 'k    46 n5 no 5240 5241'],
            ['F2281.C32 V34 2008', 'f  2281 c32 v34 2008'],
            ['CU-0072', 'cu 0072'],
            ['KF49 .L44 no. P.L. 94-145', 'kf   49 l44 no pl 94 145'],
            ['W 4i Z96 1950 no. 23', 'w     4 i z96 1950 no   23'],
            ['R-12961', 'r 12961'],
            ["R706 .T64 1726 no. 6 Superv'd",
             'r   706 t64 1726 no    6 supervd'],
            ['WP/05/59', 'wp   05 59'],
            ['Pamphlet 147', 'pamphlet 147'],
            ['NCME #820', 'ncme 820'],
            ['PQ153 .M69 no 26', 'pq  153 m69 no 26'],
            ['Shelved as: Circulation ; v. 83, suppl. 4',
             'shelved as circulation v. 83 suppl. 4'],
            ['PQ6001 .R47 año 34 1968', 'pq 6001 r47 ano 34 1968'],
            ['HC445.5.Z7 K392+', 'hc  445.5 z7 k392'],
            ['WT 30 M489s Sect. 1.1', 'wt   30 m489 s sect 1 1'],
            ['PG5003 .N692 sv. 1', 'pg 5003 n692 sv    1'],
            ['QK827 #b.J62', 'qk  827 bj62'],
            ['GC512.N8 A43 no., 90-09', 'gc  512 n8 a43 no   90 09'],
            ['Shelved as: Advances in experimental medicine and biology ;' \
               ' v. 322',
             'shelved as advances in experimental medicine and biology v. 322']
          ]

          pairs.each do |orig, norm|
            it "normalizes lc call nos. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.lc_normalize(orig)).to eq(norm)
            end
          end

          failing_pairs = [
            ['2002-09', '2002 09'],
            ['PQ8497.A65 &b Z74', 'pq 8497 a65 and b z74'],
            ['PQ6254 .N69 Año. 2 no. 24', 'pq 6254 n69 ano    2 no   24'],
            ['QD461 .S92v. 108, etc.', 'qd  461 s92 v  108 etc'],
            ['PL2543 ǂb .Z467', 'pl 2543 {7 F01 C2 }b z467']
          ]

          # Somewhat fringe-y cases that don't currently succeed
          failing_pairs.each do |orig, norm|
            xit "normalizes lc call nos. orig: #{orig} to norm: #{norm}" do
              expect(PhraseNormalization.lc_normalize(orig)).to eq(norm)
            end
          end
        end
      end
    end
  end
end
