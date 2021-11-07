#
#requires -version 4
<#
.SYNOPSIS
    Convertto-TextASCIIArt converts text string to ASCII Art.
.DESCRIPTION
    The Convertto-TextASCIIArt show normal string or text as big font nicely on console. I have created one font for use (It is not exactly font but background color and cannot be copied), alternatively if you are using online parameter it will fetch more fonts online from 'http://artii.herokuapp.com'.
.PARAMETER Text
    This is common parameter for inbuilt and online and incase not provided default value is '# This is test !', If you are using inbuilt font small letter will convert to capital letter.
.PARAMETER Online
    To use this parameter make sure you have active internet connection, as it will connect to website http://artii.herokuapp.com and and using api it will download the acsii Art
.PARAMETER FontName
    There are wide variaty of font list available on http://artii.herokuapp.com/fonts_list, when using online parameter, Value provided here is case sensetive.
.PARAMETER FontColor
    Below is the list of font color can be used to show ascii art.
    'Black', 'DarkBlue','DarkGreen','DarkCyan', 'DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White'
.PARAMETER FontHight
    This parameter is optional and default value is 5, this is font hight and required for the font I created. Algorithm of this script is depend on the default value.
.INPUTS
    [System.String]
.OUTPUTS
    [console]
.NOTES
    Version:        1.0
    Author:         Kunal Udapi
    Creation Date:  30 September 2017
    Purpose/Change: Personal use to show text to ascii art.
    Useful URLs: http://vcloud-lab.com, http://artii.herokuapp.com/fonts_list
