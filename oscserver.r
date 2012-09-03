
    REBOL [ Title: "RebOSCserver" 
    
    author: Sam Neurohack
	note: "Quick and dirty OSC listener implementation in Rebol"
	Version: 0.1]

;;
;; Code listen and parse OSC packets on a specified port (with no or float data only yet).
;;
;; Example : see Main program section.
;;
;; oscport =  local port number to listen.
;; oscaddress = received osc command.
;; oscvalue =  received [value1 value2 ...]
;; nbargs = number of received OSC arguments
;;
;; float function : See end of code for License information
;;

from-ieee: func [
 "Zamienia binarna liczbe float ieee-32 na number!"
 [catch]
  dat [binary!] "liczba w formacie ieee-32"
 /local ieee-sign ieee-exponent ieee-mantissa] [

  ieee-sign: func [dat] [either zero? ((to-integer dat) and (to-integer 2#{10000000000000000000000000000000})) [1][-1]] ;; 1 bit
  ieee-exponent: func [dat] [
    exp: (to-integer dat) and (to-integer 2#{01111111100000000000000000000000}) ;; 8 bitow
    exp: (exp / power 2 23) - 127 ;; 127=[2^(k-1) - 1] (k=8 dla IEEE-32bit)
  ]
  ieee-mantissa: func [dat] [
    ((to-integer dat) and 
     (to-integer 2#{00000000011111111111111111111111})) + (to-integer (1 * power 2 23)) ;; 23 bity
  ]

  s: ieee-sign dat
  e: ieee-exponent dat
  m: ieee-mantissa dat
  d: s * (to-integer m) / power 2 (23 - e)
]

;;
;; Init OSC connection
;;

initosc: does 	[osc: 1
				newmsg: make binary! 5000
				my-address: read make url! join "dns://" (read dns://)
				print my-address
				oscserver: do reduce ajoin ["open/binary udp://:" oscport]
				oscaddress: []
				oscvalue: array [100]
				]
  
;;
;; End OSC connection
;;

endosc: does [
			either osc = 0 [print "OSC wasn't started"]
							[close oscserver]
    		]

;;
;; split newmsg
;;

splitosc: does [
			msglength: length? newmsg
			searchcoma: 0											; search end of command ascii letters
			while [(copy/part skip newmsg searchcoma 1) <> #{2C}] [searchcoma: searchcoma + 4
																	print copy/part skip newmsg searchcoma 1
																	]
			print searchcoma
			oscommand: to-string copy/part skip newmsg 0 (searchcoma - 1)
			print oscommand
			
			msgblocks: msglength / 4										; total of packets blocks
			argsblocks: msgblocks - to-integer (searchcoma / 4)				; nb of blocks from "," to end
			nbargs: argsblocks - 1 - to-integer (argsblocks / 5)			; nbargs 
			print ajoin ["msgblocks : " msgblocks " argblocks : " argsblocks " nbargs : " nbargs]
			for values 1 nbargs 1											; read args -> oscvalue array
						[
						value: copy/part skip newmsg (((msgblocks - nbargs - 1) + values) * 4) 4
						oscvalue/(values): from-ieee value
						]
			print oscvalue			
			]
			
			
;;
;; readosc 
;; 


readosc: does [
			forever [
					until [  error? try [
								receive: wait oscserver
								newmsg: copy oscserver
								newmsg: to-binary newmsg
								print newmsg
								splitosc
								]
							]
					]
			]

;;
;; Main Program
;;

osc: 0
oscport: 7000
initosc
readosc
endosc

;;
;; rebOSClient.r use ieee.r by Piotr Gapinski 2004-01-28 with "GNU Lesser General Public License (Version 2.1)"
;; 									  		  Copyright: "Olsztynska Strona Rowerowa http://www.rowery.olsztyn.pl"