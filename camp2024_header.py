import sys
header = open("camp2024_header.bin", "rb")
camp = open("build/camp", "rb")
out = open("CAMP2024.T64", "wb")
out.write(header.read()+camp.read())
header.close()
camp.close()
out.close()