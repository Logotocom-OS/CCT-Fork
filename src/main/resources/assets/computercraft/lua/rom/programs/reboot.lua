term.clear()
if term.isColour() then
    term.setTextColour(colours.yellow)
end
print("Starting Reboot... ")
sleep(0.3)
print( "Ternimating all running programs..." )
sleep( 0.05 )
write( "Done!" )
sleep( 0.06 )
print( "Finializing Reboot... " )
sleep( 0.12 )
write( "Done!" )
sleep( 1 )
print( "Shutting Down..." )

term.setTextColour(colours. green)

sleep(1)
term.clear()

sleep(2)
print( "Online, now starting reboot system..." )
sleep( 1 )
print( "Finishing..." )
sleep( 0.03 )
term.clear()

sleep(1)

os.reboot()