.EXAMPLE
    PS C:\>.\Convertto-TextASCIIArt -Online -Text "http://vcloud-lab.com" -FontColor Gray -Fontname big
  _     _   _              ____         _                 _        _       _                         
 | |   | | | |       _    / / /        | |               | |      | |     | |                        
 | |__ | |_| |_ _ __(_)  / / /_   _____| | ___  _   _  __| |______| | __ _| |__   ___ ___  _ __ ___  
 | '_ \| __| __| '_ \   / / /\ \ / / __| |/ _ \| | | |/ _` |______| |/ _` | '_ \ / __/ _ \| '_ ` _ \ 
 | | | | |_| |_| |_) | / / /  \ V / (__| | (_) | |_| | (_| |      | | (_| | |_) | (__ (_) | | | | | |
 |_| |_|\__|\__| .__(_)_/_/    \_/ \___|_|\___/ \__,_|\__,_|      |_|\__,_|_.__(_)___\___/|_| |_| |_|
               | |                                                                                   
               |_|                                                                                   

    Shows and converts text to cool ascii art from online site http://artii.herokuapp.com using apis.
.EXAMPLE
    PS C:\>.\Convertto-TextASCIIArt -Text '# This !'

      ��  ��     ������ ��  �� ��   ����     ��
    ����������     ��   ��  �� �� ��         ��  
      ��  ��       ��   ������ ��   ��       ��  
    ����������     ��   ��  �� ��     ��    
      ��  ��       ��   ��  �� �� ����       ��  
    
    Shows local font on the script not internet required
#>

[CmdletBinding(SupportsShouldProcess=$True,
    ConfirmImpact='Medium',
    HelpURI='http://vcloud-lab.com',
    DefaultParameterSetName='Inbuilt')]
Param
(
    [parameter(Position=0, ParameterSetName='Inbuilt', ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Provide valid text')]
    [parameter(Position=0, ParameterSetName='Online', ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Provide valid text')]
    [string]$Text = '# This is test !',
    [parameter(Position=2, ParameterSetName='Inbuilt', ValueFromPipelineByPropertyName=$true, HelpMessage='Provide existing font hight')]
    [Alias('Hight')]    
    [string]$FontHight = '5',
    
    [parameter(Position=2, ParameterSetName='Online', ValueFromPipelineByPropertyName=$true, HelpMessage='Provide font name list is avaliable on http://artii.herokuapp.com/fonts_list')]
    [ValidateSet('3-d','3x5','5lineoblique','1943____','4x4_offr','64f1____','a_zooloo','advenger','aquaplan','asc_____','ascii___','assalt_m','asslt__m','atc_____','atc_gran','b_m__200','battle_s','battlesh','baz__bil','beer_pub','bubble__','bubble_b','c1______','c2______','c_ascii_','c_consen','caus_in_','char1___','char2___','char3___','char4___','charact1','charact2','charact3','charact4','charact5','charact6','characte','charset_','coil_cop','com_sen_','computer','convoy__','d_dragon','dcs_bfmo','deep_str','demo_1__','demo_2__','demo_m__','devilish','druid___','e__fist_','ebbs_1__','ebbs_2__','eca_____','etcrvs__','f15_____','faces_of','fair_mea','fairligh','fantasy_','fbr12___','fbr1____','fbr2____','fbr_stri','fbr_tilt','finalass','fireing_','flyn_sh','fp1_____','fp2_____','funky_dr','future_1','future_2','future_3','future_4','future_5','future_6','future_7','future_8','gauntlet','ghost_bo','gothic','gothic__','grand_pr','green_be','hades___','heavy_me','heroboti','high_noo','hills___','home_pak','house_of','hypa_bal','hyper___','inc_raw_','italics_','joust___','kgames_i','kik_star','krak_out','lazy_jon','letter_w','letterw3','lexible_','mad_nurs','magic_ma','master_o','mayhem_d','mcg_____','mig_ally','modern__','new_asci','nfi1____','notie_ca','npn_____','odel_lak','ok_beer_','outrun__','p_s_h_m_','p_skateb','pacos_pe','panther_','pawn_ins','phonix__','platoon2','platoon_','pod_____','r2-d2___','rad_____','rad_phan','radical_','rainbow_','rally_s2','rally_sp','rampage_','rastan__','raw_recu','rci_____','ripper!_','road_rai','rockbox_','rok_____','roman','roman___','script__','skate_ro','skateord','skateroc','sketch_s','sm______','space_op','spc_demo','star_war','stealth_','stencil1','stencil2','street_s','subteran','super_te','t__of_ap','tav1____','taxi____','tec1____','tec_7000','tecrvs__','ti_pan__','timesofl','tomahawk','top_duck','trashman','triad_st','ts1_____','tsm_____','tsn_base','twin_cob','type_set','ucf_fan_','ugalympi','unarmed_','usa_____','usa_pq__','vortron_','war_of_w','yie-ar__','yie_ar_k','z-pilot_','zig_zag_','zone7___','acrobatic','alligator','alligator2','alphabet','avatar','banner','banner3-D','banner3','banner4','barbwire','basic','5x7','5x8','6x10','6x9','brite','briteb','britebi','britei','chartr','chartri','clb6x10','clb8x10','clb8x8','cli8x8','clr4x6','clr5x10','clr5x6','clr5x8','clr6x10','clr6x6','clr6x8','clr7x10','clr7x8','clr8x10','clr8x8','cour','courb','courbi','couri','helv','helvb','helvbi','helvi','sans','sansb','sansbi','sansi','sbook','sbookb','sbookbi','sbooki','times','tty','ttyb','utopia','utopiab','utopiabi','utopiai','xbrite','xbriteb','xbritebi','xbritei','xchartr','xchartri','xcour','xcourb','xcourbi','xcouri','xhelv','xhelvb','xhelvbi','xhelvi','xsans','xsansb','xsansbi','xsansi','xsbook','xsbookb','xsbookbi','xsbooki','xtimes','xtty','xttyb','bell','big','bigchief','binary','block','broadway','bubble','bulbhead','calgphy2','caligraphy','catwalk','chunky','coinstak','colossal','contessa','contrast','cosmic','cosmike','crawford','cricket','cursive','cyberlarge','cybermedium','cybersmall','decimal','diamond','digital','doh','doom','dotmatrix','double','drpepper','dwhistled','eftichess','eftifont','eftipiti','eftirobot','eftitalic','eftiwall','eftiwater','epic','fender','fourtops','fraktur','goofy','graceful','gradient','graffiti','hex','hollywood','invita','isometric1','isometric2','isometric3','isometric4','italic','ivrit','jazmine','jerusalem','katakana','kban','l4me','larry3d','lcd','lean','letters','linux','lockergnome','madrid','marquee','maxfour','mike','mini','mirror','mnemonic','morse','moscow','mshebrew210','nancyj-fancy','nancyj-underlined','nancyj','nipples','ntgreek','nvscript','o8','octal','ogre','os2','pawp','peaks','pebbles','pepper','poison','puffy','pyramid','rectangles','relief','relief2','rev','rot13','rounded','rowancap','rozzo','runic','runyc','sblood','script','serifcap','shadow','short','slant','slide','slscript','small','smisome1','smkeyboard','smscript','smshadow','smslant','smtengwar','speed','stacey','stampatello','standard','starwars','stellar','stop','straight','tanja','tengwar','term','thick','thin','threepoint','ticks','ticksslant','tinker-toy','tombstone','trek','tsalagi','twopoint','univers','usaflag','weird','whimsy')]
    [Alias('Font')]
    [string]$FontName = 'big',

    [parameter(ParameterSetName = 'Online', Position=0, Mandatory=$false)]
    [Switch]$Online,

    [parameter(Position=1, ParameterSetName='Inbuilt', ValueFromPipelineByPropertyName=$true, ValueFromPipeline=$true, HelpMessage='Provide valid console color')]
    [parameter(ParameterSetName = 'Online', Position=1, Mandatory=$false, HelpMessage='Provide valid console color')]  
    [Alias('Color')]
    [ValidateSet('Black', 'DarkBlue','DarkGreen','DarkCyan', 'DarkRed','DarkMagenta','DarkYellow','Gray','DarkGray','Blue','Green','Cyan','Red','Magenta','Yellow','White')]
    [string]$FontColor = 'Yellow'
)
Begin {
    #$NonExistFont = $null
    if ($PsCmdlet.ParameterSetName -eq 'Inbuilt') {
        $a = {<#a 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#a#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor  -NoNewline; Write-Host " "
        <#a#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor  -NoNewline; Write-Host " "
        <#a#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#a#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor  -NoNewline; Write-Host " "} 
        $b = {<#b 07#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3) 
        <#b#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor   -NoNewline; Write-Host " "
        <#b#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#b#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor  -NoNewline; Write-Host " "
        <#b#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3) } 
        $c = {<#c 07#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#c#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) 
        <#c#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#c#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#c#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $d = {<#d 07#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3)
        <#d#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#d#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#d#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#d#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3)}  
        $e = {<#e 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#e#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#e#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host "  " 
        <#e#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#e#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $f = {<#f 07#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#f#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#f#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host "  "
        <#f#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#f#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)}
        $g = {<#g 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#g#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5)
        <#g#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host " " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#g#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#g#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $h = {<#h 07#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#h#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#h#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#h#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#h#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $i = {<#i 03#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#i#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "  
        <#i#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#i#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#i#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $j = {<#j 07#> Write-Host "  " -NoNewline; Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#j#> Write-Host $(" " * 4) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " "  
        <#j#> Write-Host $(" " * 4) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " " 
        <#h#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#j#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $k = {<#k 09#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#k#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#k#> Write-Host $(" " * 3) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5)
        <#k#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#k#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $l = {<#l 05#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host " "
        <#l#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#l#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#l#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#l#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $m = {<#m 09#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#m#> Write-Host $(" " * 3) -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host $(" " * 3) -NoNewline -BackgroundColor $FontColor; Write-Host " "
        <#m#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " " -NoNewline ; Write-Host "  " -NoNewline -BackgroundColor $FontColor ; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#m#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#m#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $n = {<#n 09#> Write-Host $(" " * 3) -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#n#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " " -NoNewline; Write-Host " " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#n#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host " " -NoNewline -BackgroundColor $FontColor ; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#n#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3) -NoNewline; Write-Host " " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#n#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $o = {<#o 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#o#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#o#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#o#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#o#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $p = {<#p 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#p#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#p#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#p#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5) 
        <#p#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5)}
        $q = {<#q 09#> Write-Host "  " -NoNewline; Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3)
        <#q#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#q#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#q#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#q#> Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $r = {<#r 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#r#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#r#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#r#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3)
        <#r#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $s = {<#s 07#> Write-Host "  " -NoNewline; Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#s#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5)
        <#s#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#s#> Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#s#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host " "}
        $t = {<#t 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#t#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#t#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#t#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3) 
        <#t#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)}
        $u = {<#u 07#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#u#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#u#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#u#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#u#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $v = {<#v 11#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 6) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#v#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 6) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#v#> Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  "
        <#v#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3)
        <#v#> Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5)}
        $w = {<#W 09#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host  $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#W#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host  $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#W#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline ; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#W#> Write-Host $(" " * 3) -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host $(" " * 3) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#W#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host  $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $x = {<#x 09#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#x#> Write-Host " " -NoNewline ; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " 
        <#x#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) 
        <#x#> Write-Host " " -NoNewline ; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " 
        <#x#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $y = {<#y 11#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#y#> Write-Host " " -NoNewline;  Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  "
        <#y#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) 
        <#y#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4) 
        <#y#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4)}
        $z = {<#z 07#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#z#> Write-Host $(" " * 4) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor ; Write-Host " " 
        <#z#> Write-Host "  " -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 3) 
        <#z#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 5)
        <#z#> Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $hyphen = {<#- 05#> Write-Host $(" " * 5)
        <#-#> Write-Host $(" " * 5)
        <#-#> Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#-#> Write-Host $(" " * 5)
        <#-#> Write-Host $(" " * 5)}
        $Hash = {<## 11#> Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host (" " * 3)
        <###> Write-Host $(" " * 10) -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <###> Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host (" " * 3)
        <###> Write-Host $(" " * 10) -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <###> Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host (" " * 3)}
        $AtRate = {<#@ 09#> Write-Host " " -NosNewline; Write-Host $(" " * 6) -BackgroundColor $FontColor -NoNewline; Write-Host "  "
        <#@#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host (" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#@#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host " " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#@#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  " -NoNewline; Write-Host " " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#@#> Write-Host " " -NoNewline; Write-Host $(" " * 4) -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $Exlaim = {<#! 03#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#!#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "  
        <#!#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#!#> Write-Host $(" " * 3)
        <#!#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $Dot = {<#. 03#> Write-Host $(" " * 3)
        <#.#> Write-Host $(" " * 3)  
        <#.#> Write-Host $(" " * 3) 
        <#.#> Write-Host $(" " * 3)
        <#.#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $Forward = {<#. 07#> Write-Host $(" " * 4) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#/#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host "  "
        <#/#> Write-Host "  " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 3)
        <#/#> Write-Host $(" " * 1) -NoNewline ; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#/#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 5)}
        $Colun = {<#: 03#> Write-Host $(" " * 3)
        <#:#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#:#> Write-Host $(" " * 3)  
        <#:#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#:#> Write-Host $(" " * 3)}
        $Space = {<#  02#> Write-Host $(" " * 2)
        <# #> Write-Host $(" " * 2)
        <# #> Write-Host $(" " * 2)
        <# #> Write-Host $(" " * 2)
        <# #> Write-Host $(" " * 2)}
        $1 = {<#1 04#> Write-Host $(" " * 3) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#1 #> Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#1 #> Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#1 #> Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#1 #> Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $2 = {<#2 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#2#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -NoNewline -BackgroundColor $FontColor ; Write-Host " " 
        <#z#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#z#> Write-Host "  " -NoNewline -BackgroundColor $FontColor; Write-Host $(" " * 4)
        <#z#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $3 = {<#3 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#3#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#3#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#3#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#3#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $4 = {<#4 06#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#4#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#4#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#4#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#4#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $5 = {<#5 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#s#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#s#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#s#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#s#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $6 = {<#6 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#6#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host $(" " * 4)
        <#6#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#6#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#6#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $7 = {<#7 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#7#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#7#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#7#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#7#> Write-Host $(" " * 3) -NoNewline;  Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $8 = {<#8 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#8#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#8#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#8#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#8#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $9 = {<#9 06#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#9#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#9#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "
        <#9#> Write-Host $(" " * 3) -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#9#> Write-Host $(" " * 5) -BackgroundColor $FontColor -NoNewline; Write-Host " "}
        $0 = {<#0 06#> Write-Host " " -NoNewline ;Write-Host $(" " * 3) -BackgroundColor $FontColor -NoNewline; Write-Host "  "
        <#0#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#0#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#0#> Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " -NoNewline; Write-Host "  " -BackgroundColor $FontColor -NoNewline; Write-Host " " 
        <#0#> Write-Host " " -NoNewline; Write-Host $(" " * 3) -BackgroundColor $FontColor -NoNewline; Write-Host "  "}
    }#if
}
Process {
    switch ($PsCmdlet.ParameterSetName) {
        'Inbuilt' {    
            [char[]]$AllCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890'
            foreach ($singleChar in $AllCharacters) {
                $CharScript = Get-Variable -Name $singleChar | Select-Object -ExpandProperty Value
                $CharScript = ($CharScript -split "`r`n")
                New-Variable -Name $singleChar -Value $CharScript -Force
            }
            $hyphen = $hyphen -split "`r`n"
            $Hash = $Hash -split "`r`n"
            $AtRate = $AtRate -split "`r`n"
            $Exlaim = $Exlaim -split "`r`n"
            $Dot = $Dot -split "`r`n"
            $Forward = $Forward -split "`r`n"
            $Colun = $Colun -split "`r`n"
            $Space = $Space -split "`r`n"

            $textlength = $text.Length 
            [char[]]$TextBreakDown = $text 
  
            $wordart = @() 
            $FindWidth  = @()
            $NonExistFont = @()

            for ($ind= 0; $ind -lt $FontHight; $ind++) { 
                $Conf = 1 
                foreach ($character in $TextBreakDown) { 
                    $NoFont = $True
                    Switch -regex ($character) {
                        '-' {
                            $charname =  Get-Variable -Name hyphen
                            break
                        } #-
                        '#' {
                            $charname =  Get-Variable -Name Hash
                            break
                        } ##
                        '@' {
                            $charname =  Get-Variable -Name AtRate
                            break
                        } #-
                        '!' {
                            $charname =  Get-Variable -Name Exlaim
                            break
                        } #!
                        '\.' {
                            $charname =  Get-Variable -Name Dot
                            break
                        } #.
                        ':' {
                            $charname =  Get-Variable -Name Colun
                            break
                        } #.
                        '/' {
                            $charname =  Get-Variable -Name Forward
                            break
                        } #.
                        '\s' {
                            $charname =  Get-Variable -Name space
                            break
                        } #.
                        "[A-Za-z_0-9]" {
                            $charname = Get-Variable -Name $character
                            break
                        } 
                        default {
                            $NoFont = $false
                            break
                        } #default
                    } #switch
                
                    if ($NoFont -eq $True) {
                        if ($Conf -eq $textlength) { 
                            $info = $charname.value[$ind] 
                            $wordart += $info
                        } #if conf
                        else {
                            $info = $charname.value[$ind] 
                            $wordart += "{0} {1}" -f $info, '-NoNewLine'
                        } #else conf
                        $wordart += "`r`n"
                
                        #Get First Line to calculate width
                        if ($ind -eq 0) {
                            $FindWidth += $charname.value[$ind]
                        } #if ind
                
                        #Calculate font width
                        if ($ind -eq 0) {
                            $AllFirstLines = @()
                            $FindWidth = $FindWidth.trim() | Where-Object {$_ -ne ""}
                            $CharWidth = $FindWidth | foreach {$_.Substring(4,2)}
                            $BigFontWidth = $CharWidth | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                        } #if ind

                    } #if NoFont
                    else {
                        $NonExistFont += $character
                    } #else NoFont
                    $Conf++
                } #foreach character
            } #for
            $TempFilePath = [System.IO.Path]::GetTempPath()
            $TempFileName = "{0}{1}" -f $TempFilePath, 'Show-BigFontOnConsole.ps1'
            $wordart | foreach {$_.trim()} | Out-File $TempFileName
            & $TempFileName
            if ($NonExistFont -ne $null) {
                $NonExistFont = $NonExistFont | Sort-Object | Get-Unique
                $NonResult = $NonExistFont -join " "
                Write-Host "`n`nSkipping as, No ascii fonts found for $NonResult" -BackgroundColor DarkRed
            } # if NonExistFont
        } #Inbuilt
        'Online' {
            if ($text -eq '# This is test !') {
                $text = 'http://vcloud-lab.com'
            }
            $testEncode = [uri]::EscapeDataString($Text)
            $url = "http://artii.herokuapp.com/make?text=$testEncode&font=$FontName"
            Try {
                $WebsiteApi = Invoke-WebRequest -Uri $url -ErrorAction Stop
                Write-Host $WebsiteApi.Content -ForegroundColor $FontColor
            }
            catch {
                $errMessage = "Check your internet connection, Verify below url in browser`n"
                $errMessage += $url
                Write-Host $errMessage -BackgroundColor DarkRed
            }
        } #Online
    } #switch pscmdlet
}
end {
}