
    REBOL [ Title: "RebOSClient" 
    
    author: Sam Neurohack
	note: "Quick and dirty OSC client implementation in Rebol"
	Version: 0.1]

;;
;; Code to send OSC packets. Support only float datas or no data
;;
;; Example : see Main program section
;;
;; oscip = IP of the OSC server waiting for orders.
;; oscport = port number of the waiting server.
;; oscaddress = osc command to be sent
;; oscvalue = [value1 value2 ...]
;;
;; float function : See end of code for License information
;;

to-ieee: func [
 "Zamienia decimal! lub integer! na binary! w formacie ieee-32."
 [catch]
  dat [number!] "liczba do konwersji (24 bity)"
 /local ieee-sign ieee-exponent ieee-mantissa integer-to-binary] [

  integer-to-binary: func [i [number!]] [debase/base to-hex i 16]
  ieee-sign: func [dat] [either positive? dat [0][1]]
  ieee-exponent: func [dat] [ ;; only for -0.5 > x > 0.5
    dat: to-integer dat
    weight: to-integer #{800000}
    i: 0
    forever [
      i: i + 1 
      if ((weight and dat) = weight) [break] 
      weight: to-integer (weight / 2)
    ]
    24 - i + 127
  ]
  ieee-mantissa: func [dat e] [
    m: to-integer (dat * (power 2 (23 - e + 127)))
    m: m and to-integer 2#{0111 1111 1111 1111 1111 1111}
  ]

  s: ieee-sign dat
  dat: abs dat
  e: ieee-exponent dat
  m: ieee-mantissa dat e
  integer-to-binary to-integer (m + (e * power 2 23) + (s * power 2 31))
]
;;
;;
;;

more0: does [
		number0: 4 - (remainder length0 4)
		switch number0 [
		 				1 [add0: #{00}]
		 				2 [add0: #{0000}]
		 				3 [add0: #{000000}]
		 				4 [add0: []]
						]
]

;;
;; Init OSC connection
;;

initosc: does [
			either error? try [testnet: do reduce ajoin ["open/binary/no-wait udp://" oscip ":" oscport]]
    										[print "Error: No OSC server"
    										break]
       										[osc: 1
       										close testnet
       										oscdevice: do reduce ajoin ["open/binary/no-wait udp://" oscip ":" oscport]
											print "OSC connection OK"
       										]						
				]
  
;;
;; End OSC connection
;;

endosc: does [
			either osc = 0 [print "OSC wasn't started"]
							[close oscdevice]
    		]


;;
;; sendosc 
;; 


sendosc: does [
			length0: 0								; convert osc address to binary
			binoscaddress: to-binary oscaddress
			length0: length? oscaddress
			more0
			binoscaddress: join binoscaddress add0
			
			oscfloat: ","							; generate values type string ie ",fff"
			nbvalue: length? oscvalue
			for values 1 nbvalue 1
						[oscfloat: ajoin [oscfloat "f"]
						]
			binfloat: to-binary oscfloat
			length0: length? binfloat
			more0
			binfloat: join binfloat add0
			print binfloat
			
			binvalue: []							; convert all oscvalue elements to binary
			for values 1 nbvalue 1
						[binvalue: join binvalue (to-ieee oscvalue/(values))]  
						
			binmsg: join binoscaddress binfloat		; generate the overall binary 			
			binmsg: join binmsg binvalue			; oscaddress + values type string + oscvalue

			print binmsg
			insert oscdevice binmsg					; send in binary 
			]

;;
;; Main Program
;;

osc: 0
oscip: 127.0.0.1
oscport: 7000
initosc
oscaddress: "/1/pan"
oscvalue: [10 9 8 7 6 5 4 3 2 1]
;value: 1
sendosc
endosc

;;
;; rebOSClient.r use ieee.r by Piotr Gapinski 2004-01-28 with "GNU Lesser General Public License (Version 2.1)"
;; 									  		  Copyright: "Olsztynska Strona Rowerowa http://www.rowery.olsztyn.pl"