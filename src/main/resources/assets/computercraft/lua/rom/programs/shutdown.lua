if term.isColour() then
    term.setTextColour(colours.yellow)
end
print("Shutting down...")
term.setTextColour(colours.green)

sleep(1)
write( "Done!" )
sleep(0.1)
os.shutdown()
